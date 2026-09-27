import 'package:flutter/material.dart';
import 'package:transition_lab/transition_lab.dart';

import '../demo_data.dart';

/// A place's details, as in Apple Maps, shown in a [SheetPageRoute].
class PlaceSheet extends StatelessWidget {
  const PlaceSheet({super.key, required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(
            child: Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: place.color,
                child: Icon(place.icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    PlaceRating(place: place),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              for (final (IconData icon, String label) in const [
                (Icons.directions, 'Directions'),
                (Icons.call, 'Call'),
                (Icons.public, 'Website'),
              ])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {},
                      child: Column(
                        children: [
                          Icon(icon, size: 20),
                          const SizedBox(height: 2),
                          Text(label, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: place.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(place.icon, size: 72, color: place.color),
          ),
          const SizedBox(height: 20),
          const Text(
            'Pull the sheet down from anywhere to close it. Open a place '
            'nearby to stack another sheet on top.',
          ),
          const SizedBox(height: 20),
          Text(
            'Nearby',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
          for (final nearby in places.where((p) => p != place))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: nearby.color,
                child: Icon(nearby.icon, color: Colors.white, size: 20),
              ),
              title: Text(nearby.name),
              subtitle: Text(nearby.kind),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                SheetPageRoute<void>(
                  builder: (_) => PlaceSheet(place: nearby),
                ),
              ),
            ),
          for (var i = 1; i <= 6; i++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.rate_review_outlined),
              title: Text('Review #$i'),
              subtitle: const Text('Worth the visit, especially at sunset.'),
            ),
        ],
      ),
    );
  }
}

/// A place's kind and star rating.
class PlaceRating extends StatelessWidget {
  const PlaceRating({super.key, required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final Color color = Colors.grey.shade600;
    return Row(
      children: [
        Text('${place.kind} · ', style: TextStyle(color: color)),
        const Icon(Icons.star, size: 14, color: Color(0xFFFFB300)),
        Text(' ${place.rating}', style: TextStyle(color: color)),
      ],
    );
  }
}
