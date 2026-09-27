import 'package:flutter/material.dart';

import 'gestures.dart';

const Curve _kCurve = Curves.easeOutCubic;

/// Hosts a page that minimizes into a bar at the bottom of the screen and
/// expands back, like the players of YouTube, Spotify and Apple Music.
///
/// Put it above the app's navigator, so the bar stays over every page:
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => MiniPlayer(child: child!),
///   // ...
/// );
///
/// MiniPlayer.of(context).open(
///   builder: (_) => PlayerPage(track: track),
///   barBuilder: (_) => PlayerBar(track: track),
/// );
/// ```
///
/// Pulling the open page down from anywhere while its content is scrolled to
/// the top shrinks it into the bar, and tapping the bar or dragging it up
/// expands it again. Dragging the bar down closes the player. The page stays
/// alive while minimized, so whatever plays in it carries on.
///
/// The page and the bar sit outside the app's navigator, in an [Overlay] of
/// their own, so [Navigator.of] does not reach the app's navigator from
/// them. Pages underneath can leave room for the bar with [barSpaceOf].
class MiniPlayer extends StatefulWidget {
  /// Hosts the player over [child].
  const MiniPlayer({
    super.key,
    this.barHeight = 64,
    this.bottomInset = 0,
    this.duration = const Duration(milliseconds: 350),
    required this.child,
  });

  /// The height of the bar the page minimizes into.
  final double barHeight;

  /// Room kept free below the bar, e.g. for a bottom navigation bar. The
  /// bottom safe area is kept free as well.
  final double bottomInset;

  /// How long a full expand or minimize takes.
  final Duration duration;

  /// The rest of the app, usually its navigator.
  final Widget child;

  /// The state of the closest [MiniPlayer], to open, expand, minimize or
  /// close the player.
  static MiniPlayerState of(BuildContext context) {
    final MiniPlayerState? state = maybeOf(context);
    assert(state != null, 'No MiniPlayer above this context.');
    return state!;
  }

  /// Like [of], but null when there is no [MiniPlayer] above [context].
  static MiniPlayerState? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_MiniPlayerScope>()?.state;

  /// How much room above the bottom safe area the bar takes while the player
  /// is open, and 0 while it is closed. [context] rebuilds when that changes.
  static double barSpaceOf(BuildContext context) {
    final _MiniPlayerScope? scope =
        context.dependOnInheritedWidgetOfExactType<_MiniPlayerScope>();
    if (scope == null || !scope.open) return 0;
    return scope.state.widget.barHeight + scope.state.widget.bottomInset;
  }

  @override
  State<MiniPlayer> createState() => MiniPlayerState();
}

/// Opens, expands, minimizes and closes a [MiniPlayer].
class MiniPlayerState extends State<MiniPlayer> with TickerProviderStateMixin {
  late final AnimationController _expansion;
  late final AnimationController _hidden; // slides the bar off the screen
  late final OverlayEntry _page;

  WidgetBuilder? _builder;
  WidgetBuilder? _barBuilder;
  int _opened = 0; // keys the page, so each one opened starts afresh

  /// Whether the player is open, expanded or minimized.
  bool get isOpen => _builder != null;

  /// How far the player is expanded: 0 minimized into the bar, 1 full
  /// screen.
  Animation<double> get expansion => _expansion.view;

  @override
  void initState() {
    super.initState();
    _expansion = AnimationController(vsync: this, duration: widget.duration);
    _hidden = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _page = OverlayEntry(builder: _buildPage, maintainState: true);
  }

  @override
  void didUpdateWidget(MiniPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _expansion.duration = widget.duration;
  }

  @override
  void dispose() {
    _page
      ..remove()
      ..dispose();
    _expansion.dispose();
    _hidden.dispose();
    super.dispose();
  }

  /// Opens the player expanded, with the page [builder] builds, and the bar
  /// [barBuilder] builds for while it is minimized. Replaces anything open.
  void open({
    required WidgetBuilder builder,
    required WidgetBuilder barBuilder,
  }) {
    setState(() {
      _builder = builder;
      _barBuilder = barBuilder;
      _opened++;
    });
    _page.markNeedsBuild();
    _hidden.value = 0;
    _expansion.animateTo(1, curve: _kCurve);
  }

  /// Expands the player to full screen.
  void expand() {
    if (isOpen) _expansion.animateTo(1, curve: _kCurve);
  }

