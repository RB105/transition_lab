import 'package:flutter/material.dart';

import '../demo_data.dart';

/// An app opening with the depth transition.
class AppPage extends StatelessWidget {
  const AppPage({super.key, required this.app});

  final DemoApp app;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: app.color,
        foregroundColor: Colors.white,
        title: Text(app.name),
      ),
      body: ListView(
        children: [
          Container(
            height: 160,
            color: app.color,
            child: Icon(app.icon, size: 80, color: Colors.white),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'The home screen sank back and blurred as this app came '
              'forward. Swipe from the left edge to go back.',
            ),
          ),
          for (final (IconData icon, String title) in const [
            (Icons.wifi, 'Wi-Fi'),
            (Icons.bluetooth, 'Bluetooth'),
            (Icons.notifications_none, 'Notifications'),
            (Icons.dark_mode_outlined, 'Appearance'),
            (Icons.lock_outline, 'Privacy'),
          ])
            ListTile(
              leading: Icon(icon),
              title: Text(title),
              trailing: const Icon(Icons.chevron_right),
            ),
        ],
      ),
    );
  }
}

/// The app's icon on the home page.
class AppIcon extends StatelessWidget {
  const AppIcon({super.key, required this.app, required this.onTap});

  final DemoApp app;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: app.color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(app.icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 6),
          Text(app.name, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
