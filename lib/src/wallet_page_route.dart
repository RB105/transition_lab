part of 'zoom_page_route.dart';

const Curve _kWalletCurve = Curves.easeOutCubic;

/// Apple Wallet: the pass that was tapped rises out of the stack and opens
/// into a full page, while the stack it came from drops away and dims.
///
/// ```dart
/// GestureDetector(
///   onTap: () => Navigator.of(context).push(
///     WalletPageRoute(tag: pass, builder: (_) => PassPage(pass: pass)),
///   ),
///   child: ZoomSource(tag: pass, borderRadius: 14, child: PassCard(pass)),
/// )
/// ```
///
/// Pulling the page down while its content is scrolled to the top shrinks it
/// around the finger, and letting go far or fast enough drops it back onto
/// the stack. The pull is disabled while a [PopScope] blocks popping.
///
/// The route assumes its navigator fills the screen, as the app's root
/// navigator does.
class WalletPageRoute<T> extends _SourcePageRoute<T> {
  /// Creates a route that raises the [ZoomSource] with [tag] into its page.
  WalletPageRoute({
    required this.tag,
    required super.builder,
    this.coveredOffset = 0.08,
    this.coveredScale = 0.94,
    super.duration = const Duration(milliseconds: 520),
    super.reverseDuration = const Duration(milliseconds: 420),
    super.settings,
  });

  /// The [ZoomSource.tag] of the pass the page rises out of.
  final Object tag;

  /// How far the stack underneath drops, as a fraction of the screen height.
  final double coveredOffset;

  /// The scale of the stack underneath once the pass is open.
  final double coveredScale;

  @override
  Object? get _tag => tag;

  @override
  _ZoomStyle get _style => const _ZoomStyle(
        backdrop: Color(0x99000000),
        shrink: 0.4,
        dragRadius: 32,
        fallbackScale: 0.7,
        fallbackRadius: 14,
        freeDrag: false,
        anchor: Alignment.topCenter,
        fillsWhileFading: true,
        scalesPage: false,
      );

  @override
  DelegatedTransitionBuilder? get delegatedTransition => _dropStack;

  Widget? _dropStack(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) {
    return _Stack(
      route: this,
      animation: secondaryAnimation,
      linear: Navigator.maybeOf(context)?.userGestureInProgress ?? false,
      child: child,
    );
  }
}

/// The stack of passes underneath, dropping away as one of them opens.
class _Stack extends AnimatedWidget {
  const _Stack({
    required this.route,
    required Animation<double> animation,
    required this.linear,
    required this.child,
  }) : super(listenable: animation);

  final WalletPageRoute<dynamic> route;
  final bool linear;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final double value = (listenable as Animation<double>).value;
    final double q = linear ? value : _kWalletCurve.transform(value);
    final double scale = 1 - (1 - route.coveredScale) * q;
    return Transform(
      alignment: Alignment.bottomCenter,
      // Exactly identity at rest, so text and hit testing are untouched.
      transform: q == 0
          ? Matrix4.identity()
          : (Matrix4.translationValues(
              0,
              route.coveredOffset * MediaQuery.sizeOf(context).height * q,
              0,
            )..multiply(Matrix4.diagonal3Values(scale, scale, 1))),
      child: child,
    );
  }
}
