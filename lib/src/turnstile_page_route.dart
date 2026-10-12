import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'gestures.dart';

const Curve _kCurve = Curves.easeInOutCubic;

/// The turnstile of Windows Phone's Metro: the page underneath pivots away
/// around its leading edge like a revolving door, and the new one pivots into
/// its place.
///
/// ```dart
/// Navigator.of(context).push(
///   TurnstileRoute(builder: (_) => const PivotPage()),
/// );
/// ```
///
/// The page can be popped with the iOS edge swipe, which is disabled while a
/// [PopScope] blocks popping.
class TurnstileRoute<T> extends PageRoute<T> {
  /// Creates a route that pivots its page in.
  TurnstileRoute({
    required this.builder,
    this.duration = const Duration(milliseconds: 450),
    this.reverseDuration,
    this.angle = math.pi * 70 / 180,
    this.perspective = 1000,
    super.settings,
  }) : assert(perspective > 0);

  /// Builds the primary contents of the route.
  final WidgetBuilder builder;

  /// How long a push takes.
  final Duration duration;

  /// How long a pop takes. Defaults to [duration].
  final Duration? reverseDuration;

  /// How far the pages pivot around their leading edge, in radians. The
  /// trailing edge turns away from the viewer.
  final double angle;

  /// The viewer's distance from the screen in logical pixels, as in CSS
  /// `perspective()`. Smaller values give a stronger 3D effect.
  final double perspective;

  @override
  Duration get transitionDuration => duration;

  @override
  Duration get reverseTransitionDuration => reverseDuration ?? duration;

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  DelegatedTransitionBuilder? get delegatedTransition => _pivotAway;

  Widget? _pivotAway(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) {
    return _Pivot(
      spec: this,
      animation: secondaryAnimation,
      leaving: true,
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
    return _Pivot(
      spec: this,
      animation: secondaryAnimation,
      leaving: true,
      linear: linear,
      child: _Pivot(
        spec: this,
        animation: animation,
        leaving: false,
        linear: linear,
        child: edgeSwipeBack(this, context, child),
      ),
    );
  }

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}

/// A page pivoting around its leading edge: the one [leaving] turns away, the
/// arriving one turns into view.
class _Pivot extends AnimatedWidget {
  const _Pivot({
    required this.spec,
    required Animation<double> animation,
    required this.leaving,
    required this.linear,
    required this.child,
  }) : super(listenable: animation);

  final TurnstileRoute<dynamic> spec;
  final bool leaving;
  final bool linear;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final double value = (listenable as Animation<double>).value;
    final double t = linear ? value : _kCurve.transform(value);
    // How far this page is turned away from the viewer: 1 edge-on, 0 flat.
    final double away = leaving ? t : 1 - t;
    final double direction = trailingSign(context);
    final Widget page = Opacity(
      // Opaque again once it is halfway back to flat.
      opacity: ((1 - away) / 0.5).clamp(0.0, 1.0),
      child: Transform(
        alignment: AlignmentDirectional.centerStart,
        // Exactly identity at rest, so text and hit testing are untouched.
        transform: away == 0
            ? Matrix4.identity()
            : (Matrix4.identity()
              ..setEntry(3, 2, -1 / spec.perspective)
              ..multiply(Matrix4.rotationY(direction * spec.angle * away))),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          // A page darkens as it turns edge-on.
          decoration: BoxDecoration(
            color:
                away == 0 ? null : Colors.black.withValues(alpha: 0.5 * away),
          ),
          child: child,
        ),
      ),
    );
    // Black around the pages while they turn.
    if (!leaving) return page;
    return DecoratedBox(
      decoration: BoxDecoration(color: away == 0 ? null : Colors.black),
      child: page,
    );
  }
}
