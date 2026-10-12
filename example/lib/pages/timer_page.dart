import 'package:flutter/material.dart';

/// The pill at the top of the screen the island page grows out of.
class IslandPill extends StatelessWidget {
  const IslandPill({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.black,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          borderRadius: BorderRadius.circular(19),
          onTap: onTap,
          child: const SizedBox(
            width: 126,
            height: 37,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer_outlined, color: Color(0xFF32D74B), size: 18),
                SizedBox(width: 8),
                Text(
                  '04:32',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A live activity, opened out of the Dynamic Island.
class TimerPage extends StatelessWidget {
  const TimerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
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
              const Text(
                'Timer',
                style: TextStyle(color: Colors.white54, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                '04:32',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 72,
                  fontWeight: FontWeight.w200,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  FilledButton.tonal(
                      onPressed: () {}, child: const Text('Pause')),
                  const SizedBox(width: 12),
                  OutlinedButton(onPressed: () {}, child: const Text('Cancel')),
                ],
              ),
              const Spacer(),
              const Text(
                'The pill stretched out into this page and the screen behind '
                'it went dark. Pull the page down to put it back.',
                style: TextStyle(color: Colors.white54, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
