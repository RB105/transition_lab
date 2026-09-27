import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'gestures.dart';

/// Remembers where the last finger went down, so a [CircularRevealRoute] can
/// open from it.
abstract final class TapPosition {
  /// Where the last pointer went down, in global coordinates, or null before
  /// the first one.
  static Offset? last;

  /// Keeps [last] up to date for every pointer inside [child]. Wrap the whole
  /// app with it, e.g. in `MaterialApp.builder`.
  static Widget tracker({required Widget child}) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) => last = event.position,
      child: child,
    );
  }
}

/// Material's circular reveal, as in Android and Telegram: the page opens as
/// a circle growing from where the user tapped, and closes back into that
/// point.
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => TapPosition.tracker(child: child!),
///   // ...
/// );
///
/// Navigator.of(context).push(
///   CircularRevealRoute(builder: (_) => const SearchPage()),
/// );
/// ```
///
/// The page can be popped with the iOS edge swipe, which is disabled while a
/// [PopScope] blocks popping.
///
/// The route assumes its navigator fills the screen, as the app's root
/// navigator does.
class CircularRevealRoute<T> extends PageRoute<T> {
  /// Creates a route whose page grows out of [center].
  CircularRevealRoute({
    required this.builder,
    Offset? center,
    this.duration = const Duration(milliseconds: 600),
    this.reverseDuration = const Duration(milliseconds: 450),
    super.settings,
  }) : center = center ?? TapPosition.last;

  /// Builds the primary contents of the route.
  final WidgetBuilder builder;

  /// Where the circle grows from, in global coordinates. Defaults to
  /// [TapPosition.last]; without one, the middle of the screen.
  final Offset? center;

  /// How long the circle takes to grow.
  final Duration duration;

  /// How long the circle takes to shrink back.
  final Duration reverseDuration;

  @override
  Duration get transitionDuration => duration;

  @override
  Duration get reverseTransitionDuration => reverseDuration;

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

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
    return _RevealTransition(
      animation: animation,
      center: center,
      linear: popGestureInProgress,
      child: edgeSwipeBack(this, context, child),
    );
  }

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}

class _RevealTransition extends AnimatedWidget {
  const _RevealTransition({
    required Animation<double> animation,
    required this.center,
    required this.linear,
    required this.child,
  }) : super(listenable: animation);

  final Offset? center;
  final bool linear;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double value = (listenable as Animation<double>).value;
    final double t = linear ? value : Curves.fastOutSlowIn.transform(value);
    return Stack(
      fit: StackFit.passthrough,
      children: [
        // Dims the page underneath while the circle grows.
        Positioned.fill(
          child: IgnorePointer(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: t == 1 ? 0 : 0.25 * t),
            ),
          ),
        ),
        ClipPath(
          clipper: _CircleClipper(center: center, fraction: t),
          clipBehavior: t == 1 ? Clip.none : Clip.antiAlias,
          child: child,
        ),
      ],
    );
  }
}

class _CircleClipper extends CustomClipper<Path> {
  _CircleClipper({required this.center, required this.fraction});

  final Offset? center;
  final double fraction;

  @override
  Path getClip(Size size) {
    final Offset c = center ?? size.center(Offset.zero);
    // Big enough to reach the farthest corner.
    final double maxRadius = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ].map((corner) => (corner - c).distance).reduce(math.max);
    return Path()
      ..addOval(Rect.fromCircle(center: c, radius: maxRadius * fraction));
  }

  @override
  bool shouldReclip(_CircleClipper oldClipper) =>
      oldClipper.center != center || oldClipper.fraction != fraction;
}
