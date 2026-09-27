import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'gestures.dart';

const Curve _kCurve = Curves.easeInOut;

/// A page turn, as in Apple Books: the page is a sheet of paper whose bottom
/// corner on the leading edge lifts and folds over, the folded flap showing
/// the back of the page, until the page has turned away towards the trailing
/// edge. A push lays the page down the same way in reverse.
///
/// ```dart
/// Navigator.of(context).push(
///   PageCurlRoute(builder: (_) => BookPage(number: number + 1)),
/// );
/// ```
///
/// Dragging from the leading edge of the page lifts that corner under the
/// finger, and letting go far or fast enough turns the page away. The drag is
/// disabled while a [PopScope] blocks popping.
///
/// The paper is drawn from a snapshot of the page, taken as the turn starts,
/// so the page does not animate meanwhile.
class PageCurlRoute<T> extends PageRoute<T> {
  /// Creates a route whose page turns like a sheet of paper.
  PageCurlRoute({
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
    return _PageCurl(
      animation: animation,
      linear: popGestureInProgress,
      child: BackDragGesture(
        route: this,
        controller: controller!,
        edgeWidth: 32,
        // The corner moves twice as far as the page turns, so this keeps the
        // corner under the finger.
        travel: 2,
        popDistance: 0.3,
        child: child,
      ),
    );
  }

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}

class _PageCurl extends StatefulWidget {
  const _PageCurl({
    required this.animation,
    required this.linear,
    required this.child,
  });

  final Animation<double> animation;
  final bool linear;
  final Widget child;

  @override
  State<_PageCurl> createState() => _PageCurlState();
}

class _PageCurlState extends State<_PageCurl> {
  final SnapshotController _snapshot = SnapshotController();
  final _CurlPainter _painter = _CurlPainter();
  double _direction = 1;

  @override
  void initState() {
    super.initState();
    widget.animation.addListener(_update);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _direction = trailingSign(context);
    _update();
  }

  @override
  void didUpdateWidget(_PageCurl oldWidget) {
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
    final double value = widget.animation.value;
    final double laid = widget.linear ? value : _kCurve.transform(value);
    _snapshot.allowSnapshotting = laid < 1;
    _painter.update(laid: laid, direction: _direction);
  }

  @override
  Widget build(BuildContext context) {
    return SnapshotWidget(
      controller: _snapshot,
      painter: _painter,
      // Platform views cannot be snapshotted; the page then stays as it is.
      mode: SnapshotMode.permissive,
      autoresize: true,
      child: widget.child,
    );
  }
}

/// Paints the page folded along a straight line, with the part beyond the
/// line reflected over as a flap.
class _CurlPainter extends SnapshotPainter {
  // 1 while the page lies flat, 0 once it has turned away.
  double _laid = 1;
  double _direction = 1;

  void update({required double laid, required double direction}) {
    if (laid == _laid && direction == _direction) return;
    _laid = laid;
    _direction = direction;
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
    final double w = size.width;
    final double h = size.height;
    final double turned = 1 - _laid;
    // The corner that lifts, and where it has been carried to: along the
    // bottom towards the trailing edge, rising in between.
    final Offset corner = Offset(_direction > 0 ? 0 : w, h);
    final Offset lifted = corner +
        Offset(
          _direction * 2 * w * turned,
          -0.5 * math.min(w, h) * math.sin(math.pi * turned),
        );
    final Canvas canvas = context.canvas;
    final Rect page = Offset.zero & size;
    final Paint imagePaint = Paint()..filterQuality = FilterQuality.medium;
    void drawPage() =>
        canvas.drawImageRect(image, Offset.zero & sourceSize, page, imagePaint);

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    final Offset carried = lifted - corner;
    if (carried.distance < 0.5) {
      drawPage();
      canvas.restore();
      return;
    }
    // The fold is the line halfway between the corner and where it went;
    // [normal] points from the lifted part towards the part lying flat.
    final Offset fold = (corner + lifted) / 2;
    final Offset normal = carried / carried.distance;
    final double extent = (w + h) * 4;
    final Path flat = _halfPlane(fold, normal, extent);
    final Path lifting = _halfPlane(fold, -normal, extent);

    // The part still lying flat.
    canvas.save();
    canvas.clipRect(page);
    canvas.clipPath(flat);
    drawPage();
    canvas.restore();

    // The shadow of the fold on the page underneath.
    canvas.save();
    canvas.clipRect(page);
    canvas.clipPath(lifting);
    canvas.drawRect(
      page,
      Paint()
        ..shader = ui.Gradient.linear(
          fold,
          fold - normal * 36,
          const [Color(0x40000000), Color(0x00000000)],
        ),
    );
    canvas.restore();

    // The flap: the lifted part folded over the fold, showing its back, which
    // lets the print show through mirrored.
    canvas.save();
    canvas.transform(_reflection(fold, normal).storage);
    canvas.clipRect(page);
    canvas.clipPath(lifting);
    drawPage();
    canvas.drawRect(page, Paint()..color = const Color(0xD9FFFFFF));
    // Darker along the fold, where the paper bends away from the light.
    canvas.drawRect(
      page,
      Paint()
        ..shader = ui.Gradient.linear(
          fold,
          fold - normal * (carried.distance / 2),
          const [Color(0x33000000), Color(0x05000000)],
        ),
    );
    canvas.restore();

    canvas.restore();
  }

  // The half of the plane on the [normal] side of the line through [point].
  static Path _halfPlane(Offset point, Offset normal, double extent) {
    final Offset along = Offset(-normal.dy, normal.dx) * extent;
    final Offset out = normal * extent;
    return Path()
      ..moveTo((point + along).dx, (point + along).dy)
      ..lineTo((point - along).dx, (point - along).dy)
      ..lineTo((point - along + out).dx, (point - along + out).dy)
      ..lineTo((point + along + out).dx, (point + along + out).dy)
      ..close();
  }

  // Mirrors the plane across the line through [point] with unit [normal].
  static Matrix4 _reflection(Offset point, Offset normal) {
    final double nx = normal.dx;
    final double ny = normal.dy;
    final double k = 2 * (point.dx * nx + point.dy * ny);
    return Matrix4(
      1 - 2 * nx * nx, -2 * nx * ny, 0, 0, //
      -2 * nx * ny, 1 - 2 * ny * ny, 0, 0, //
      0, 0, 1, 0, //
      k * nx, k * ny, 0, 1, //
    );
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
  bool shouldRepaint(_CurlPainter oldPainter) =>
      oldPainter._laid != _laid || oldPainter._direction != _direction;
}
