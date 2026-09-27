import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'gestures.dart';

const Curve _kCurve = Curves.easeOutCubic;

/// A depth transition, as when an app opens on iOS or a window comes forward
/// on visionOS: the page underneath recedes, blurs and dims, while the new
/// page settles in from slightly in front of the screen and fades in.
///
/// ```dart
/// Navigator.of(context).push(
///   DepthPageRoute(builder: (_) => const SettingsPage()),
/// );
/// ```
///
/// The page can be popped with the iOS edge swipe, which is disabled while a
/// [PopScope] blocks popping.
///
/// Blurring a whole page every frame is costly on low-end devices; lower
/// [blurSigma], or set it to 0 to leave the blur out.
class DepthPageRoute<T> extends PageRoute<T> {
  /// Creates a route that brings its page forward over a blurred one.
  DepthPageRoute({
    required this.builder,
    this.duration = const Duration(milliseconds: 450),
    this.reverseDuration,
    this.blurSigma = 12,
    super.settings,
  }) : assert(blurSigma >= 0);

  /// Builds the primary contents of the route.
  final WidgetBuilder builder;

  /// How long a push takes.
  final Duration duration;

  /// How long a pop takes. Defaults to [duration].
  final Duration? reverseDuration;

  /// How strongly the page underneath is blurred once covered.
  final double blurSigma;

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
  DelegatedTransitionBuilder? get delegatedTransition => _recede;

  Widget? _recede(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) {
    return _Recede(
      animation: secondaryAnimation,
      blurSigma: blurSigma,
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
    return _Recede(
      animation: secondaryAnimation,
      blurSigma: blurSigma,
      linear: linear,
      child: _ComeForward(
        animation: animation,
        linear: linear,
        child: edgeSwipeBack(this, context, child),
      ),
    );
  }

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}

double _progress(Animation<double> animation, bool linear) =>
    linear ? animation.value : _kCurve.transform(animation.value);

/// The new page, settling from slightly in front of the screen.
class _ComeForward extends AnimatedWidget {
  const _ComeForward({
    required Animation<double> animation,
    required this.linear,
    required this.child,
  }) : super(listenable: animation);

  final bool linear;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double t = _progress(listenable as Animation<double>, linear);
    return Opacity(
      opacity: (t / 0.6).clamp(0.0, 1.0),
      child: Transform.scale(scale: 1.08 - 0.08 * t, child: child),
    );
  }
}

/// The page underneath, receding into a blur.
class _Recede extends AnimatedWidget {
  const _Recede({
    required Animation<double> animation,
    required this.blurSigma,
    required this.linear,
    required this.child,
  }) : super(listenable: animation);

  final double blurSigma;
  final bool linear;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final double q = _progress(listenable as Animation<double>, linear);
    final double sigma = blurSigma * q;
    return DecoratedBox(
      decoration: BoxDecoration(color: q == 0 ? null : Colors.black),
      child: Transform.scale(
        scale: 1 - 0.06 * q,
        child: ImageFiltered(
          enabled: sigma > 0,
          imageFilter: ImageFilter.blur(
            sigmaX: sigma,
            sigmaY: sigma,
            tileMode: TileMode.decal,
          ),
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              color: q == 0 ? null : Colors.black.withValues(alpha: 0.25 * q),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
