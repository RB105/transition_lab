import 'package:flutter/material.dart';

import '../demo_data.dart';

/// The card a destination is shown as, both in the grid and as the page
/// header, so the zoom can cross-fade between the two.
class DestinationCard extends StatelessWidget {
  const DestinationCard({
    super.key,
    required this.destination,
    this.radius = 20,
    this.iconSize = 56,
    this.titleSize = 18,
    this.topInset = 0,
  });

  final Destination destination;
  final double radius;
  final double iconSize;
  final double titleSize;
  final double topInset;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: destination.color,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            top: topInset,
            child: Center(
              child: Icon(
                destination.icon,
                size: iconSize,
                color: Colors.white,
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  destination.city,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  destination.tagline,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: titleSize * 0.62,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DestinationPage extends StatelessWidget {
  const DestinationPage({super.key, required this.destination});

  final Destination destination;

  @override
  Widget build(BuildContext context) {
    final EdgeInsets padding = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(bottom: padding.bottom + 80),
            children: [
              SizedBox(
                height: 420,
                child: DestinationCard(
                  destination: destination,
                  radius: 0,
                  iconSize: 120,
                  titleSize: 34,
                  topInset: padding.top,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var day = 1; day <= 5; day++) ...[
                      Text(
                        'Day $day',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'A morning walk around the city centre, local food '
                        "for lunch, and ${destination.city}'s best-known "
                        'sights in the evening.',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.45,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: padding.top + 8,
            right: 16,
            child: RoundIconButton(
              icon: Icons.close,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: padding.bottom + 16,
            child: const IgnorePointer(
              child: Center(
                child: HintPill(text: 'Pull down to shrink back into the card'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class HintPill extends StatelessWidget {
  const HintPill({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }
}
