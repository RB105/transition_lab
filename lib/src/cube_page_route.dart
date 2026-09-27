import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'gestures.dart';

/// The Instagram Stories transition: the two pages are faces of a cube that
/// turns.
///
/// ```dart
/// Navigator.of(context).pushReplacement(
///   CubePageRoute(builder: (_) => StoryPage(index: index + 1)),
/// );
/// ```
///
/// The new page comes in from the trailing edge (the right in left-to-right
/// layouts). With [backward] it comes in from the leading edge instead, as
/// when going back to the previous story.
///
/// A page that came in from the trailing edge can be popped with the iOS edge
/// swipe, which is disabled while a [PopScope] blocks popping.
class CubePageRoute<T> extends PageRoute<T> {
  /// Creates a route that turns the cube to show its page.
  CubePageRoute({
    required this.builder,
    this.backward = false,
    this.duration = const Duration(milliseconds: 650),
    this.reverseDuration,
    super.settings,
  });

  /// Builds the primary contents of the route.
  final WidgetBuilder builder;

  /// Whether the cube turns the other way, bringing the page in from the
  /// leading edge.
  final bool backward;

  /// How long a push takes.
  final Duration duration;

  /// How long a pop takes. Defaults to [duration].
  final Duration? reverseDuration;

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

  // The page underneath turns away as the neighbouring face of the cube.
  // These are static so two routes turning the same way share them, and a
  // CubePageRoute underneath then keeps its own, identical, turn.
  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      backward ? _turnAwayBackward : _turnAwayForward;

  static Widget? _turnAwayForward(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) =>
      _CubeFace(
        animation: secondaryAnimation,
        side: -trailingSign(context),
        linear: Navigator.maybeOf(context)?.userGestureInProgress ?? false,
        child: child,
      );

  static Widget? _turnAwayBackward(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) =>
      _CubeFace(
        animation: secondaryAnimation,
        side: trailingSign(context),
        linear: Navigator.maybeOf(context)?.userGestureInProgress ?? false,
        child: child,
      );

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
    // Where this page comes in from: 1 on the right, -1 on the left.
    final double side = trailingSign(context) * (backward ? -1 : 1);
    return _CubeFace(
      animation: secondaryAnimation,
      side: -side,
      linear: linear,
      child: _CubeFace(
        animation: animation,
        side: side,
        entering: true,
        linear: linear,
        // The edge swipe only matches a page that came from the trailing
        // edge.
        child: backward ? child : edgeSwipeBack(this, context, child),
      ),
    );
  }

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}

/// One face of the cube. [side] is where the face is when it is not facing
/// the viewer: -1 on the left, 1 on the right.
class _CubeFace extends AnimatedWidget {
  const _CubeFace({
    required Animation<double> animation,
    required this.side,
    this.entering = false,
    required this.linear,
    this.child,
  }) : super(listenable: animation);

  final double side;
  final bool entering;
  final bool linear;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final double value = (listenable as Animation<double>).value;
    final double t = linear ? value : Curves.easeInOut.transform(value);
    // 0 while facing the viewer, ±1 when turned away to the side.
    final double position = side * (entering ? 1 - t : t);
    final double width = MediaQuery.sizeOf(context).width;
    // The faces turn around their shared edge.
    final double pivot = (position > 0 ? -0.5 : 0.5) * width;

    return DecoratedBox(
      // Black around the faces while the cube turns.
      decoration: BoxDecoration(
        color: !entering && position != 0 ? Colors.black : null,
      ),
      child: Transform(
        alignment: Alignment.center,
        // Exactly identity at rest, so text and hit testing are untouched.
        transform: position == 0
            ? Matrix4.identity()
            : (Matrix4.identity()
              ..setEntry(3, 2, -1 / 900)
              ..multiply(
                Matrix4.translationValues(position * width + pivot, 0, 0),
              )
              ..multiply(Matrix4.rotationY(position * math.pi / 2))
              ..multiply(Matrix4.translationValues(-pivot, 0, 0))),
        // A face turned away from the viewer gets darker.
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            color: position == 0
                ? null
                : Colors.black.withValues(alpha: 0.55 * position.abs()),
          ),
          child: child,
        ),
      ),
    );
  }
}
