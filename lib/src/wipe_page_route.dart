import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'gestures.dart';

const Curve _kCurve = Curves.easeInOutCubic;

/// The shape a [WipePageRoute] uncovers its page with.
enum WipeStyle {
  /// Slats opening downwards together, like a blind.
  shutter,

  /// A straight edge sweeping across from the leading top corner.
  diagonal,

  /// A hand sweeping around the middle, like a clock's.
  clock,

  /// A circle opening in the middle, like a camera's aperture.
  iris,
}

/// A wipe: the new page is uncovered through a growing mask, in one of four
/// shapes, while the page underneath dims.
///
/// ```dart
/// Navigator.of(context).push(
///   WipePageRoute(
///     style: WipeStyle.shutter,
///     builder: (_) => const EpisodePage(),
///   ),
/// );
/// ```
///
/// The page can be popped with the iOS edge swipe, which is disabled while a
/// [PopScope] blocks popping.
///
/// [WipeStyle.diagonal] and [WipeStyle.clock] start from the leading edge, so
/// they mirror in a right-to-left directionality.
class WipePageRoute<T> extends PageRoute<T> {
  /// Creates a route that wipes its page in with [style].
  WipePageRoute({
    required this.builder,
    this.style = WipeStyle.diagonal,
    this.slats = 5,
    this.duration = const Duration(milliseconds: 450),
    this.reverseDuration,
    this.coveredOverlayColor = const Color(0x40000000),
    super.settings,
  }) : assert(slats > 0);

  /// Builds the primary contents of the route.
  final WidgetBuilder builder;

  /// The shape the page is uncovered with.
  final WipeStyle style;

  /// How many slats [WipeStyle.shutter] opens. Ignored by the other styles.
  final int slats;

  /// How long a push takes.
  final Duration duration;

  /// How long a pop takes. Defaults to [duration].
  final Duration? reverseDuration;

  /// The color painted over the page underneath once the wipe is complete. It
  /// fades in from transparent.
  final Color coveredOverlayColor;

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
    return _WipeTransition(
      animation: animation,
      route: this,
      rtl: Directionality.maybeOf(context) == TextDirection.rtl,
      linear: popGestureInProgress,
      child: edgeSwipeBack(this, context, child),
    );
  }

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}

class _WipeTransition extends AnimatedWidget {
  const _WipeTransition({
    required Animation<double> animation,
    required this.route,
    required this.rtl,
    required this.linear,
    required this.child,
  }) : super(listenable: animation);

  final WipePageRoute<dynamic> route;
  final bool rtl;
  final bool linear;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double value = (listenable as Animation<double>).value;
    final double t = linear ? value : _kCurve.transform(value);
    final Color overlay = route.coveredOverlayColor;

    return Stack(
      fit: StackFit.passthrough,
      children: [
        // Dims the page underneath as the wipe covers it.
        Positioned.fill(
          child: IgnorePointer(
            child: ColoredBox(
              color: t == 1
                  ? const Color(0x00000000)
                  : Color.lerp(overlay.withAlpha(0), overlay, t)!,
            ),
          ),
        ),
        ClipPath(
          clipper: _WipeClipper(
            style: route.style,
            slats: route.slats,
            fraction: t,
            rtl: rtl,
          ),
          clipBehavior: t == 1 ? Clip.none : Clip.antiAlias,
          child: child,
        ),
      ],
    );
  }
}

class _WipeClipper extends CustomClipper<Path> {
  _WipeClipper({
    required this.style,
    required this.slats,
    required this.fraction,
    required this.rtl,
  });

  final WipeStyle style;
  final int slats;
  final double fraction;
  final bool rtl;

  @override
  Path getClip(Size size) {
    if (fraction >= 1) return Path()..addRect(Offset.zero & size);
    final Path path = Path();
    if (fraction <= 0) return path;
    switch (style) {
      case WipeStyle.shutter:
        final double slat = size.height / slats;
        for (int i = 0; i < slats; i++) {
          path.addRect(
            Rect.fromLTWH(0, i * slat, size.width, slat * fraction),
          );
        }
      case WipeStyle.diagonal:
        // The half-plane x + y <= k, swept from the leading top corner.
        final double k = (size.width + size.height) * fraction;
        double x(double value) => rtl ? size.width - value : value;
        path.moveTo(x(0), 0);
        if (k <= size.width) {
          path.lineTo(x(k), 0);
        } else {
          path.lineTo(x(size.width), 0);
          path.lineTo(x(size.width), math.min(k - size.width, size.height));
        }
        if (k <= size.height) {
          path.lineTo(x(0), k);
        } else {
          path.lineTo(x(math.min(k - size.height, size.width)), size.height);
          path.lineTo(x(0), size.height);
        }
        path.close();
      case WipeStyle.clock:
        final Offset center = size.center(Offset.zero);
        path.moveTo(center.dx, center.dy);
        path.arcTo(
          Rect.fromCircle(center: center, radius: _cornerRadius(size)),
          -math.pi / 2,
          (rtl ? -1 : 1) * 2 * math.pi * fraction,
          false,
        );
        path.close();
      case WipeStyle.iris:
        path.addOval(
          Rect.fromCircle(
            center: size.center(Offset.zero),
            radius: _cornerRadius(size) * fraction,
          ),
        );
    }
    return path;
  }

  // Reaches the corners from the middle.
  static double _cornerRadius(Size size) =>
      math.sqrt(size.width * size.width + size.height * size.height) / 2;

  @override
  bool shouldReclip(_WipeClipper oldClipper) =>
      oldClipper.fraction != fraction ||
      oldClipper.style != style ||
      oldClipper.slats != slats ||
      oldClipper.rtl != rtl;
}
