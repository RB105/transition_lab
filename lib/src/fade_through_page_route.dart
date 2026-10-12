// PageTransitionsBuilder lives here before Flutter 3.38.
import 'package:flutter/material.dart';

import 'gestures.dart';

/// Material 3's fade through transition, as between the destinations of a
/// navigation bar: the outgoing page fades out, and the new one fades in
/// while growing slightly, with no overlap between the two.
///
/// Use it for pages that are not related to each other; for pages that are
/// steps along an axis, use `SharedAxisPageTransitionsBuilder` instead.
///
/// Apply it to every route through the theme:
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     pageTransitionsTheme: const PageTransitionsTheme(
///       builders: {
///         TargetPlatform.android: FadeThroughPageTransitionsBuilder(),
///         TargetPlatform.iOS: FadeThroughPageTransitionsBuilder(),
///       },
///     ),
///   ),
/// )
/// ```
///
/// or to a single push with [FadeThroughPageRoute].
///
/// The iOS-style edge swipe back is kept (see [swipeBackEnabled]), and is
/// disabled while a [PopScope] blocks popping.
@immutable
class FadeThroughPageTransitionsBuilder extends PageTransitionsBuilder {
  /// Creates a fade through page transition. The defaults match Material 3.
  const FadeThroughPageTransitionsBuilder({
    this.duration = const Duration(milliseconds: 300),
    this.reverseDuration,
    this.curve = Curves.easeInOutCubicEmphasized,
    this.enterScale = 0.92,
    this.fillColor,
    this.swipeBackEnabled = true,
  }) : assert(enterScale > 0);

  /// How long a push takes.
  ///
  /// `MaterialPageRoute` reads it on Flutter 3.29 and newer;
  /// [FadeThroughPageRoute] always does.
  final Duration duration;

  /// How long a pop takes. Defaults to [duration].
  final Duration? reverseDuration;

  /// The easing of the scale. The cross-fade is linear, as in Material 3.
  final Curve curve;

  /// The scale the incoming page starts at.
  final double enterScale;

  /// Painted behind the pages while they cross-fade. Defaults to the theme's
  /// [ThemeData.scaffoldBackgroundColor].
  final Color? fillColor;

  /// Whether the route can be popped by dragging from its leading edge.
  final bool swipeBackEnabled;

  @override
  Duration get transitionDuration => duration;

  @override
  Duration get reverseTransitionDuration => reverseDuration ?? duration;

  @override
  DelegatedTransitionBuilder? get delegatedTransition => _coverPage;

  Widget? _coverPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) {
    return _FadeThroughTransition(
      spec: this,
      animation: secondaryAnimation,
      leaving: true,
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
    return _FadeThroughTransition(
      spec: this,
      animation: secondaryAnimation,
      leaving: true,
      child: _FadeThroughTransition(
        spec: this,
        animation: animation,
        leaving: false,
        child: swipeBackEnabled ? edgeSwipeBack(route, context, child) : child,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FadeThroughPageTransitionsBuilder &&
        other.duration == duration &&
        other.reverseDuration == reverseDuration &&
        other.curve == curve &&
        other.enterScale == enterScale &&
        other.fillColor == fillColor &&
        other.swipeBackEnabled == swipeBackEnabled;
  }

  @override
  int get hashCode => Object.hash(duration, reverseDuration, curve, enterScale,
      fillColor, swipeBackEnabled);
}

/// A [PageRoute] that always uses a [FadeThroughPageTransitionsBuilder],
/// whatever the app's [PageTransitionsTheme] is:
///
/// ```dart
/// Navigator.of(context).push(
///   FadeThroughPageRoute(builder: (_) => const LibraryPage()),
/// );
/// ```
class FadeThroughPageRoute<T> extends PageRoute<T> {
  /// Creates a route that fades its page through.
  FadeThroughPageRoute({
    required this.builder,
    this.transitions = const FadeThroughPageTransitionsBuilder(),
    this.maintainState = true,
    super.settings,
    super.fullscreenDialog,
  });

  /// Builds the primary contents of the route.
  final WidgetBuilder builder;

  /// The transition used to push and pop this route.
  final FadeThroughPageTransitionsBuilder transitions;

  @override
  final bool maintainState;

  @override
  Duration get transitionDuration => transitions.transitionDuration;

  @override
  Duration get reverseTransitionDuration =>
      transitions.reverseTransitionDuration;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      transitions.delegatedTransition;

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
    return transitions.buildTransitions<T>(
        this, context, animation, secondaryAnimation, child);
  }

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}

/// One of the two pages: the one [leaving] fades out over the first 30%, the
/// arriving one fades in over the rest while it grows to size.
class _FadeThroughTransition extends AnimatedWidget {
  const _FadeThroughTransition({
    required this.spec,
    required Animation<double> animation,
    required this.leaving,
    required this.child,
  }) : super(listenable: animation);

  final FadeThroughPageTransitionsBuilder spec;
  final bool leaving;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final double value = (listenable as Animation<double>).value;
    // How far this page is from where it rests: 1 fully away, 0 arrived.
    final double away = leaving ? value : 1 - value;
    final double opacity = leaving
        ? 1 - (away / 0.3).clamp(0.0, 1.0)
        : (1 - away / 0.7).clamp(0.0, 1.0);
    final Widget result = Opacity(opacity: opacity, child: child);
    if (!leaving) {
      // Exactly 1 at rest, so text and hit testing are untouched.
      final double scale = away == 0
          ? 1
          : 1 - (1 - spec.enterScale) * (1 - spec.curve.transform(1 - away));
      return Transform.scale(scale: scale, child: result);
    }
    // Only behind the page that is leaving: it fades out onto the fill, and
    // the arriving page fades in over both.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: away == 0
            ? null
            : spec.fillColor ?? Theme.of(context).scaffoldBackgroundColor,
      ),
      child: result,
    );
  }
}
