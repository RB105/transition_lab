import 'package:flutter/material.dart';

/// A Control Center, pulled down from the top of the screen.
class ControlsPage extends StatelessWidget {
  const ControlsPage({super.key});

  static const List<(IconData, String, Color)> _controls = [
    (Icons.wifi, 'Wi-Fi', Color(0xFF0A84FF)),
    (Icons.bluetooth, 'Bluetooth', Color(0xFF0A84FF)),
    (Icons.airplanemode_active, 'Airplane', Color(0xFFFF9F0A)),
    (Icons.flashlight_on, 'Torch', Color(0xFF8E8E93)),
    (Icons.music_note, 'Now playing', Color(0xFFFF375F)),
    (Icons.screen_rotation, 'Rotation lock', Color(0xFFFF375F)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.6,
                  children: [
                    for (final (IconData icon, String name, Color color)
                        in _controls)
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(icon, color: color),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 12, bottom: 4),
                child: Text(
                  'Push the sheet back up from anywhere to close it.',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              Container(
                width: 120,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
