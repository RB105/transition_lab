import 'package:flutter/material.dart';

import 'gestures.dart';

const Curve _kCurve = Curves.easeOutCubic;

/// A side menu, as in Messenger and Telegram: the page slides in from the
/// leading edge over part of the screen, while the page underneath slides a
/// little the other way, shrinks and is dimmed by the scrim.
///
/// ```dart
/// Navigator.of(context).push(
///   DrawerPageRoute(
///     barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
///     builder: (_) => const MenuPage(),
///   ),
/// );
/// ```
///
/// Dragging the panel towards the leading edge closes it, as does a tap on
/// the scrim beside it. Both are disabled while a [PopScope] blocks popping.
class DrawerPageRoute<T> extends PageRoute<T> {
  /// Creates a route that slides its page in as a side menu.
  DrawerPageRoute({
    required this.builder,
    this.widthFactor = 0.78,
    this.duration = const Duration(milliseconds: 380),
    this.reverseDuration,
    this.scrimColor = const Color(0x66000000),
    this.coveredOffset = 0.1,
    this.coveredScale = 0.94,
    this.barrierLabel = 'Dismiss',
    super.settings,
  })  : assert(widthFactor > 0 && widthFactor <= 1),
        assert(coveredScale > 0);

  /// Builds the primary contents of the route.
  final WidgetBuilder builder;

  /// How much of the screen width the panel covers.
  final double widthFactor;

  /// How long the panel takes to slide in.
  final Duration duration;

  /// How long the panel takes to slide away. Defaults to [duration].
  final Duration? reverseDuration;

  /// Painted over the page underneath while the panel is open. A tap on it
  /// closes the panel.
  final Color scrimColor;

  /// How far the page underneath slides towards the trailing edge, as a
  /// fraction of the screen width.
  final double coveredOffset;

  /// The scale of the page underneath once the panel is open.
  final double coveredScale;

  /// The semantic label of the scrim. Pass
  /// `MaterialLocalizations.of(context).modalBarrierDismissLabel` to have it
  /// read out in the user's language.
  @override
  final String? barrierLabel;

  @override
  Duration get transitionDuration => duration;

  @override
  Duration get reverseTransitionDuration => reverseDuration ?? duration;

  // The page underneath and the scrim stay visible beside the panel.
  @override
  bool get opaque => false;

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => scrimColor;

  @override
  bool get barrierDismissible => true;

  @override
  DelegatedTransitionBuilder? get delegatedTransition => _slideAway;

  Widget? _slideAway(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) {
    return _Covered(
      route: this,
      animation: secondaryAnimation,
      linear: Navigator.maybeOf(context)?.userGestureInProgress ?? false,
      child: child,
    );
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: builder(context),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // The panel itself is not wrapped in anything that fills the screen, so
    // taps beside it reach the scrim.
    return _Panel(
      route: this,
      animation: animation,
      linear: popGestureInProgress,
      child: BackDragGesture(
        route: this,
        controller: controller!,
        travel: widthFactor,
        popDistance: widthFactor / 2,
        reverse: true,
        child: child,
      ),
    );
  }

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}

double _progress(Animation<double> animation, bool linear) =>
    linear ? animation.value : _kCurve.transform(animation.value);

/// The panel, sliding in from the leading edge over part of the screen.
class _Panel extends AnimatedWidget {
  const _Panel({
    required this.route,
    required Animation<double> animation,
    required this.linear,
    required this.child,
  }) : super(listenable: animation);

  final DrawerPageRoute<dynamic> route;
  final bool linear;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double t = _progress(listenable as Animation<double>, linear);
    final double width = MediaQuery.sizeOf(context).width * route.widthFactor;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Transform.translate(
        offset: Offset(-trailingSign(context) * width * (1 - t), 0),
        child: SizedBox(width: width, child: child),
      ),
    );
  }
}

/// The page underneath, sliding a little towards the trailing edge.
class _Covered extends AnimatedWidget {
  const _Covered({
    required this.route,
    required Animation<double> animation,
    required this.linear,
    required this.child,
  }) : super(listenable: animation);

  final DrawerPageRoute<dynamic> route;
  final bool linear;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final double q = _progress(listenable as Animation<double>, linear);
    final double scale = 1 - (1 - route.coveredScale) * q;
    // Black around the page while it is shrunk.
    return DecoratedBox(
      decoration: BoxDecoration(color: q == 0 ? null : Colors.black),
      child: Transform(
        alignment: Alignment.center,
        // Exactly identity at rest, so text and hit testing are untouched.
        transform: q == 0
            ? Matrix4.identity()
            : (Matrix4.translationValues(
                trailingSign(context) *
                    route.coveredOffset *
                    MediaQuery.sizeOf(context).width *
                    q,
                0,
                0,
              )..multiply(Matrix4.diagonal3Values(scale, scale, 1))),
        child: child,
      ),
    );
  }
}
