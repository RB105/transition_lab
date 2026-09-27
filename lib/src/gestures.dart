// Gesture plumbing shared by the routes. Not exported.
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/cupertino.dart' show CupertinoRouteTransitionMixin;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// +1 when the trailing edge is on the right (LTR), -1 when on the left.
double trailingSign(BuildContext context) =>
    Directionality.maybeOf(context) == TextDirection.rtl ? -1 : 1;

/// Adds the iOS edge swipe back to [route]'s [child]. It reuses Cupertino's
/// edge swipe detector, whose own slide is neutralized by handing it
/// animations that never move.
Widget edgeSwipeBack<T>(
    PageRoute<T> route, BuildContext context, Widget child) {
  return CupertinoRouteTransitionMixin.buildPageTransitions<T>(
    route,
    context,
    kAlwaysCompleteAnimation,
    kAlwaysDismissedAnimation,
    child,
  );
}

/// Ends a back gesture that drove [controller] by hand the way Flutter's
/// Cupertino back gesture does: settles the page open again, or pops it.
void finishPopGesture({
  required AnimationController controller,
  required NavigatorState navigator,
  required bool pop,
}) {
  const Curve curve = Curves.fastLinearToSlowEaseIn;
  if (pop) {
    navigator.pop();
    if (controller.isAnimating) {
      controller.animateBack(
        0,
        duration: Duration(
          milliseconds: lerpDouble(0, 800, controller.value)!.floor(),
        ),
        curve: curve,
      );
    }
  } else {
    controller.animateTo(
      1,
      duration: Duration(
        milliseconds: math.min(
          lerpDouble(800, 0, controller.value)!.floor(),
          300,
        ),
      ),
      curve: curve,
    );
  }
  if (controller.isAnimating) {
    late final AnimationStatusListener listener;
    listener = (_) {
      navigator.didStopUserGesture();
      controller.removeStatusListener(listener);
    };
    controller.addStatusListener(listener);
  } else {
    navigator.didStopUserGesture();
  }
}

/// Drives [route]'s transition backwards with a horizontal drag towards the
/// trailing edge, and pops or settles it when the finger lets go.
class BackDragGesture extends StatefulWidget {
  const BackDragGesture({
    super.key,
    required this.route,
    required this.controller,
    this.edgeWidth,
    required this.travel,
    required this.popDistance,
    required this.child,
  });

  final ModalRoute<dynamic> route;

  /// The route's own controller.
  final AnimationController controller;

  /// The width of the strip along the leading edge where the drag may start,
  /// or null to let it start anywhere on the page.
  final double? edgeWidth;

  /// How many page widths the finger moves over the whole transition.
  final double travel;

  /// The share of the page width the finger has to move for a slow release
  /// to pop.
  final double popDistance;

  final Widget child;

  @override
  State<BackDragGesture> createState() => _BackDragGestureState();
}

class _BackDragGestureState extends State<BackDragGesture> {
  late final HorizontalDragGestureRecognizer _recognizer =
      HorizontalDragGestureRecognizer(debugOwner: this)
        ..onStart = _onStart
        ..onUpdate = _onUpdate
        ..onEnd = _onEnd
        ..onCancel = _onCancel;
  bool _active = false;

  void _onStart(DragStartDetails details) {
    _active = true;
    widget.route.navigator!.didStartUserGesture();
  }

  void _onUpdate(DragUpdateDetails details) {
    if (_active) {
      widget.controller.value -= trailingSign(context) *
          details.primaryDelta! /
          (context.size!.width * widget.travel);
    }
  }

  void _onEnd(DragEndDetails details) {
    if (_active) {
      _finish(trailingSign(context) *
          details.velocity.pixelsPerSecond.dx /
          context.size!.width);
    }
  }

  void _onCancel() {
    if (_active) _finish(0);
  }

  // [velocity] is in page widths per second, positive towards popping.
  void _finish(double velocity) {
    _active = false;
    finishPopGesture(
      controller: widget.controller,
      navigator: widget.route.navigator!,
      pop: velocity.abs() >= 1
          ? velocity > 0
          : widget.controller.value < 1 - widget.popDistance / widget.travel,
    );
  }