  /// Minimizes the player into the bar.
  void minimize() {
    if (isOpen) _expansion.animateTo(0, curve: _kCurve);
  }

  /// Minimizes the player, slides the bar away and closes it.
  Future<void> close() async {
    if (!isOpen) return;
    final int opened = _opened;
    if (_expansion.value > 0) await _expansion.animateTo(0, curve: _kCurve);
    await _hidden.animateTo(1);
    // Something else may have been opened meanwhile.
    if (!mounted || opened != _opened) return;
    setState(() {
      _builder = null;
      _barBuilder = null;
    });
    _page.markNeedsBuild();
    _hidden.value = 0;
  }

  double get _dock => MediaQuery.paddingOf(context).bottom + widget.bottomInset;

  // How far the top of the player moves between minimized and expanded.
  double get _travel =>
      MediaQuery.sizeOf(context).height - _dock - widget.barHeight;

  // Settles the expansion after a drag; [velocity] is positive downwards.
  void _settle(double velocity) {
    final bool expand =
        velocity.abs() > 700 ? velocity < 0 : _expansion.value > 0.5;
    expand ? this.expand() : minimize();
  }

  void _onBarDragUpdate(DragUpdateDetails details) {
    final double dy = details.primaryDelta!;
    if (_hidden.value > 0 || (_expansion.value == 0 && dy > 0)) {
      _hidden.value += dy / (widget.barHeight + _dock);
    } else {
      _expansion.value -= dy / _travel;
    }
  }

  void _onBarDragEnd(DragEndDetails details) {
    final double velocity = details.primaryVelocity ?? 0;
    if (_hidden.value > 0) {
      if (_hidden.value > 0.5 || velocity > 700) {
        close();
      } else {
        _hidden.animateTo(0);
      }
      return;
    }
    _settle(velocity);
  }

  bool _shouldStartPull(Offset moved, bool atTop, bool atBottom) =>
      atTop &&
      moved.dy > moved.dx.abs() &&
      _expansion.value == 1 &&
      !_expansion.isAnimating;

  Widget _buildPage(BuildContext context) {
    final WidgetBuilder? builder = _builder;
    if (builder == null) return const SizedBox.shrink();
    return KeyedSubtree(
      key: ValueKey<int>(_opened),
      child: Builder(builder: builder),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _MiniPlayerScope(
      state: this,
      open: isOpen,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          Positioned.fill(
            child: Offstage(
              offstage: !isOpen,
              child: AnimatedBuilder(
                animation: Listenable.merge([_expansion, _hidden]),
                builder: _buildPanel,
                // Built once: the page lives in its own overlay.
                child: PullDetector(
                  shouldStart: _shouldStartPull,
                  onUpdate: (moved) =>
                      _expansion.value = 1 - moved.dy / _travel,
                  onEnd: (velocity) =>
                      velocity == null ? expand() : _settle(velocity.dy),
                  child: Overlay(initialEntries: [_page]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanel(BuildContext context, Widget? page) {
    final Size size = MediaQuery.sizeOf(context);
    final double e = _expansion.value;
    final double dock = _dock;
    final double hidden = _hidden.value * (widget.barHeight + dock);
    final WidgetBuilder? barBuilder = _barBuilder;
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: _travel * (1 - e) + hidden,
          bottom: dock * (1 - e) - hidden,
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            elevation: 6 * (1 - e),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // The page keeps its full-screen layout; the panel reveals
                // it from the top as it grows.
                Positioned(
                  left: 0,
                  top: 0,
                  width: size.width,
                  height: size.height,
                  child: IgnorePointer(
                    ignoring: e < 1,
                    child: Opacity(
                      opacity: ((e - 0.15) / 0.5).clamp(0.0, 1.0),
                      child: page,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: widget.barHeight,
                  child: IgnorePointer(
                    ignoring: e > 0.5,
                    child: Opacity(
                      opacity: (1 - e / 0.3).clamp(0.0, 1.0),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: expand,
                        onVerticalDragUpdate: _onBarDragUpdate,
                        onVerticalDragEnd: _onBarDragEnd,
                        child: barBuilder == null
                            ? null
                            : Builder(builder: barBuilder),
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

class _MiniPlayerScope extends InheritedWidget {
  const _MiniPlayerScope({
    required this.state,
    required this.open,
    required super.child,
  });

  final MiniPlayerState state;
  final bool open;

  @override
  bool updateShouldNotify(_MiniPlayerScope oldWidget) => oldWidget.open != open;
}
