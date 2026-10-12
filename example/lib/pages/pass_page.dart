import 'package:flutter/material.dart';

import '../demo_data.dart';

/// A pass in the stack on the home page.
class PassCard extends StatelessWidget {
  const PassCard({super.key, required this.pass});

  final Pass pass;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: pass.color,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            pass.from.substring(0, 3).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Expanded(
            child: Icon(Icons.flight_takeoff, color: Colors.white70),
          ),
          Text(
            pass.to.substring(0, 3).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// The pass, risen out of the stack.
class PassPage extends StatelessWidget {
  const PassPage({super.key, required this.pass});

  final Pass pass;

  @override
  Widget build(BuildContext context) {
    const TextStyle label = TextStyle(color: Colors.white70, fontSize: 12);
    const TextStyle value = TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w700,
    );
    return Scaffold(
      backgroundColor: pass.color,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(pass.code, style: value),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('From', style: label),
                      Text(pass.from, style: value),
                    ],
                  ),
                  const Icon(Icons.flight, color: Colors.white),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('To', style: label),
                      Text(pass.to, style: value),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Gate', style: label),
                      Text(pass.gate, style: value),
                    ],
                  ),
                  const SizedBox(width: 40),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Seat', style: label),
                      Text('14A', style: value),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Container(
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.qr_code_2, size: 56),
              ),
              const SizedBox(height: 20),
              const Text(
                'The pass rose out of the stack, which dropped away behind '
                'it. Pull the page down to drop it back on top.',
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
