import 'package:flutter/material.dart';

import 'gestures.dart';

// The sheet's bottom sits this far above the bottom safe area.
const double _kBottomGap = 10;
const double _kRadius = 12;
// How far a covered page shrinks.
const double _kCoveredScale = 0.92;
const Color _kCoveredOverlay = Color(0x33000000);
const Curve _kCurve = Curves.easeOutCubic;

/// A sheet coming down from the top, as iOS Control Center and the Android
/// notification shade do: the page slides down as a card with rounded bottom
/// corners, while the page underneath shrinks back, dims and peeks out below
/// it.
///
/// ```dart
/// Navigator.of(context).push(
///   TopSheetRoute(builder: (_) => const ControlsPage()),
/// );
/// ```
///
/// Pushing the sheet up from anywhere while its content is scrolled to the
/// bottom drags it with the finger, and letting go far or fast enough closes
/// it. The push is disabled while a [PopScope] blocks popping.
///
/// Sheets stack: a sheet pushed over another one shrinks it back in turn.
class TopSheetRoute<T> extends PageRoute<T> {
  /// Creates a route that slides its page down as a sheet.
  TopSheetRoute({
    required this.builder,
    this.duration = const Duration(milliseconds: 500),
    this.reverseDuration = const Duration(milliseconds: 400),
    super.settings,
  });

  /// Builds the primary contents of the route.
  final WidgetBuilder builder;

  /// How long the sheet takes to slide down.
  final Duration duration;

  /// How long the sheet takes to slide away.
  final Duration reverseDuration;

  @override
  Duration get transitionDuration => duration;

  @override
  Duration get reverseTransitionDuration => reverseDuration;

  // The page underneath peeks out below the sheet.
  @override
  bool get opaque => false;

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  // Static, so a sheet underneath another one keeps its own covered look.
  @override
  DelegatedTransitionBuilder? get delegatedTransition => _coverPage;

  static Widget? _coverPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) {
    return _Covered(
      animation: secondaryAnimation,
      linear: Navigator.maybeOf(context)?.userGestureInProgress ?? false,
      sheet: false,
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
    return _Covered(
      animation: secondaryAnimation,
      linear: linear,
      sheet: true,
      child: _Sheet(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        linear: linear,
        child: _SheetPush(route: this, controller: controller!, child: child),
      ),
    );
  }

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}

double _progress(Animation<double> animation, bool linear) =>
    linear ? animation.value : _kCurve.transform(animation.value);

double _sheetBottom(BuildContext context) =>
    MediaQuery.paddingOf(context).bottom + _kBottomGap;

/// The sheet sliding down, rounded at the bottom and dimmed while covered.
class _Sheet extends AnimatedWidget {
  _Sheet({
    required this.animation,
    required this.secondaryAnimation,
    required this.linear,
    required this.child,
  }) : super(listenable: Listenable.merge([animation, secondaryAnimation]));

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final bool linear;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double t = _progress(animation, linear);
    final double q = _progress(secondaryAnimation, linear);
    final double bottom = _sheetBottom(context);
    final double travel = MediaQuery.sizeOf(context).height - bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Transform.translate(
        offset: Offset(0, -(1 - t) * travel),
        child: ClipRRect(
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(_kRadius)),
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              color: q == 0
                  ? null
                  : Color.lerp(
                      _kCoveredOverlay.withAlpha(0), _kCoveredOverlay, q),
            ),
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// A page with a sheet over it: it shrinks towards its bottom so that it
/// peeks out just below the sheet. A plain page also gets rounded corners, a
/// black surround and a dimming; a sheet only shrinks, as it dims itself.
class _Covered extends AnimatedWidget {
  const _Covered({
    required Animation<double> animation,
    required this.linear,
    required this.sheet,
    required this.child,
  }) : super(listenable: animation);

  final bool linear;
  final bool sheet;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final double q = _progress(listenable as Animation<double>, linear);
    final double padBottom = MediaQuery.paddingOf(context).bottom;
    final double scale = 1 - (1 - _kCoveredScale) * q;
    // Where the content's bottom starts, and where it ends up: just below
    // the sheet covering it.
    final double from = sheet ? _sheetBottom(context) : 0;
    final double bottom = from + (padBottom - from) * q;

    Widget result = Transform(
      alignment: Alignment.bottomCenter,
      // Exactly identity at rest, so text and hit testing are untouched.
      transform: q == 0
          ? Matrix4.identity()
          : (Matrix4.translationValues(0, -(bottom - from * scale), 0)
            ..multiply(Matrix4.diagonal3Values(scale, scale, 1))),
      child: sheet
          ? child
          : ClipRRect(
              borderRadius: BorderRadius.circular(_kRadius * q),
              clipBehavior: q == 0 ? Clip.none : Clip.antiAlias,
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  color: q == 0
                      ? null
                      : Color.lerp(
                          _kCoveredOverlay.withAlpha(0), _kCoveredOverlay, q),
                ),
                child: child,
              ),
            ),
    );
    if (!sheet) {
      result = DecoratedBox(
        decoration: BoxDecoration(color: q == 0 ? null : Colors.black),
        child: result,
      );
    }
    return result;
  }
}

/// Lets the sheet be pushed up from anywhere on its content.
class _SheetPush extends StatefulWidget {
  const _SheetPush({
    required this.route,
    required this.controller,
    required this.child,
  });

  final TopSheetRoute<dynamic> route;
  final AnimationController controller;
  final Widget child;

  @override
  State<_SheetPush> createState() => _SheetPushState();
}

class _SheetPushState extends State<_SheetPush> {
  double _startValue = 1;

  // How far the sheet moves over the whole transition.
  double get _travel =>
      MediaQuery.sizeOf(context).height - _sheetBottom(context);

  bool _shouldStart(Offset moved, bool atTop, bool atBottom) =>
      atBottom &&
      -moved.dy > moved.dx.abs() &&
      !widget.controller.isAnimating &&
      widget.route.popGestureEnabled;

  void _onStart(Offset downAt) {
    _startValue = widget.controller.value;
    widget.route.navigator!.didStartUserGesture();
  }

  void _onUpdate(Offset moved) {
    widget.controller.value = _startValue + moved.dy / _travel;
  }

  void _onEnd(Offset? velocity) {
    // In sheet heights per second, positive upwards.
    final double speed = -(velocity?.dy ?? 0) / _travel;
    finishPopGesture(
      controller: widget.controller,
      navigator: widget.route.navigator!,
      pop: velocity != null &&
          (speed.abs() >= 1 ? speed > 0 : widget.controller.value < 0.65),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PullDetector(
      shouldStart: _shouldStart,
      onStart: _onStart,
      onUpdate: _onUpdate,
      onEnd: _onEnd,
      child: widget.child,
    );
  }
}
