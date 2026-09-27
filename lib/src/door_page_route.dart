import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'gestures.dart';

const Curve _kCurve = Curves.easeInOutCubic;

// How far each leaf swings open, around its outer edge.
const double _kOpenAngle = 70 * math.pi / 180;

/// A doorway: the page underneath splits down the middle and its two halves
/// swing open like double doors, away from the viewer, revealing the new
/// page as it comes forward. Popping closes the doors again.
///
/// ```dart
/// Navigator.of(context).push(
///   DoorPageRoute(builder: (_) => const RoomPage()),
/// );
/// ```
///
/// The doors are drawn from a snapshot of the page underneath, taken as the
/// transition starts, so that page does not animate meanwhile. The page can
/// be popped with the iOS edge swipe, which is disabled while a [PopScope]
/// blocks popping.
class DoorPageRoute<T> extends PageRoute<T> {
  /// Creates a route that opens the page underneath like a pair of doors.
  DoorPageRoute({
    required this.builder,
    this.duration = const Duration(milliseconds: 700),
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

  // Static, so a DoorPageRoute underneath keeps its own, identical, doors.
  @override
  DelegatedTransitionBuilder? get delegatedTransition => _openDoors;

  static Widget? _openDoors(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) {
    return _Doors(
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
    return _Doors(
      animation: secondaryAnimation,
      linear: linear,
      child: _Doorway(
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

// The doors are seen from the middle of the page, from twice its width away.
double _perspective(Size size) => size.width * 2;

/// Where the inner edge of the left door is on screen once the doors are
/// [q] open. The right one mirrors it.
///
/// Each door swings around its outer edge, which also slides outwards by
/// half the page width, so that fully open the doors are off the page.
double _leftDoorInnerEdge(double q, Size size) {
  final double half = size.width / 2;
  final double angle = q * _kOpenAngle;
  // Relative to the middle of the page.
  final double x = -half * q + half * math.cos(angle) - half;
  final double z = -half * math.sin(angle);
  return half + x / (1 - z / _perspective(size));
}

/// The new page, showing through the opening between the doors.
class _Doorway extends AnimatedWidget {
  const _Doorway({
    required Animation<double> animation,
    required this.linear,
    required this.child,
  }) : super(listenable: animation);

  final bool linear;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double t = _progress(listenable as Animation<double>, linear);
    return ClipRect(
      clipper: _OpeningClipper(t),
      clipBehavior: t == 1 ? Clip.none : Clip.hardEdge,
      child: Transform.scale(
        scale: 0.85 + 0.15 * t,
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          // The room behind the doors is darker until they are open.
          decoration: BoxDecoration(
            color:
                t == 1 ? null : Colors.black.withValues(alpha: 0.5 * (1 - t)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _OpeningClipper extends CustomClipper<Rect> {
  const _OpeningClipper(this.open);

  final double open;

  @override
  Rect getClip(Size size) {
    final double left = _leftDoorInnerEdge(open, size);
    return Rect.fromLTRB(left, 0, size.width - left, size.height);
  }

  @override
  bool shouldReclip(_OpeningClipper oldClipper) => oldClipper.open != open;
}

/// The page underneath, drawn as two doors swinging open over black.
class _Doors extends StatefulWidget {
  const _Doors({
    required this.animation,
    required this.linear,
    required this.child,
  });

  final Animation<double> animation;
  final bool linear;
  final Widget? child;

  @override
  State<_Doors> createState() => _DoorsState();
}

class _DoorsState extends State<_Doors> {
  final SnapshotController _snapshot = SnapshotController();
  final _DoorsPainter _painter = _DoorsPainter();

  @override
  void initState() {
    super.initState();
    widget.animation.addListener(_update);
    _update();
  }

  @override
  void didUpdateWidget(_Doors oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      oldWidget.animation.removeListener(_update);
      widget.animation.addListener(_update);
    }
    _update();
  }

  @override
  void dispose() {
    widget.animation.removeListener(_update);
    _snapshot.dispose();
    _painter.dispose();
    super.dispose();
  }

  void _update() {
    final double q = _progress(widget.animation, widget.linear);
    _snapshot.allowSnapshotting = q > 0;
    _painter.open = q;
  }

  @override
  Widget build(BuildContext context) {
    return SnapshotWidget(
      controller: _snapshot,
      painter: _painter,
      // Platform views cannot be snapshotted; the page then stays as it is.
      mode: SnapshotMode.permissive,
      autoresize: true,
      child: widget.child ?? const SizedBox.shrink(),
    );
  }
}

class _DoorsPainter extends SnapshotPainter {
  double _open = 0;

  set open(double value) {
    if (value == _open) return;
    _open = value;
    notifyListeners();
  }

  @override
  void paintSnapshot(
    PaintingContext context,
    Offset offset,
    Size size,
    ui.Image image,
    Size sourceSize,
    double pixelRatio,
  ) {
    final Canvas canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);
    _paintDoor(canvas, size, image, sourceSize, left: true);
    _paintDoor(canvas, size, image, sourceSize, left: false);
    canvas.restore();
  }

  void _paintDoor(
    Canvas canvas,
    Size size,
    ui.Image image,
    Size sourceSize, {
    required bool left,
  }) {
    final double width = size.width;
    final double height = size.height;
    final double angle = _open * _kOpenAngle;
    // The outer edge the door swings around slides outwards.
    final double hinge = left ? -width / 2 * _open : width + width / 2 * _open;
    canvas.save();
    // Seen from the middle of the page.
    canvas.translate(width / 2, height / 2);
    canvas.transform(
      (Matrix4.identity()..setEntry(3, 2, -1 / _perspective(size))).storage,
    );
    canvas.translate(hinge - width / 2, 0);
    // Both doors swing away from the viewer.
    canvas.transform(Matrix4.rotationY(left ? angle : -angle).storage);
    final Rect door = left
        ? Rect.fromLTWH(0, -height / 2, width / 2, height)
        : Rect.fromLTWH(-width / 2, -height / 2, width / 2, height);
    final Rect source = left
        ? Rect.fromLTWH(0, 0, sourceSize.width / 2, sourceSize.height)
        : Rect.fromLTWH(
            sourceSize.width / 2, 0, sourceSize.width / 2, sourceSize.height);
    canvas.drawImageRect(
      image,
      source,
      door,
      Paint()..filterQuality = FilterQuality.medium,
    );
    // A door gets darker as it turns away from the light.
    canvas.drawRect(
      door,
      Paint()..color = Colors.black.withValues(alpha: 0.45 * _open),
    );
    canvas.restore();
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset,
    Size size,
    PaintingContextCallback painter,
  ) {
    painter(context, offset);
  }

  @override
  bool shouldRepaint(_DoorsPainter oldPainter) => oldPainter._open != _open;
}
