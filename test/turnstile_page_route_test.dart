import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transition_lab/transition_lab.dart';

const _homeKey = ValueKey('home');
const _pageKey = ValueKey('page');

Future<void> _pushHalfway(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(key: _homeKey, body: Text('home'))),
  );
  tester.state<NavigatorState>(find.byType(Navigator)).push(
        TurnstileRoute<void>(
          builder: (_) => const Scaffold(key: _pageKey, body: Text('page')),
        ),
      );
  await tester.pump();
  // Half of 450 ms, and easeInOutCubic is 0.5 there too.
  await tester.pump(const Duration(milliseconds: 225));
}

// How far the pages have turned at the halfway point. easeInOutCubic is a
// Bezier, so it is a little past 0.5 there.
final double _turned = Curves.easeInOutCubic.transform(0.5);

// Where the trailing top corner of an 800 x 600 page lands once it has
// pivoted [angle] around its leading edge, seen from 1000 px away.
Offset _trailingTop(double angle) {
  final double w = 1 + 800 * math.sin(angle) / 1000;
  return Offset(800 * math.cos(angle) / w, 300 - 300 / w);
}

void main() {
  testWidgets('the new page pivots in around its leading edge', (tester) async {
    await _pushHalfway(tester);

    // The new page still has this much of the 70 degrees to turn.
    final Offset expected = _trailingTop(70 * math.pi / 180 * (1 - _turned));
    final Offset corner = tester.getTopRight(find.byKey(_pageKey));
    expect(corner.dx, moreOrLessEquals(expected.dx, epsilon: 0.01));
    expect(corner.dy, moreOrLessEquals(expected.dy, epsilon: 0.01));
    // The leading edge is the hinge, so it stays put.
    expect(tester.getTopLeft(find.byKey(_pageKey)), Offset.zero);

    await tester.pumpAndSettle();
    expect(tester.getTopRight(find.byKey(_pageKey)), const Offset(800, 0));
  });

  testWidgets('the page underneath pivots away the same way', (tester) async {
    await _pushHalfway(tester);

    final Offset expected = _trailingTop(70 * math.pi / 180 * _turned);
    final Offset corner = tester.getTopRight(find.byKey(_homeKey));
    expect(corner.dx, moreOrLessEquals(expected.dx, epsilon: 0.01));
  });

  testWidgets('edge swipe goes back', (tester) async {
    await _pushHalfway(tester);
    await tester.pumpAndSettle();

    await tester.dragFrom(const Offset(5, 300), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.byKey(_pageKey), findsNothing);
  });
}
