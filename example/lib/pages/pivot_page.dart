import 'package:flutter/material.dart';

import '../demo_data.dart';

/// A Metro tile on the home page.
class PivotTile extends StatelessWidget {
  const PivotTile({super.key, required this.pivot, required this.onTap});

  final Pivot pivot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: pivot.color,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 110,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  pivot.detail,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Text(
                  pivot.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
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

/// The page the turnstile pivots in.
class PivotPage extends StatelessWidget {
  const PivotPage({super.key, required this.pivot});

  final Pivot pivot;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              pivot.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 20),
            for (int i = 0; i < 5; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Container(width: 56, height: 56, color: pivot.color),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'item ${i + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        const Text(
                          'pivoted in around the leading edge',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const Text(
              'The page underneath turned away like a revolving door while '
              'this one turned in. Swipe from the left edge to go back.',
              style: TextStyle(color: Colors.white54, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
