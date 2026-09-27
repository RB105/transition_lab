import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'gestures.dart';

const Curve _kCurve = Curves.easeInOut;

/// A card flip: the two pages are the front and the back of a card that
/// turns over around its vertical axis, moving back a little as it turns.
///
/// ```dart
/// Navigator.of(context).push(
///   FlipPageRoute(builder: (_) => const TicketBackPage()),
/// );
/// ```
///
/// The card turns with its trailing edge moving away from the viewer. The
/// page can be popped with the iOS edge swipe, which turns the card back and
/// is disabled while a [PopScope] blocks popping.
class FlipPageRoute<T> extends PageRoute<T> {
  /// Creates a route that turns the card over to show its page.
  FlipPageRoute({
    required this.builder,
    this.duration = const Duration(milliseconds: 600),
    this.reverseDuration,
    super.settings,
  });

  /// Builds the primary contents of the route.
  final WidgetBuilder builder;

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

  // The page underneath is the front of the card. Static, so a FlipPageRoute
  // underneath keeps its own, identical, turn.
  @override
  DelegatedTransitionBuilder? get delegatedTransition => _turnFront;

  static Widget? _turnFront(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) {
    return _CardFace(
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
    return _CardFace(
      animation: secondaryAnimation,
      linear: linear,
      child: _CardFace(
        animation: animation,
        back: true,
        linear: linear,
        child: edgeSwipeBack(this, context, child),
      ),
    );
  }

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}

/// One face of the card: the front turns away as its animation runs, the
/// [back] turns into view.
class _CardFace extends AnimatedWidget {
  const _CardFace({
    required Animation<double> animation,
    this.back = false,
    required this.linear,
    this.child,
  }) : super(listenable: animation);

  final bool back;
  final bool linear;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final double value = (listenable as Animation<double>).value;
    // How far the card has turned over: 0 face up, 1 upside down.
    final double turn = linear ? value : _kCurve.transform(value);
    // How far this face is turned away from the viewer, 0 to 1.
    final double away = back ? 1 - turn : turn;
    final double width = MediaQuery.sizeOf(context).width;
    // The card turns half a turn; the back starts out upside down.
    final double angle =
        trailingSign(context) * math.pi * (back ? turn - 1 : turn);
    // It moves back as it turns, and comes forward again.
    final double scale = 1 - 0.15 * math.sin(math.pi * turn);
    final bool atRest = away == 0;

    final Widget face = Opacity(
      // A face turned away from the viewer is hidden behind the other one.
      opacity: away < 0.5 ? 1 : 0,
      child: Transform(
        alignment: Alignment.center,
        // Exactly identity at rest, so text and hit testing are untouched.
        transform: atRest
            ? Matrix4.identity()
            : (Matrix4.identity()
              ..setEntry(3, 2, -1 / (width * 2.5))
              ..multiply(Matrix4.diagonal3Values(scale, scale, 1))
              ..multiply(Matrix4.rotationY(angle))),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          // A face darkens as it turns edge-on.
          decoration: BoxDecoration(
            color: atRest
                ? null
                : Colors.black.withValues(alpha: 0.6 * math.min(away * 2, 1)),
          ),
          child: child,
        ),
      ),
    );
    if (back) return face;
    // Black around the card while it turns.
    return DecoratedBox(
      decoration: BoxDecoration(color: atRest ? null : Colors.black),
      child: face,
    );
  }
}
