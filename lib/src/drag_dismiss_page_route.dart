part of 'zoom_page_route.dart';

/// The photo viewer of Instagram, Telegram and iOS Photos: the page opens
/// over a dark background, and a vertical drag lets it follow the finger in
/// any direction while the background fades. Letting go far or fast enough
/// closes it.
///
/// ```dart
/// GestureDetector(
///   onTap: () => Navigator.of(context).push(
///     DragDismissPageRoute(
///       tag: photo,
///       builder: (_) => PhotoViewer(photo: photo),
///     ),
///   ),
///   child: ZoomSource(tag: photo, child: Thumbnail(photo)),
/// )
/// ```
///
/// With a [tag], the page grows out of the [ZoomSource] with that tag and
/// flies back into it when closed. Without one, it fades in and is thrown
/// off the screen in the direction it was dragged.
///
/// The drag only starts vertically, so a horizontal [PageView] of photos
/// inside still swipes between them. Downwards it starts while a vertical
/// scrollable in the page is scrolled to the top, upwards while it is
/// scrolled to the bottom. It is disabled while a [PopScope] blocks popping.
///
/// The route assumes its navigator fills the screen, as the app's root
/// navigator does.
class DragDismissPageRoute<T> extends _SourcePageRoute<T> {
  /// Creates a route whose page can be dragged away.
  DragDismissPageRoute({
    this.tag,
    required super.builder,
    this.backgroundColor = const Color(0xFF000000),
    super.duration = const Duration(milliseconds: 350),
    super.reverseDuration = const Duration(milliseconds: 300),
    super.settings,
  });

  /// The [ZoomSource.tag] of the widget the page grows out of and flies back
  /// into, or null to fade the page in and throw it away.
  final Object? tag;

  /// Painted behind the page. It fades out as the page is dragged away.
  final Color backgroundColor;

  @override
  Object? get _tag => tag;

  @override
  _ZoomStyle get _style => _ZoomStyle(
        backdrop: backgroundColor,
        shrink: 0.25,
        dragRadius: 0,
        fallbackScale: 0.9,
        fallbackRadius: 0,
        freeDrag: true,
        anchor: Alignment.center,
        fillsWhileFading: false,
      );
}
