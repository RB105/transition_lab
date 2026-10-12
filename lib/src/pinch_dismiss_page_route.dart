part of 'zoom_page_route.dart';

/// The photo viewer of Apple Photos and Google Photos: two fingers pinching
/// the page together shrink it around the point between them, and letting go
/// while it is small closes it back into its thumbnail.
///
/// ```dart
/// GestureDetector(
///   onTap: () => Navigator.of(context).push(
///     PinchDismissPageRoute(
///       tag: photo,
///       builder: (_) => PhotoViewer(photo: photo),
///     ),
///   ),
///   child: ZoomSource(tag: photo, child: Thumbnail(photo)),
/// )
/// ```
///
/// Only two fingers close the page, so a single finger is left to the content:
/// a [PageView] of photos still swipes, and scrollables still scroll. For a
/// viewer closed with one finger, use [DragDismissPageRoute].
///
/// The pinch is disabled while a [PopScope] blocks popping. Without a matching
/// [ZoomSource], the page fades out in place.
///
/// The route assumes its navigator fills the screen, as the app's root
/// navigator does.
class PinchDismissPageRoute<T> extends _SourcePageRoute<T> {
  /// Creates a route whose page can be pinched away.
  PinchDismissPageRoute({
    this.tag,
    required super.builder,
    this.backgroundColor = const Color(0xFF000000),
    super.duration = const Duration(milliseconds: 350),
    super.reverseDuration = const Duration(milliseconds: 320),
    super.settings,
  });

  /// The [ZoomSource.tag] of the widget the page grows out of and shrinks
  /// back into, or null to fade the page in and out in place.
  final Object? tag;

  /// Painted behind the page. It fades out as the page is pinched away.
  final Color backgroundColor;

  @override
  Object? get _tag => tag;

  @override
  _ZoomStyle get _style => _ZoomStyle(
        backdrop: backgroundColor,
        shrink: 0.25,
        dragRadius: 24,
        fallbackScale: 0.9,
        fallbackRadius: 0,
        freeDrag: false,
        anchor: Alignment.center,
        fillsWhileFading: false,
        pinch: true,
      );
}
