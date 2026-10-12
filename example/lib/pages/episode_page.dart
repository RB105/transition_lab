import 'package:flutter/material.dart';
import 'package:transition_lab/transition_lab.dart';

/// The page a wipe uncovers, and the tile that opens it.
class EpisodeTile extends StatelessWidget {
  const EpisodeTile({super.key, required this.style, required this.onTap});

  final WipeStyle style;
  final VoidCallback onTap;

  static const Map<WipeStyle, (IconData, Color)> _looks = {
    WipeStyle.shutter: (Icons.blinds, Color(0xFF5E35B1)),
    WipeStyle.diagonal: (Icons.swipe_right_alt, Color(0xFF00897B)),
    WipeStyle.clock: (Icons.schedule, Color(0xFFD81B60)),
    WipeStyle.iris: (Icons.camera, Color(0xFFEF6C00)),
  };

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color) = _looks[style]!;
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 8),
              Text(
                style.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The page uncovered by the wipe.
class EpisodePage extends StatelessWidget {
  const EpisodePage({super.key, required this.style});

  final WipeStyle style;

  static const Map<WipeStyle, String> _notes = {
    WipeStyle.shutter: 'Five slats opened downwards at once, like a blind.',
    WipeStyle.diagonal:
        'A straight edge swept across from the leading top corner.',
    WipeStyle.clock: 'A hand swept around the middle, like a clock\'s.',
    WipeStyle.iris: 'A circle opened in the middle, like a camera\'s aperture.',
  };

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color) = EpisodeTile._looks[style]!;
    return Scaffold(
      backgroundColor: color,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
              const Spacer(),
              Icon(icon, size: 90, color: Colors.white),
              const SizedBox(height: 20),
              Text(
                style.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _notes[style]!,
                style: const TextStyle(color: Colors.white70, fontSize: 17),
              ),
              const Spacer(),
              const Text(
                'All four shapes are one route and one enum. Swipe from the '
                'left edge to go back.',
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
