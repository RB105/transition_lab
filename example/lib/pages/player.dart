import 'package:flutter/material.dart';
import 'package:transition_lab/transition_lab.dart';

import '../demo_data.dart';

class Artwork extends StatelessWidget {
  const Artwork({super.key, required this.track, required this.size});

  final Track track;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: track.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size / 10),
      ),
      child: Icon(track.icon, color: Colors.white, size: size / 2),
    );
  }
}

/// The full-screen player, shown in a [MiniPlayer]. Its progress keeps
/// running while it is minimized.
class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key, required this.track, required this.playing});

  final Track track;
  final ValueNotifier<bool> playing;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _position = AnimationController(
    vsync: this,
    duration: const Duration(minutes: 3),
  );

  @override
  void initState() {
    super.initState();
    widget.playing.addListener(_onPlaying);
    _onPlaying();
  }

  @override
  void dispose() {
    widget.playing.removeListener(_onPlaying);
    _position.dispose();
    super.dispose();
  }

  void _onPlaying() {
    if (widget.playing.value) {
      _position.repeat();
    } else {
      _position.stop();
    }
  }

  static String _time(double fraction) {
    final int seconds = (fraction * 180).floor();
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final Track track = widget.track;
    const TextStyle dim = TextStyle(color: Colors.white70);
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [track.colors.last, Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => MiniPlayer.of(context).minimize(),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Now playing',
                      textAlign: TextAlign.center,
                      style: dim,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 24),
              Center(child: Artwork(track: track, size: 280)),
              const SizedBox(height: 32),
              Text(
                track.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(track.artist, style: dim),
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: _position,
                builder: (context, _) => Column(
                  children: [
                    LinearProgressIndicator(
                      value: _position.value,
                      color: Colors.white,
                      backgroundColor: Colors.white24,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(_time(_position.value), style: dim),
                        const Spacer(),
                        const Text('3:00', style: dim),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(child: _PlayButton(playing: widget.playing, size: 64)),
              const SizedBox(height: 24),
              const Text(
                'Pull down to minimize: the progress keeps running in the '
                'bar. Tap the bar to come back, drag it down to close.',
                style: dim,
              ),
              const SizedBox(height: 16),
              for (var i = 1; i <= 12; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    'Lyrics line $i',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The bar the player minimizes into.
class PlayerBar extends StatelessWidget {
  const PlayerBar({super.key, required this.track, required this.playing});

  final Track track;
  final ValueNotifier<bool> playing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Artwork(track: track, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(track.artist, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          _PlayButton(playing: playing, size: 28, dark: true),
          IconButton(
            onPressed: () => MiniPlayer.of(context).close(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.playing,
    required this.size,
    this.dark = false,
  });

  final ValueNotifier<bool> playing;
  final double size;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: playing,
      builder: (context, value, _) => IconButton(
        iconSize: size,
        color: dark ? null : Colors.white,
        onPressed: () => playing.value = !value,
        icon: Icon(value ? Icons.pause_circle_filled : Icons.play_circle_fill),
      ),
    );
  }
}
