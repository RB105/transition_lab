import 'package:flutter/material.dart';

import 'gestures.dart';

const Curve _kCurve = Curves.easeOutCubic;

/// A card dealt onto a stack, as in Tinder or the iOS Safari tab switcher:
/// the page flies in from the trailing edge with a tilt and settles flat,
/// while the page underneath sits back as the next card in the stack.
///
/// ```dart
/// Navigator.of(context).push(
///   CardStackRoute(builder: (_) => ProfileCard(profile: profile)),
/// );
/// ```
///
/// Dragging the card towards the trailing edge from anywhere throws it away
/// again, which pops the route. The drag is disabled while a [PopScope]
/// blocks popping.
class CardStackRoute<T> extends PageRoute<T> {
  /// Creates a route that deals its page onto the stack.
  CardStackRoute({
    required this.builder,
    this.duration = const Duration(milliseconds: 420),
    this.reverseDuration,
    this.tilt = 0.2,
    this.radius = 18,
    this.coveredScale = 0.94,
    this.coveredOverlayColor = const Color(0x33000000),
    super.settings,
  });

  /// Builds the primary contents of the route.
  final WidgetBuilder builder;

  /// How long a push takes.
  final Duration duration;

  /// How long a pop takes. Defaults to [duration].
  final Duration? reverseDuration;

  /// How far the card is tilted while it is off to the side, in radians.
  final double tilt;

  /// The corner radius of the card while it moves. At rest the page fills the
  /// screen with square corners.
  final double radius;

  /// The scale of the page underneath once covered.
  final double coveredScale;

  /// The color painted over the page underneath once covered. It fades in
  /// from transparent.
  final Color coveredOverlayColor;

  @override
  Duration get transitionDuration => duration;

  @override
  Duration get reverseTransitionDuration => reverseDuration ?? duration;

  // The card underneath peeks out around the one on top while it moves.
  @override
  bool get opaque => false;

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  DelegatedTransitionBuilder? get delegatedTransition => _sitBack;

  Widget? _sitBack(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) {
    return _NextCard(
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
    final bool linear = popGestureInProgress;
    return _NextCard(
      route: this,
      animation: secondaryAnimation,
      linear: linear,
      child: _TopCard(
        route: this,
        animation: animation,
        linear: linear,
        child: BackDragGesture(
          route: this,
          controller: controller!,
          // The card leaves across a bit more than the screen width.
          travel: 1.15,
          popDistance: 0.3,
          child: child,
        ),
      ),
    );
  }

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}

double _progress(Animation<double> animation, bool linear) =>
    linear ? animation.value : _kCurve.transform(animation.value);

/// The card on top, flying in from the trailing edge with a tilt.
class _TopCard extends AnimatedWidget {
  const _TopCard({
    required this.route,
    required Animation<double> animation,
    required this.linear,
    required this.child,
  }) : super(listenable: animation);

  final CardStackRoute<dynamic> route;
  final bool linear;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double t = _progress(listenable as Animation<double>, linear);
    // 1 while off to the side, 0 once the card has landed.
    final double away = 1 - t;
    final double direction = trailingSign(context);
    final Size size = MediaQuery.sizeOf(context);
    // The structure stays the same at rest, and every transform is exactly
    // identity there, so text, hit testing and the drag below are untouched.
    return Transform.translate(
      offset: Offset(direction * size.width * 1.15 * away, 20 * away),
      child: Transform.rotate(
        angle: direction * route.tilt * away,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(route.radius * away),
          clipBehavior: away == 0 ? Clip.none : Clip.antiAlias,
          child: child,
        ),
      ),
    );
  }
}

/// The card underneath, sitting back while it is covered.
class _NextCard extends AnimatedWidget {
  const _NextCard({
    required this.route,
    required Animation<double> animation,
    required this.linear,
    required this.child,
  }) : super(listenable: animation);

  final CardStackRoute<dynamic> route;
  final bool linear;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final double q = _progress(listenable as Animation<double>, linear);
    final double scale = 1 - (1 - route.coveredScale) * q;
    final Color overlay = route.coveredOverlayColor;
    // Black around the card while it is shrunk.
    return DecoratedBox(
      decoration: BoxDecoration(color: q == 0 ? null : Colors.black),
      child: Transform.scale(
        scale: scale,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(route.radius * q),
          clipBehavior: q == 0 ? Clip.none : Clip.antiAlias,
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              color:
                  q == 0 ? null : Color.lerp(overlay.withAlpha(0), overlay, q),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
