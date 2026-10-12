import 'package:flutter/material.dart';
import 'package:transition_lab/transition_lab.dart';

import '../demo_data.dart';

/// One step of a checkout. Each step pushes the next one along the same
/// axis, so they read as neighbours.
class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key, required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final (String title, String detail) = checkoutSteps[step];
    final bool last = step == checkoutSteps.length - 1;
    return Scaffold(
      appBar: AppBar(title: Text('${step + 1}. $title')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: (step + 1) / checkoutSteps.length,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(detail, style: const TextStyle(fontSize: 16)),
            const Spacer(),
            Text(
              last
                  ? 'Swipe from the left edge to walk back through the steps.'
                  : 'The two pages travel sideways together and cross-fade, '
                      'so the step you left and the one you reach feel like '
                      'neighbours.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            if (!last)
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  SharedAxisPageRoute<void>(
                    builder: (_) => CheckoutPage(step: step + 1),
                  ),
                ),
                child: const Text('Next step'),
              ),
          ],
        ),
      ),
    );
  }
}
