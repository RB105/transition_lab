import 'dart:math' as math;

import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
// PageTransitionsBuilder lives here before Flutter 3.38.
import 'package:flutter/material.dart';

import 'gestures.dart';

/// A [PageTransitionsBuilder] in which the incoming page swings in from the
/// side in 3D — rotating around the vertical axis and zooming down to size,
/// like a book page being turned — while the page underneath slides back,
/// shrinks and dims.
///
/// The defaults reproduce the page transition of the Wolt app, as re-created
/// for React Navigation by Shadi F.
///
/// Apply it to every route through the theme:
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     pageTransitionsTheme: const PageTransitionsTheme(
///       builders: {
///         TargetPlatform.android: SwingPageTransitionsBuilder(),
///         TargetPlatform.iOS: SwingPageTransitionsBuilder(),
///       },
///     ),
///   ),
/// )
/// ```
///
/// or to a single push with `SwingPageRoute`.
///
/// The iOS-style edge swipe back is kept (see [swipeBackEnabled]). Like in
/// [CupertinoPageRoute], it is disabled while a [PopScope] blocks popping.
@immutable
class SwingPageTransitionsBuilder extends PageTransitionsBuilder {
  /// Creates a swing page transition. The defaults match the Wolt app.
  const SwingPageTransitionsBuilder({
    this.duration = const Duration(milliseconds: 550),
    this.reverseDuration,
    this.curve = Curves.easeOut,
    this.enterOffset = 1.6,
    this.enterAngle = math.pi / 3,
    this.enterScale = 1.6,
    this.enterOpacity = 0.8,
    this.perspective = 1000,
    this.coveredOffset = -0.3,
    this.coveredScale = 0.9,
    this.coveredOverlayColor = const Color(0x80000000),
    this.backdropColor = const Color(0xFF000000),
    this.swipeBackEnabled = true,
  })  : assert(perspective > 0),
        assert(enterOpacity >= 0 && enterOpacity <= 1);

  /// How long a push takes.
  ///
  /// `MaterialPageRoute` reads it on Flutter 3.29 and newer; `SwingPageRoute`
  /// always does.
  final Duration duration;

  /// How long a pop takes. Defaults to [duration].
  final Duration? reverseDuration;

  /// The easing of the transition.
  ///
  /// A pop plays the same curve backwards, so the default [Curves.easeOut]
  /// makes a push start fast and settle gently, and a pop start gently and
  /// finish fast. During a back swipe the pages follow the finger linearly.
  final Curve curve;

  /// Where the incoming page starts, as a fraction of the screen width
  /// measured towards the trailing edge.
  final double enterOffset;

  /// The incoming page's initial rotation around the vertical axis, in
  /// radians. Positive values turn its trailing edge away from the viewer.
  final double enterAngle;

  /// The incoming page's initial scale.
  final double enterScale;

  /// The incoming page's initial opacity.
  final double enterOpacity;

  /// The viewer's distance from the screen in logical pixels, as in CSS
  /// `perspective()`. Smaller values give a stronger 3D effect.
  final double perspective;

  /// How far the page underneath slides once fully covered, as a fraction of
  /// the screen width. Negative values move it towards the leading edge.
  final double coveredOffset;

  /// The scale of the page underneath once fully covered.
  final double coveredScale;

  /// The color painted over the page underneath once fully covered. It fades
  /// in from transparent. Use a transparent color to disable dimming.
  final Color coveredOverlayColor;

  /// The color shown around the page underneath while it is shrunk, or null
  /// to show whatever is behind the navigator.
  final Color? backdropColor;

  /// Whether the route can be popped by dragging from its leading edge.
  final bool swipeBackEnabled;

  @override
  Duration get transitionDuration => duration;

  @override
  Duration get reverseTransitionDuration => reverseDuration ?? duration;

  // Lets routes below that are not MaterialPageRoutes (e.g. a PageRouteBuilder
  // root) recede too.
  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      _buildDelegatedTransition;

  Widget? _buildDelegatedTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) {
    return _CoveredTransition(
      spec: this,
      animation: secondaryAnimation,
      linear: Navigator.maybeOf(context)?.userGestureInProgress ?? false,
      child: child,
    );
  }

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final bool linear = route.popGestureInProgress;
    return _CoveredTransition(
      spec: this,
      animation: secondaryAnimation,
      linear: linear,
      child: _EnterTransition(
        spec: this,
        animation: animation,
        linear: linear,
        child: swipeBackEnabled ? edgeSwipeBack(route, context, child) : child,
      ),
    );
  }

  double _progress(Animation<double> animation, bool linear) =>
      linear ? animation.value : curve.transform(animation.value);

  @override
  bool operator ==(Object other) {
    return other is SwingPageTransitionsBuilder &&
        other.duration == duration &&
        other.reverseDuration == reverseDuration &&
        other.curve == curve &&
        other.enterOffset == enterOffset &&
        other.enterAngle == enterAngle &&
        other.enterScale == enterScale &&
        other.enterOpacity == enterOpacity &&
        other.perspective == perspective &&
        other.coveredOffset == coveredOffset &&
        other.coveredScale == coveredScale &&
        other.coveredOverlayColor == coveredOverlayColor &&
        other.backdropColor == backdropColor &&
        other.swipeBackEnabled == swipeBackEnabled;
  }

  @override
  int get hashCode => Object.hash(
        duration,
        reverseDuration,
        curve,
        enterOffset,
        enterAngle,
        enterScale,
        enterOpacity,
        perspective,
        coveredOffset,
        coveredScale,
        coveredOverlayColor,
        backdropColor,
        swipeBackEnabled,
      );
}

