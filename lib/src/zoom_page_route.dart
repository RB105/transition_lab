import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'gestures.dart';

part 'container_transform_route.dart';
part 'drag_dismiss_page_route.dart';
part 'island_page_route.dart';
part 'pinch_dismiss_page_route.dart';
part 'wallet_page_route.dart';

/// Marks the widget a [ZoomPageRoute] or [DragDismissPageRoute] with the same
/// tag grows out of and shrinks back into.
///
/// Like [Hero] tags, a tag should be used by only one mounted [ZoomSource] at
/// a time.
class ZoomSource extends StatefulWidget {
  /// Makes [child] the source of the routes pushed with [tag].
  const ZoomSource({
    super.key,
    required this.tag,
    this.borderRadius = 0,
    required this.child,
  });

  /// Pairs this source with a [ZoomPageRoute.tag] or
  /// [DragDismissPageRoute.tag].
  final Object tag;

  /// The corner radius of [child], so the page starts with the same corners.
  final double borderRadius;

  /// The widget the page grows out of. It stays hidden while the page is
  /// open, and cross-fades into the page at the start of the zoom.
  final Widget child;

  static final Map<Object, _ZoomSourceState> _sources = {};

  @override
  State<ZoomSource> createState() => _ZoomSourceState();
}

class _ZoomSourceState extends State<ZoomSource> {
  bool _hidden = false;

  Rect? get globalRect {
    if (!mounted) return null;
    final RenderObject? box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  set hidden(bool value) {
    if (mounted && value != _hidden) setState(() => _hidden = value);
  }

  @override
  void initState() {
    super.initState();
    ZoomSource._sources[widget.tag] = this;
  }

  @override
  void didUpdateWidget(ZoomSource oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tag != widget.tag) {
      if (ZoomSource._sources[oldWidget.tag] == this) {
        ZoomSource._sources.remove(oldWidget.tag);
      }
      ZoomSource._sources[widget.tag] = this;
    }
  }

  @override
  void dispose() {
    if (ZoomSource._sources[widget.tag] == this) {
      ZoomSource._sources.remove(widget.tag);
    }
    super.dispose();
  }

  // The page flies in its place, so the original stays invisible meanwhile.
  @override
  Widget build(BuildContext context) =>
      Opacity(opacity: _hidden ? 0 : 1, child: widget.child);
}

/// The iOS 18 zoom transition, as in Photos and the App Store: the page grows
/// out of the [ZoomSource] with the same [tag] and shrinks back into it when
/// popped.
///
/// ```dart
/// GestureDetector(
///   onTap: () => Navigator.of(context).push(
///     ZoomPageRoute(tag: item, builder: (_) => ItemPage(item: item)),
///   ),
///   child: ZoomSource(tag: item, borderRadius: 20, child: ItemCard(item)),
/// )
/// ```
///
/// Pulling the page down while its content is scrolled to the top shrinks it
/// around the finger, and letting go far or fast enough closes it. Like the
/// edge swipe of other routes, the pull is disabled while a [PopScope] blocks
/// popping. Without a matching [ZoomSource], the page grows out of the middle
/// of the screen.
///
/// The route assumes its navigator fills the screen, as the app's root
/// navigator does.
class ZoomPageRoute<T> extends _SourcePageRoute<T> {
  /// Creates a route that zooms its page out of the [ZoomSource] with [tag].
  ZoomPageRoute({
    required this.tag,
    required super.builder,
    super.duration = const Duration(milliseconds: 500),
    super.reverseDuration = const Duration(milliseconds: 420),
    super.settings,
  });

  /// The [ZoomSource.tag] of the widget the page grows out of.
  final Object tag;

  @override
  Object? get _tag => tag;

  @override
  _ZoomStyle get _style => const _ZoomStyle(
        backdrop: Color(0x66000000),
        shrink: 0.45,
        dragRadius: 40,
        fallbackScale: 0.5,
        fallbackRadius: 24,
        freeDrag: false,
        anchor: Alignment.topLeft,
        fillsWhileFading: true,
      );
}