  void _addPointer(PointerDownEvent event) {
    if (widget.route.popGestureEnabled) _recognizer.addPointer(event);
  }

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  // Inner horizontal scrollables sit deeper in the tree, so they still win
  // their own drags.
  @override
  Widget build(BuildContext context) {
    final double? edgeWidth = widget.edgeWidth;
    if (edgeWidth == null) {
      return Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _addPointer,
        child: widget.child,
      );
    }
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        PositionedDirectional(
          start: 0,
          width: edgeWidth,
          top: 0,
          bottom: 0,
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: _addPointer,
          ),
        ),
      ],
    );
  }
}

/// Reports a finger pulling [child] around, and freezes scrolling inside it
/// while it does.
///
/// It listens to raw pointers, so scrollables inside still see the drag, but
/// cannot scroll during a pull.
class PullDetector extends StatefulWidget {
  const PullDetector({
    super.key,
    required this.shouldStart,
    this.onStart,
    required this.onUpdate,
    required this.onEnd,
    required this.child,
  });

  /// Whether a pointer that moved by [moved] since it went down starts a
  /// pull. [atTop] and [atBottom] tell whether the vertical scrollable in
  /// [child], if any, is scrolled to that end.
  final bool Function(Offset moved, bool atTop, bool atBottom) shouldStart;

  /// Called when a pull starts, with where the pointer went down.
  final ValueChanged<Offset>? onStart;

  /// Called as the pull moves, with how far the pointer moved since it went
  /// down.
  final ValueChanged<Offset> onUpdate;

  /// Called when the pull ends, with the pointer's velocity in logical
  /// pixels per second, or null when the pointer was cancelled.
  final ValueChanged<Offset?> onEnd;

  final Widget child;

  @override
  State<PullDetector> createState() => _PullDetectorState();
}

class _PullDetectorState extends State<PullDetector> {
  late ScrollBehavior _scrollBehavior;

  int? _pointer;
  Offset _downAt = Offset.zero;
  bool _decided = false;
  bool _pulling = false;
  bool _atTop = true;
  bool _atBottom = true;
  VelocityTracker? _velocity;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ScrollBehavior inherited = ScrollConfiguration.of(context);
    _scrollBehavior = inherited.copyWith(
      physics: _LockablePhysics(
        isLocked: () => _pulling,
        parent: inherited.getScrollPhysics(context),
      ),
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_pointer != null) return;
    _pointer = event.pointer;
    _downAt = event.position;
    _decided = false;
    _velocity = VelocityTracker.withKind(event.kind)
      ..addPosition(event.timeStamp, event.position);
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _pointer) return;
    _velocity?.addPosition(event.timeStamp, event.position);
    final Offset moved = event.position - _downAt;
    if (!_decided) {
      if (moved.distance < 8) return;
      _decided = true;
      _pulling = widget.shouldStart(moved, _atTop, _atBottom);
      if (_pulling) widget.onStart?.call(_downAt);
    }
    if (_pulling) widget.onUpdate(moved);
  }

  void _onPointerUp(PointerEvent event) {
    if (event.pointer != _pointer) return;
    _pointer = null;
    if (!_pulling) return;
    // Unlock scrolling after the scrollable has handled this pointer too.
    scheduleMicrotask(() => _pulling = false);
    widget.onEnd(
      event is PointerUpEvent
          ? _velocity?.getVelocity().pixelsPerSecond ?? Offset.zero
          : null,
    );
  }

  bool _onScroll(Notification notification) {
    final ScrollMetrics? metrics = switch (notification) {
      ScrollNotification(depth: 0, :final metrics) => metrics,
      ScrollMetricsNotification(depth: 0, :final metrics) => metrics,
      _ => null,
    };
    if (metrics != null && metrics.axis == Axis.vertical) {
      _atTop = metrics.pixels <= metrics.minScrollExtent + 0.5;
      _atBottom = metrics.pixels >= metrics.maxScrollExtent - 0.5;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<Notification>(
      onNotification: _onScroll,
      child: ScrollConfiguration(
        behavior: _scrollBehavior,
        child: Listener(
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerUp,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Wraps the platform physics so scrolling can be frozen during a pull.
class _LockablePhysics extends ScrollPhysics {
  const _LockablePhysics({required this.isLocked, super.parent});

  final ValueGetter<bool> isLocked;

  @override
  _LockablePhysics applyTo(ScrollPhysics? ancestor) =>
      _LockablePhysics(isLocked: isLocked, parent: buildParent(ancestor));

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) =>
      isLocked() ? 0 : super.applyPhysicsToUserOffset(position, offset);

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) =>
      super.createBallisticSimulation(position, isLocked() ? 0 : velocity);
}
