import 'package:flutter/material.dart';

import '../demo_data.dart';

/// A door on the home page. Opening it splits the whole page into doors.
class DoorTile extends StatelessWidget {
  const DoorTile({super.key, required this.room, required this.onTap});

  final Room room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: room.color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          border: Border.all(color: Colors.black26, width: 3),
        ),
        child: Stack(
          children: [
            // Two panels and a handle.
            Column(
              children: [
                for (var i = 0; i < 2; i++)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black26, width: 2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
              ],
            ),
            Align(
              alignment: const Alignment(0.85, 0.1),
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFD54F),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: const Color(0xFFFFD54F),
                child: Text(
                  room.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The room behind the door.
class RoomPage extends StatelessWidget {
  const RoomPage({super.key, required this.room});

  final Room room;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF3E0), Color(0xFFD7B899)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.name,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(room.details),
                const Spacer(),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Icon(Icons.window, size: 72, color: Color(0xFF5D4037)),
                    Icon(Icons.bed, size: 110, color: Color(0xFF5D4037)),
                    Icon(Icons.light, size: 72, color: Color(0xFF5D4037)),
                  ],
                ),
                const Spacer(),
                const Text(
                  'The page you came from split into two doors and swung '
                  'open. Swipe from the left edge, or leave, to close them.',
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: room.color),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.logout),
                    label: const Text('Leave the room'),
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