/// How a [_SourcePageRoute] looks, and how it reacts to a pull.
class _ZoomStyle {
  const _ZoomStyle({
    required this.backdrop,
    required this.shrink,
    required this.dragRadius,
    required this.fallbackScale,
    required this.fallbackRadius,
    required this.freeDrag,
    required this.anchor,
    required this.fillsWhileFading,
    this.scalesPage = true,
    this.pinch = false,
  });

  /// Painted behind the open page. It fades in with the page, and out as the
  /// page is pulled away.
  final Color backdrop;

  /// How much the page shrinks once pulled half the screen height.
  final double shrink;

  /// The largest corner radius of the page while it is pulled.
  final double dragRadius;

  /// Without a source, the page grows out of this share of the screen,
  /// centered, with [fallbackRadius] corners.
  final double fallbackScale;
  final double fallbackRadius;

  /// Whether a pull may also start upwards (while the content is scrolled to
  /// the bottom) and close the page in any direction. Without a source, a
  /// page closed that way is thrown off the screen.
  final bool freeDrag;

  /// The point of the page that stays put in the growing window: the top
  /// left for a page with a header, the middle for a centered photo, so it
  /// lands right on its thumbnail.
  final Alignment anchor;

  /// Whether the window is filled with the scaffold background while the
  /// page fades in over its source.
  final bool fillsWhileFading;

  /// Whether the page is scaled down into the window, as the zoom does, or
  /// laid out at full size and uncovered by it, as a container transform
  /// does.
  final bool scalesPage;

  /// Whether a two-finger pinch closes the page instead of a one-finger
  /// pull.
  final bool pinch;
}

/// A route whose page grows out of a [ZoomSource] and closes with a pull.
abstract class _SourcePageRoute<T> extends PageRoute<T> {
  _SourcePageRoute({
    required this.builder,
    required this.duration,
    required this.reverseDuration,
    super.settings,
  });

  /// Builds the primary contents of the route.
  final WidgetBuilder builder;

  /// How long the page takes to open.
  final Duration duration;

  /// How long the page takes to close.
  final Duration reverseDuration;

  Object? get _tag;
  _ZoomStyle get _style;

  /// Where the page grows from when no [ZoomSource] matches [_tag], or null
  /// to grow out of the middle of the screen.
  ({Rect rect, double radius})? _sourceFallback(
          Size size, EdgeInsets padding) =>
      null;

  _ZoomSourceState? _source;
  Rect? _sourceRect;
  double? _sourceRadius;
  Widget? _sourceChild;

  @override
  Duration get transitionDuration => duration;

  @override
  Duration get reverseTransitionDuration => reverseDuration;

  // Keeps the page underneath painted, so it shows while this one is pulled.
  @override
  bool get opaque => false;

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  void install() {
    super.install();
    final _ZoomSourceState? source =
        _tag == null ? null : ZoomSource._sources[_tag];
    if (source != null) {
      _source = source;
      _sourceRect = source.globalRect;
      _sourceRadius = source.widget.borderRadius;
      _sourceChild = source.widget.child;
      source.hidden = true;
    }
    animation!.addStatusListener(_revealSourceWhenClosed);
  }

  @override
  bool didPop(T? result) {
    // The source may have moved since the push, e.g. on rotation.
    _sourceRect = _source?.globalRect ?? _sourceRect;
    return super.didPop(result);
  }

  void _revealSourceWhenClosed(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) _source?.hidden = false;
  }

  @override
  void dispose() {
    final _ZoomSourceState? source = _source;
    if (source != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => source.hidden = false);
    }
    super.dispose();
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
    return _ZoomTransition(route: this, animation: animation, child: child);
  }

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}

class _ZoomTransition extends StatefulWidget {
  const _ZoomTransition({
    required this.route,
    required this.animation,
    required this.child,
  });

  final _SourcePageRoute<dynamic> route;
  final Animation<double> animation;
  final Widget child;

  @override
  State<_ZoomTransition> createState() => _ZoomTransitionState();
}

