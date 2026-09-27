import 'package:flutter/material.dart';

import '../demo_data.dart';

const _accent = Color(0xFF009DE0);

class VenuePage extends StatelessWidget {
  const VenuePage({super.key, required this.venue});

  final Venue venue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: venue.color,
        foregroundColor: Colors.white,
        title: Text(venue.name),
      ),
      body: ListView(
        children: [
          Container(
            height: 180,
            color: venue.color,
            child: Icon(venue.icon, size: 96, color: Colors.white),
          ),
          for (var i = 1; i <= 8; i++)
            ListTile(
              title: Text('${venue.name} special #$i'),
              subtitle: const Text('Tap to open the item'),
              trailing: Text('\$${i * 3 + 6}'),
              // A plain MaterialPageRoute: the theme makes it swing.
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ItemPage(
                    title: '${venue.name} special #$i',
                    color: venue.color,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ItemPage extends StatelessWidget {
  const ItemPage({super.key, required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.alphaBlend(color.withAlpha(30), Colors.white),
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _accent),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Add to order'),
        ),
      ),
    );
  }
}
