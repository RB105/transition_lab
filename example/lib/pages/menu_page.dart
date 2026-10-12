import 'package:flutter/material.dart';

/// A side menu, slid in from the leading edge over the page.
class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  static const List<(IconData, String)> _items = [
    (Icons.person_outline, 'Profile'),
    (Icons.bookmark_outline, 'Saved'),
    (Icons.group_outlined, 'People'),
    (Icons.archive_outlined, 'Archive'),
    (Icons.settings_outlined, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surfaceContainerHighest,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: colors.primary,
                    child: const Text(
                      'B',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bahrom',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text('See your profile'),
                    ],
                  ),
                ],
              ),
            ),
            for (final (IconData icon, String title) in _items)
              ListTile(leading: Icon(icon), title: Text(title)),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Drag the panel towards the left edge to close it, or tap the '
                'dimmed page beside it.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