class _ZoomTransitionState extends State<_ZoomTransition>
    with SingleTickerProviderStateMixin {
  late CurvedAnimation _progress = _curved(widget.animation);
  late final AnimationController _settle;

  Offset _drag = Offset.zero; // how far the page has been pulled
  double _pinch = 1; // how far two fingers have pinched it together
  Offset _settleFrom = Offset.zero;
  double _settleFromPinch = 1;
  Offset _anchor = Offset.zero; // the point of the page under the finger
  Rect? _releasedAt; // where the page was let go when a pull closes it
  double _releasedRadius = 0;
  Rect? _thrownTo; // where a page without a source flies off to

  _ZoomStyle get _style => widget.route._style;

  // Fast start and a soft landing, in both directions.
  static CurvedAnimation _curved(Animation<double> parent) => CurvedAnimation(
        parent: parent,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutCubic.flipped,
      );

  @override
  void initState() {
    super.initState();
    // Created up front: a lazy one first touched in dispose() would create
    // its ticker on an unmounted widget.
    _settle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..addListener(_onSettle);
  }

  @override
  void didUpdateWidget(_ZoomTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      _progress.dispose();
      _progress = _curved(widget.animation);
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    _settle.dispose();
    super.dispose();
  }

  void _onSettle() {
    setState(() {
      final double t = Curves.easeOutCubic.transform(_settle.value);
      _drag = Offset.lerp(_settleFrom, Offset.zero, t)!;
      _pinch = lerpDouble(_settleFromPinch, 1, t)!;
    });
  }

  double _pull(Size size) {
    // A pinch is measured by how far the fingers came together instead.
    if (_style.pinch) return ((1 - _pinch) / 0.5).clamp(0.0, 1.0);
    final double distance =
        _style.freeDrag ? _drag.distance : math.max(_drag.dy, 0);
    return (distance / (size.height * 0.5)).clamp(0.0, 1.0);
  }

  // The page shrinks around the finger as it is pulled, or around the point
  // between two fingers as they pinch.
  Rect _draggedRect(Size size) {
    final double scale =
        _style.pinch ? _pinch : 1 - _style.shrink * _pull(size);
    return Rect.fromLTWH(
      _anchor.dx * (1 - scale) + _drag.dx,
      _anchor.dy * (1 - scale) + _drag.dy,
      size.width * scale,
      size.height * scale,
    );
  }

  double get _draggedRadius => _style.pinch
      ? _style.dragRadius * _pull(MediaQuery.sizeOf(context))
      : math.min(_drag.distance * 0.5, _style.dragRadius);

  bool _shouldStart(Offset moved, bool atTop, bool atBottom) {
    if (_settle.isAnimating || !widget.route.popGestureEnabled) return false;
    if (moved.dy.abs() <= moved.dx.abs()) return false;
    // Like iOS: a downward pull while the content is at the top.
    return moved.dy > 0 ? atTop : _style.freeDrag && atBottom;
  }

  void _onPullUpdate(Offset moved) => setState(() => _drag = moved);

  bool _shouldStartPinch() =>
      !_settle.isAnimating && widget.route.popGestureEnabled;

  void _onPinchUpdate(double scale, Offset moved) => setState(() {
        _pinch = scale.clamp(0.2, 1.0);
        _drag = moved;
      });

  // Pinched to less than this, the page closes when the fingers lift.
  static const double _kPinchCloses = 0.85;

  void _onPinchEnd(double? scale) {
    if (scale == null || scale >= _kPinchCloses) {
      _settleBack();
      return;
    }
    _release();
  }

  void _settleBack() {
    _settleFrom = _drag;
    _settleFromPinch = _pinch;
    _settle.forward(from: 0);
  }

  void _onPullEnd(Offset? velocity) {
    if (velocity == null || !_closes(velocity)) {
      _settleBack();
      return;
    }
    _release(velocity: velocity);
  }

  void _release({Offset? velocity}) {
    final Size size = MediaQuery.sizeOf(context);
    setState(() {
      _releasedAt = _draggedRect(size);
      _releasedRadius = _draggedRadius;
      if (velocity != null &&
          _style.freeDrag &&
          widget.route._sourceRect == null) {
        final Offset fling = velocity.distance > 700 ? velocity : _drag;
        _thrownTo = _releasedAt!.shift(
          fling / fling.distance * size.longestSide,
        );
      }
    });
    widget.route.navigator?.pop();
  }

  bool _closes(Offset velocity) {
    if (!_style.freeDrag) return _drag.dy > 110 || velocity.dy > 700;
    final double distance = _drag.distance;
    if (distance == 0) return false;
    // Speed away from where the pull started.
    final double away =
        (velocity.dx * _drag.dx + velocity.dy * _drag.dy) / distance;
    return away > 700 || (distance > 110 && away > -300);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, _) => _buildFrame(context),
    );
  }

  // A box of [size] placed in [window] so their anchor points coincide.
  Rect _anchored(Size size, Size window) =>
      _style.anchor.inscribe(size, Offset.zero & window);

  // The zoom scales the whole page down into the window; a container
  // transform leaves it at full size and lets the window uncover it.
  Widget _scaledIntoWindow({
    required Rect window,
    required Size size,
    required Widget child,
  }) {
    if (!_style.scalesPage) return child;
    return Transform.scale(
      scale: window.width / size.width,
      alignment: _style.anchor,
      child: child,
    );
  }

  Widget _buildFrame(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final _SourcePageRoute<dynamic> route = widget.route;
    final double p = _progress.value;
    final ({Rect rect, double radius})? fallback =
        route._sourceRect == null && _thrownTo == null
            ? route._sourceFallback(size, MediaQuery.paddingOf(context))
            : null;
    final Rect source = route._sourceRect ??
        _thrownTo ??
        fallback?.rect ??
        Rect.fromCenter(
          center: size.center(Offset.zero),
          width: size.width * _style.fallbackScale,
          height: size.height * _style.fallbackScale,
        );
    final double sourceRadius = route._sourceRadius ??
        (_thrownTo != null
            ? _releasedRadius
            : fallback?.radius ?? _style.fallbackRadius);
    final Rect expanded = _releasedAt ?? _draggedRect(size);
    final double expandedRadius =
        _releasedAt != null ? _releasedRadius : _draggedRadius;
    final Rect window = Rect.lerp(source, expanded, p)!;
    final double radius = lerpDouble(sourceRadius, expandedRadius, p)!;
    final bool atRest = p == 1 && _drag == Offset.zero && _releasedAt == null;
    // The page fades in over the source's own look during the first 30%. The
    // source stays opaque underneath, so nothing shows through the fade.
    final double pageOpacity = (p / 0.3).clamp(0.0, 1.0);
    final bool fading = pageOpacity < 1;
    final Widget? sourceChild = route._sourceChild;
    final Color backdrop = _style.backdrop;

    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: ColoredBox(
              color: backdrop.withValues(
                alpha: backdrop.a * p * (1 - _pull(size)),
              ),
            ),
          ),
        ),
        Positioned.fromRect(
          rect: window,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            clipBehavior: atRest ? Clip.none : Clip.antiAlias,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color:
                        fading && sourceChild != null && _style.fillsWhileFading
                            ? Theme.of(context).scaffoldBackgroundColor
                            : Colors.transparent,
                  ),
                ),
                if (sourceChild != null)
                  Positioned.fromRect(
                    rect: _anchored(source.size, window.size),
                    child: IgnorePointer(
                      child: Transform.scale(
                        scale: window.width / source.width,
                        alignment: _style.anchor,
                        child: Opacity(
                          opacity: fading ? 1 : 0,
                          child: Material(
                            type: MaterialType.transparency,
                            child: sourceChild,
                          ),
                        ),
                      ),
                    ),
                  ),
                // The page keeps its full-screen layout, and is either
                // scaled into the window or uncovered by it.
                Positioned.fromRect(
                  rect: _anchored(size, window.size),
                  child: _scaledIntoWindow(
                    window: window,
                    size: size,
                    child: Opacity(
                      opacity: pageOpacity,
                      child: _style.pinch
                          ? PinchDetector(
                              shouldStart: _shouldStartPinch,
                              onStart: (focal) => _anchor = focal,
                              onUpdate: _onPinchUpdate,
                              onEnd: _onPinchEnd,
                              child: widget.child,
                            )
                          : PullDetector(
                              shouldStart: _shouldStart,
                              onStart: (downAt) => _anchor = downAt,
                              onUpdate: _onPullUpdate,
                              onEnd: _onPullEnd,
                              child: widget.child,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
