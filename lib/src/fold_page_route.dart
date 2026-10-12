import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'gestures.dart';

const Curve _kCurve = Curves.easeOutCubic;

// How far each half is folded back when the page is closed.
const double _kFoldAngle = math.pi / 2;

/// Flipboard's fold: the new page arrives folded in half along a crease
/// across its middle, and opens flat, while the page underneath sinks back
/// and dims. Popping folds it closed again.
///
/// ```dart
/// Navigator.of(context).push(
///   FoldPageRoute(builder: (_) => ArticlePage(article: article)),
/// );
/// ```
///
/// The folding page is drawn from a snapshot taken as the transition starts,
/// so it does not rebuild while it folds. The page can be popped with the iOS
/// edge swipe, which is disabled while a [PopScope] blocks popping.
class FoldPageRoute<T> extends PageRoute<T> {
  /// Creates a route that unfolds its page.
  FoldPageRoute({
    required this.builder,
    this.duration = const Duration(milliseconds: 600),
    this.reverseDuration,
    this.coveredScale = 0.94,
    this.coveredOverlayColor = const Color(0x4D000000),
    super.settings,
  });

  /// Builds the primary contents of the route.
  final WidgetBuilder builder;

  /// How long a push takes.
  final Duration duration;

  /// How long a pop takes. Defaults to [duration].
  final Duration? reverseDuration;

  /// The scale of the page underneath once covered.
  final double coveredScale;

  /// The color painted over the page underneath once covered. It fades in
  /// from transparent.
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
  DelegatedTransitionBuilder? get delegatedTransition => _sinkBack;

  Widget? _sinkBack(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) {
    return _Covered(
      route: this,
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
    return _Covered(
      route: this,
      animation: secondaryAnimation,
      linear: linear,
      child: _Fold(
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

/// The page underneath, sinking back behind the folding page.
class _Covered extends AnimatedWidget {
  const _Covered({
    required this.route,
    required Animation<double> animation,
    required this.linear,
    required this.child,
  }) : super(listenable: animation);

  final FoldPageRoute<dynamic> route;
  final bool linear;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final double q = _progress(listenable as Animation<double>, linear);
    final Color overlay = route.coveredOverlayColor;
    return DecoratedBox(
      decoration: BoxDecoration(color: q == 0 ? null : Colors.black),
      child: Transform.scale(
        scale: 1 - (1 - route.coveredScale) * q,
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            color: q == 0 ? null : Color.lerp(overlay.withAlpha(0), overlay, q),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// The new page, drawn as two halves hinged on a crease across its middle.
class _Fold extends StatefulWidget {
  const _Fold({
    required this.animation,
    required this.linear,
    required this.child,
  });

  final Animation<double> animation;
  final bool linear;
  final Widget child;

  @override
  State<_Fold> createState() => _FoldState();
}

class _FoldState extends State<_Fold> {
  final SnapshotController _snapshot = SnapshotController();
  final _FoldPainter _painter = _FoldPainter();

  @override
  void initState() {
    super.initState();
    widget.animation.addListener(_update);
    _update();
  }

  @override
  void didUpdateWidget(_Fold oldWidget) {
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
    // 1 while folded shut, 0 once the page lies flat.
    final double fold = 1 - _progress(widget.animation, widget.linear);
    _snapshot.allowSnapshotting = fold > 0;
    _painter.fold = fold;
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

class _FoldPainter extends SnapshotPainter {
  double _fold = 1;

  set fold(double value) {
    if (value == _fold) return;
    _fold = value;
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
    _paintHalf(canvas, size, image, sourceSize, top: true);
    _paintHalf(canvas, size, image, sourceSize, top: false);
    canvas.restore();
  }

  void _paintHalf(
    Canvas canvas,
    Size size,
    ui.Image image,
    Size sourceSize, {
    required bool top,
  }) {
    final double width = size.width;
    final double height = size.height;
    final double angle = _fold * _kFoldAngle;
    canvas.save();
    // Seen from the crease, from one and a half page heights away.
    canvas.translate(width / 2, height / 2);
    canvas.transform(
      (Matrix4.identity()..setEntry(3, 2, -1 / (height * 1.5))).storage,
    );
    // Both halves fold away from the viewer.
    canvas.transform(Matrix4.rotationX(top ? angle : -angle).storage);
    final Rect half = top
        ? Rect.fromLTWH(-width / 2, -height / 2, width, height / 2)
        : Rect.fromLTWH(-width / 2, 0, width, height / 2);
    final Rect source = top
        ? Rect.fromLTWH(0, 0, sourceSize.width, sourceSize.height / 2)
        : Rect.fromLTWH(
            0, sourceSize.height / 2, sourceSize.width, sourceSize.height / 2);
    canvas.drawImageRect(
      image,
      source,
      half,
      Paint()..filterQuality = FilterQuality.medium,
    );
    // A half gets darker as it folds away from the light.
    canvas.drawRect(
      half,
      Paint()..color = Colors.black.withValues(alpha: 0.5 * _fold),
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
  bool shouldRepaint(_FoldPainter oldPainter) => oldPainter._fold != _fold;
}
