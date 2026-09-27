import 'package:flutter/material.dart';

import '../demo_data.dart';

class ShortcutPage extends StatelessWidget {
  const ShortcutPage({super.key, required this.shortcut});

  final Shortcut shortcut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: shortcut.color,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(shortcut.title),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(shortcut.icon, size: 120, color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'This page opened as a circle\nfrom where your finger landed',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: shortcut.color,
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
