part of 'zoom_page_route.dart';

/// A page growing out of the Dynamic Island: the pill at the top of the
/// screen stretches out into the page, while the screen behind it blurs away
/// under the backdrop.
///
/// ```dart
/// Navigator.of(context).push(
///   IslandPageRoute(builder: (_) => TimerPage(timer: timer)),
/// );
/// ```
///
/// With a [tag] the page grows out of the [ZoomSource] with that tag instead,
/// so any pill-shaped widget can be its source.
///
/// Pulling the page down while its content is scrolled to the top shrinks it
/// around the finger, and letting go far or fast enough closes it. The pull is
/// disabled while a [PopScope] blocks popping.
///
/// The route assumes its navigator fills the screen, as the app's root
/// navigator does.
class IslandPageRoute<T> extends _SourcePageRoute<T> {
  /// Creates a route that grows its page out of the Dynamic Island.
  IslandPageRoute({
    this.tag,
    required super.builder,
    this.pillSize = const Size(126, 37),
    this.pillTop = 11,
    super.duration = const Duration(milliseconds: 520),
    super.reverseDuration = const Duration(milliseconds: 420),
    super.settings,
  });

  /// The [ZoomSource.tag] of the widget the page grows out of, or null to
  /// grow out of a pill of [pillSize] at the top of the screen.
  final Object? tag;

  /// The size of that pill. The default matches the Dynamic Island.
  final Size pillSize;

  /// How far below the top of the screen the pill sits.
  final double pillTop;

  @override
  Object? get _tag => tag;

  @override
  ({Rect rect, double radius})? _sourceFallback(Size size, EdgeInsets padding) {
    return (
      rect: Rect.fromLTWH(
        (size.width - pillSize.width) / 2,
        pillTop,
        pillSize.width,
        pillSize.height,
      ),
      radius: pillSize.height / 2,
    );
  }

  @override
  _ZoomStyle get _style => const _ZoomStyle(
        backdrop: Color(0x8C000000),
        shrink: 0.4,
        dragRadius: 36,
        fallbackScale: 0.5,
        fallbackRadius: 18,
        freeDrag: false,
        anchor: Alignment.topCenter,
        fillsWhileFading: true,
        scalesPage: false,
      );
}
