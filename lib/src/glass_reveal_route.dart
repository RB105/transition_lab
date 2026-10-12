import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'circular_reveal_route.dart' show TapPosition;
import 'gestures.dart';

const Curve _kCurve = Curves.easeOutCubic;

/// The glass ripple of iOS 26: the page is uncovered by a circle growing from
/// where the user tapped, with a band of blurred, lit glass riding its edge.
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => TapPosition.tracker(child: child!),
///   // ...
/// );
///
/// Navigator.of(context).push(
///   GlassRevealRoute(builder: (_) => const SearchPage()),
/// );
/// ```
///
/// The page can be popped with the iOS edge swipe, which is disabled while a
/// [PopScope] blocks popping.
///
/// The band blurs everything behind it every frame, which is costly on
/// low-end devices; lower [blurSigma], or set it to 0 to leave the blur out
/// and keep only the rim.
///
/// The route assumes its navigator fills the screen, as the app's root
/// navigator does.
class GlassRevealRoute<T> extends PageRoute<T> {
  /// Creates a route whose page is uncovered by a ripple from [center].
  GlassRevealRoute({
    required this.builder,
    Offset? center,
    this.duration = const Duration(milliseconds: 650),
    this.reverseDuration = const Duration(milliseconds: 500),
    this.bandWidth = 26,
    this.blurSigma = 10,
    this.rimColor = const Color(0xCCFFFFFF),
    super.settings,
  })  : center = center ?? TapPosition.last,
        assert(bandWidth > 0),
        assert(blurSigma >= 0);

  /// Builds the primary contents of the route.
  final WidgetBuilder builder;

  /// Where the ripple grows from, in global coordinates. Defaults to
  /// [TapPosition.last]; without one, the middle of the screen.
  final Offset? center;

  /// How long the ripple takes to cover the screen.
  final Duration duration;

  /// How long it takes to close back into its point.
  final Duration reverseDuration;

  /// How wide the band of glass riding the ripple's edge is.
  final double bandWidth;

  /// How strongly the band blurs what is behind it.
  final double blurSigma;

  /// The color of the lit rim on the ripple's edge.
  final Color rimColor;

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
    return _GlassTransition(
      animation: animation,
      route: this,
      linear: popGestureInProgress,
      child: edgeSwipeBack(this, context, child),
    );
  }

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}

class _GlassTransition extends AnimatedWidget {
  const _GlassTransition({
    required Animation<double> animation,
    required this.route,
    required this.linear,
    required this.child,
  }) : super(listenable: animation);

  final GlassRevealRoute<dynamic> route;
  final bool linear;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double value = (listenable as Animation<double>).value;
    final double t = linear ? value : _kCurve.transform(value);
    final Size size = MediaQuery.sizeOf(context);
    final Offset center = route.center ?? size.center(Offset.zero);
    final double radius = _maxRadius(center, size) * t;
    // The glass rides the edge, and is gone by the time it leaves the screen.
    final double lit = t == 0 ? 0 : 1 - ((t - 0.75) / 0.25).clamp(0.0, 1.0);

    return Stack(
      fit: StackFit.passthrough,
      children: [
        // Dims the page underneath while the ripple grows.
        Positioned.fill(
          child: IgnorePointer(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: t == 1 ? 0 : 0.25 * t),
            ),
          ),
        ),
        ClipPath(
          clipper: _CircleClipper(center: center, radius: radius),
          clipBehavior: t == 1 ? Clip.none : Clip.antiAlias,
          child: child,
        ),
        if (lit > 0) ...[
          // A band of glass straddling the edge: it blurs and lightens what
          // is behind it.
          Positioned.fill(
            child: IgnorePointer(
              child: ClipPath(
                clipper: _BandClipper(
                  center: center,
                  radius: radius,
                  band: route.bandWidth,
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: route.blurSigma * lit,
                    sigmaY: route.blurSigma * lit,
                    tileMode: TileMode.decal,
                  ),
                  child: ColoredBox(
                    color: Colors.white.withValues(alpha: 0.14 * lit),
                  ),
                ),
              ),
            ),
          ),
          // The lit rim on the edge itself.
          Positioned.fromRect(
            rect: Rect.fromCircle(center: center, radius: radius),
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: route.rimColor.withValues(
                      alpha: route.rimColor.a * lit,
                    ),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Big enough to reach the farthest corner.
  static double _maxRadius(Offset center, Size size) => [
        Offset.zero,
        Offset(size.width, 0),
        Offset(0, size.height),
        Offset(size.width, size.height),
      ].map((corner) => (corner - center).distance).reduce(math.max);
}

class _CircleClipper extends CustomClipper<Path> {
  const _CircleClipper({required this.center, required this.radius});

  final Offset center;
  final double radius;

  @override
  Path getClip(Size size) =>
      Path()..addOval(Rect.fromCircle(center: center, radius: radius));

  @override
  bool shouldReclip(_CircleClipper oldClipper) =>
      oldClipper.center != center || oldClipper.radius != radius;
}

class _BandClipper extends CustomClipper<Path> {
  const _BandClipper({
    required this.center,
    required this.radius,
    required this.band,
  });

  final Offset center;
  final double radius;
  final double band;

  @override
  Path getClip(Size size) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(Rect.fromCircle(center: center, radius: radius + band / 2))
      ..addOval(
        Rect.fromCircle(
          center: center,
          radius: math.max(radius - band / 2, 0),
        ),
      );
  }

  @override
  bool shouldReclip(_BandClipper oldClipper) =>
      oldClipper.center != center ||
      oldClipper.radius != radius ||
      oldClipper.band != band;
}
