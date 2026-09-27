import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transition_lab/transition_lab.dart';

const _homeKey = ValueKey('home');
const _pageKey = ValueKey('page');

Future<void> _pumpHome(WidgetTester tester) => tester.pumpWidget(
      const MaterialApp(home: Scaffold(key: _homeKey, body: Text('home'))),
    );

void _push(WidgetTester tester) =>
    tester.state<NavigatorState>(find.byType(Navigator)).push(
          DoorPageRoute<void>(
            builder: (_) => const Scaffold(key: _pageKey, body: Text('page')),
          ),
        );

// The inner edge of the left door on an 800 px wide screen once the doors
// are [open]: it swings 70° away from the viewer around its outer edge,
// which slides out by up to half the width, seen from 1600 px away.
double _innerEdge(double open) {
  final double angle = open * 70 * math.pi / 180;
  final double x = -400 * open + 400 * math.cos(angle) - 400;
  final double z = -400 * math.sin(angle);
  return 400 + x / (1 + -z / 1600);
}

// The part of the screen the new page shows through.
Rect _opening(WidgetTester tester) {
  final ClipRect clip = tester.widget<ClipRect>(
    find
        .ancestor(of: find.byKey(_pageKey), matching: find.byType(ClipRect))
        .first,
  );
  return clip.clipper!.getClip(const Size(800, 600));
}

bool _snapshotting(WidgetTester tester) => tester
    .widget<SnapshotWidget>(
      find.ancestor(
          of: find.byKey(_homeKey), matching: find.byType(SnapshotWidget)),
    )
    .controller
    .allowSnapshotting;

void main() {
  testWidgets('the new page shows through the doors as they open',
      (tester) async {
    await _pumpHome(tester);
    _push(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350)); // half of 700 ms

    final double open = Curves.easeInOutCubic.transform(0.5);
    final Rect opening = _opening(tester);
    expect(opening.left, moreOrLessEquals(_innerEdge(open), epsilon: 0.01));
    expect(
        opening.right, moreOrLessEquals(800 - _innerEdge(open), epsilon: 0.01));
    // The page underneath is drawn as the doors.
    expect(_snapshotting(tester), isTrue);

    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(_pageKey)), Offset.zero);
  });

  testWidgets('fully open, the doors are off the screen', (tester) async {
    expect(_innerEdge(1), lessThan(0));
  });

  testWidgets('popping closes the doors', (tester) async {
    await _pumpHome(tester);
    _push(tester);
    await tester.pumpAndSettle();

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(_snapshotting(tester), isTrue);

    await tester.pumpAndSettle();
    expect(find.byKey(_pageKey), findsNothing);
    expect(tester.getTopLeft(find.byKey(_homeKey)), Offset.zero);
  });

  testWidgets('edge swipe closes the doors with the finger', (tester) async {
    await _pumpHome(tester);
    _push(tester);
    await tester.pumpAndSettle();

    final TestGesture gesture = await tester.startGesture(
      const Offset(5, 300),
    );
    await gesture.moveBy(const Offset(400, 0)); // half the width
    await tester.pump();
    expect(_opening(tester).left, moreOrLessEquals(_innerEdge(0.5)));

    await gesture.moveBy(const Offset(100, 0));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byKey(_pageKey), findsNothing);
  });
}
