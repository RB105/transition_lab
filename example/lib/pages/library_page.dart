import 'package:flutter/material.dart';

import '../demo_data.dart';

/// A destination of a music app, reached with the fade through transition.
class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key, required this.section});

  final LibrarySection section;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: section.color,
        foregroundColor: Colors.white,
        title: Text(section.name),
      ),
      body: ListView(
        children: [
          Container(
            height: 150,
            color: section.color,
            alignment: Alignment.center,
            child: Icon(section.icon, size: 72, color: Colors.white),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${section.detail}. Nothing slid sideways on the way here: one '
              'page faded out, then this one faded in while it grew to size. '
              'That is what Material 3 uses between places that are not '
              'steps along a path.',
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
          for (final track in tracks)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: track.colors.first,
                child: Icon(track.icon, color: Colors.white, size: 20),
              ),
              title: Text(track.title),
              subtitle: Text(track.artist),
            ),
        ],
      ),
    );
  }
}
