import 'dart:math' as math;

import 'package:flutter/material.dart';

const _passColor = Color(0xFF0B3D91);

/// The front of the boarding pass, on the home page.
class BoardingPassCard extends StatelessWidget {
  const BoardingPassCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const TextStyle label = TextStyle(color: Colors.white70, fontSize: 12);
    const TextStyle code = TextStyle(
      color: Colors.white,
      fontSize: 30,
      fontWeight: FontWeight.w800,
    );
    return Material(
      color: _passColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tashkent', style: label),
                  Text('TAS', style: code),
                ],
              ),
              Expanded(
                child: Icon(Icons.flight_takeoff, color: Colors.white),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Istanbul', style: label),
                  Text('IST', style: code),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The back of the boarding pass, shown by turning the card over.
class BoardingPassPage extends StatelessWidget {
  const BoardingPassPage({super.key});

  @override
  Widget build(BuildContext context) {
    const TextStyle label = TextStyle(color: Colors.white70, fontSize: 13);
    const TextStyle value = TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.w700,
    );
    return Scaffold(
      backgroundColor: _passColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Flight', style: label),
                      Text('HY 271', style: value),
                    ],
                  ),
                  Column(
                    children: [
                      Text('Gate', style: label),
                      Text('B12', style: value),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Seat', style: label),
                      Text('14A', style: value),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const SizedBox.square(
                  dimension: 200,
                  child: CustomPaint(painter: _CodePainter()),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Boarding 07:00 · Departure 07:30', style: label),
              const Spacer(),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _passColor,
                ),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.flip),
                label: const Text('Flip back'),
              ),
              const SizedBox(height: 8),
              const Text('or swipe from the left edge', style: label),
            ],
          ),
        ),
      ),
    );
  }
}

/// A made-up 2D barcode.
class _CodePainter extends CustomPainter {
  const _CodePainter();

  static const int _cells = 21;

  @override
  void paint(Canvas canvas, Size size) {
    final double cell = size.width / _cells;
    final math.Random random = math.Random(271);
    final Paint dark = Paint()..color = Colors.black;
    final Paint light = Paint()..color = Colors.white;
    Rect square(int x, int y, int side) =>
        Rect.fromLTWH(x * cell, y * cell, side * cell, side * cell);

    for (var y = 0; y < _cells; y++) {
      for (var x = 0; x < _cells; x++) {
        if (random.nextBool()) canvas.drawRect(square(x, y, 1), dark);
      }
    }
    // The nested squares in three corners.
    for (final (int x, int y) in const [
      (0, 0),
      (_cells - 7, 0),
      (0, _cells - 7)
    ]) {
      canvas
        ..drawRect(square(x - 1, y - 1, 9), light)
        ..drawRect(square(x, y, 7), dark)
        ..drawRect(square(x + 1, y + 1, 5), light)
        ..drawRect(square(x + 2, y + 2, 3), dark);
    }
  }

  @override
  bool shouldRepaint(_CodePainter oldDelegate) => false;
}
