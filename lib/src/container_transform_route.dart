part of 'zoom_page_route.dart';

/// Material 3's container transform, as in Gmail, the Play Store and Google
/// Photos: the card the page was opened from grows into the page, its corners
/// rounding out, while its own look cross-fades into the page's.
///
/// ```dart
/// GestureDetector(
///   onTap: () => Navigator.of(context).push(
///     ContainerTransformRoute(
///       tag: mail,
///       builder: (_) => MailPage(mail: mail),
///     ),
///   ),
///   child: ZoomSource(tag: mail, borderRadius: 16, child: MailCard(mail)),
/// )
/// ```
///
/// Where [ZoomPageRoute] scales the whole page down into the card, so its text
/// grows with it, a container transform leaves the page at full size and lets
/// the growing card uncover it, as Material 3 specifies.
///
/// Pulling the page down while its content is scrolled to the top shrinks it
/// around the finger, and letting go far or fast enough closes it. The pull is
/// disabled while a [PopScope] blocks popping. Without a matching
/// [ZoomSource], the page grows out of the middle of the screen.
///
/// The route assumes its navigator fills the screen, as the app's root
/// navigator does.
class ContainerTransformRoute<T> extends _SourcePageRoute<T> {
  /// Creates a route that grows the [ZoomSource] with [tag] into its page.
  ContainerTransformRoute({
    required this.tag,
    required super.builder,
    super.duration = const Duration(milliseconds: 450),
    super.reverseDuration = const Duration(milliseconds: 380),
    super.settings,
  });

  /// The [ZoomSource.tag] of the card the page grows out of.
  final Object tag;

  @override
  Object? get _tag => tag;

  @override
  _ZoomStyle get _style => const _ZoomStyle(
        backdrop: Color(0x59000000),
        shrink: 0.35,
        dragRadius: 28,
        fallbackScale: 0.6,
        fallbackRadius: 16,
        freeDrag: false,
        anchor: Alignment.center,
        fillsWhileFading: true,
        scalesPage: false,
      );
}