/// The page being pushed or popped (React Navigation's `current.progress`).
class _EnterTransition extends AnimatedWidget {
  const _EnterTransition({
    required this.spec,
    required Animation<double> animation,
    required this.linear,
    required this.child,
  }) : super(listenable: animation);

  final SwingPageTransitionsBuilder spec;
  final bool linear;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // 1 while off screen, 0 once the page has landed.
    final double t =
        1 - spec._progress(listenable as Animation<double>, linear);
    final double direction = trailingSign(context);
    final double scale = 1 + (spec.enterScale - 1) * t;

    return Opacity(
      opacity: 1 - (1 - spec.enterOpacity) * t,
      child: Transform(
        alignment: Alignment.center,
        // Exactly identity at rest, so text and hit testing are untouched.
        transform: t == 0
            ? Matrix4.identity()
            : (Matrix4.identity()
              ..setEntry(3, 2, -1 / spec.perspective)
              ..multiply(
                Matrix4.translationValues(
                  direction *
                      spec.enterOffset *
                      MediaQuery.sizeOf(context).width *
                      t,
                  0,
                  0,
                ),
              )
              ..multiply(Matrix4.rotationY(direction * spec.enterAngle * t))
              ..multiply(Matrix4.diagonal3Values(scale, scale, 1))),
        child: child,
      ),
    );
  }
}

/// The page a new route is pushed on top of (React Navigation's
/// `next.progress`).
class _CoveredTransition extends AnimatedWidget {
  const _CoveredTransition({
    required this.spec,
    required Animation<double> animation,
    required this.linear,
    required this.child,
  }) : super(listenable: animation);

  final SwingPageTransitionsBuilder spec;
  final bool linear;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    // 0 while uncovered, 1 once fully covered.
    final double q = spec._progress(listenable as Animation<double>, linear);
    final double scale = 1 + (spec.coveredScale - 1) * q;
    final Color overlay = spec.coveredOverlayColor;

    return DecoratedBox(
      decoration: BoxDecoration(color: q == 0 ? null : spec.backdropColor),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.translationValues(
          trailingSign(context) *
              spec.coveredOffset *
              MediaQuery.sizeOf(context).width *
              q,
          0,
          0,
        )..multiply(Matrix4.diagonal3Values(scale, scale, 1)),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            color: q == 0 ? null : Color.lerp(overlay.withAlpha(0), overlay, q),
          ),
          child: child,
        ),
      ),
    );
  }
}
