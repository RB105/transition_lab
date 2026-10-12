// PageTransitionsBuilder lives here before Flutter 3.38.
import 'package:flutter/material.dart';

import 'gestures.dart';

/// The axis a [SharedAxisPageTransitionsBuilder] moves its pages along.
enum SharedAxis {
  /// Sideways, for pages next to each other, like steps of a form.
  horizontal,

  /// Up and down, for pages stacked above each other.
  vertical,

  /// Into the screen, for a page that comes out of the one before it.
  scaled,
}

/// Material 3's shared axis transition: the two pages move together along one
/// axis while they cross-fade, so they read as neighbours on that axis.
///
/// The outgoing page fades out over the first 30% of the transition and the
/// incoming one fades in over the rest, so they never show through each
/// other. [fillColor] is painted in the gap between them.
///
/// Apply it to every route through the theme:
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     pageTransitionsTheme: const PageTransitionsTheme(
///       builders: {
///         TargetPlatform.android: SharedAxisPageTransitionsBuilder(),
///         TargetPlatform.iOS: SharedAxisPageTransitionsBuilder(),
///       },
///     ),
///   ),
/// )
/// ```
///
/// or to a single push with [SharedAxisPageRoute].
///
/// The iOS-style edge swipe back is kept (see [swipeBackEnabled]), and is
/// disabled while a [PopScope] blocks popping.
@immutable
class SharedAxisPageTransitionsBuilder extends PageTransitionsBuilder {
  /// Creates a shared axis page transition. The defaults match Material 3.
  const SharedAxisPageTransitionsBuilder({
    this.axis = SharedAxis.horizontal,
    this.duration = const Duration(milliseconds: 300),
    this.reverseDuration,
    this.curve = Curves.easeInOutCubicEmphasized,
    this.distance = 30,
    this.fillColor,
    this.swipeBackEnabled = true,
  });

  /// The axis the pages travel along.
  final SharedAxis axis;

  /// How long a push takes.
  ///
  /// `MaterialPageRoute` reads it on Flutter 3.29 and newer;
  /// [SharedAxisPageRoute] always does.
  final Duration duration;

  /// How long a pop takes. Defaults to [duration].
  final Duration? reverseDuration;

  /// The easing of the movement. The cross-fade is linear, as in Material 3.
  final Curve curve;

  /// How far the pages travel, in logical pixels. Ignored by
  /// [SharedAxis.scaled], which scales instead.
  final double distance;

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
    return _SharedAxisTransition(
      spec: this,
      animation: secondaryAnimation,
      leaving: true,
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
    return _SharedAxisTransition(
      spec: this,
      animation: secondaryAnimation,
      leaving: true,
      linear: linear,
      child: _SharedAxisTransition(
        spec: this,
        animation: animation,
        leaving: false,
        linear: linear,
        child: swipeBackEnabled ? edgeSwipeBack(route, context, child) : child,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SharedAxisPageTransitionsBuilder &&
        other.axis == axis &&
        other.duration == duration &&
        other.reverseDuration == reverseDuration &&
        other.curve == curve &&
        other.distance == distance &&
        other.fillColor == fillColor &&
        other.swipeBackEnabled == swipeBackEnabled;
  }

  @override
  int get hashCode => Object.hash(
        axis,
        duration,
        reverseDuration,
        curve,
        distance,
        fillColor,
        swipeBackEnabled,
      );
}

/// A [PageRoute] that always uses a [SharedAxisPageTransitionsBuilder],
/// whatever the app's [PageTransitionsTheme] is:
///
/// ```dart
/// Navigator.of(context).push(
///   SharedAxisPageRoute(
///     axis: SharedAxis.horizontal,
///     builder: (_) => const StepTwoPage(),
///   ),
/// );
/// ```
class SharedAxisPageRoute<T> extends PageRoute<T> {
  /// Creates a route that moves its page in along [axis].
  SharedAxisPageRoute({
    required this.builder,
    SharedAxis axis = SharedAxis.horizontal,
    SharedAxisPageTransitionsBuilder? transitions,
    this.maintainState = true,
    super.settings,
    super.fullscreenDialog,
  }) : transitions = transitions ??
            (axis == SharedAxis.horizontal
                ? const SharedAxisPageTransitionsBuilder()
                : SharedAxisPageTransitionsBuilder(axis: axis));

  /// Builds the primary contents of the route.
  final WidgetBuilder builder;

  /// The transition used to push and pop this route.
  final SharedAxisPageTransitionsBuilder transitions;

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
      this,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}

/// One of the two pages: the one [leaving] travels on and fades out early,
/// the arriving one travels in and fades in late.
class _SharedAxisTransition extends AnimatedWidget {
  const _SharedAxisTransition({
    required this.spec,
    required Animation<double> animation,
    required this.leaving,
    required this.linear,
    required this.child,
  }) : super(listenable: animation);

  final SharedAxisPageTransitionsBuilder spec;
  final bool leaving;
  final bool linear;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final double value = (listenable as Animation<double>).value;
    // How far this page is from where it rests: 1 fully away, 0 arrived.
    final double away = leaving ? value : 1 - value;
    final double moved =
        linear ? away : 1 - spec.curve.transform(leaving ? 1 - value : value);
    // The leaving page travels on in the direction the new one came from.
    final double sign = leaving ? -1 : 1;
    final double shift = sign * spec.distance * moved * trailingSign(context);
    final double opacity = leaving
        ? 1 - (away / 0.3).clamp(0.0, 1.0)
        : (1 - away / 0.7).clamp(0.0, 1.0);

    Widget result = Opacity(opacity: opacity, child: child);
    result = switch (spec.axis) {
      SharedAxis.horizontal => Transform.translate(
          offset: Offset(shift, 0),
          child: result,
        ),
      SharedAxis.vertical => Transform.translate(
          offset: Offset(0, sign * spec.distance * moved),
          child: result,
        ),
      SharedAxis.scaled => Transform.scale(
          scale: leaving ? 1 + 0.1 * moved : 1 - 0.2 * moved,
          child: result,
        ),
    };
    // Only behind the page that is leaving: it fades out onto the fill,
    // and the arriving page fades in over both.
    if (!leaving) return result;
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
