import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transition_lab/transition_lab.dart';

const _pageKey = ValueKey('page');
const _half = Duration(milliseconds: 300); // half of the default 600 ms

Route<void> _route({Offset? center}) => CircularRevealRoute<void>(
      center: center,
      builder: (_) => const Scaffold(key: _pageKey, body: Text('page')),
    );

// The button that opens the page sits 50 px from the top-left corner.
Widget _app({Offset? center}) => MaterialApp(
      builder: (context, child) => TapPosition.tracker(child: child!),
      home: Scaffold(
        body: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.all(50),
            child: Align(
              alignment: Alignment.topLeft,
              child: TextButton(
                onPressed: () =>
                    Navigator.of(context).push(_route(center: center)),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

// The circle the page is clipped to, as its bounding box.
Rect _circle(WidgetTester tester) {
  final ClipPath clip = tester.widget<ClipPath>(
    find.ancestor(of: find.byKey(_pageKey), matching: find.byType(ClipPath)),
  );
  return clip.clipper!.getClip(const Size(800, 600)).getBounds();
}

void _expectCircle(Rect actual, Offset center, double radius) {
  expect(actual.center.dx, moreOrLessEquals(center.dx, epsilon: 0.01));
  expect(actual.center.dy, moreOrLessEquals(center.dy, epsilon: 0.01));
  expect(actual.width / 2, moreOrLessEquals(radius, epsilon: 0.01));
}

void main() {
  setUp(() => TapPosition.last = null);

  testWidgets('grows from the tap to the farthest corner and back',
      (tester) async {
    await tester.pumpWidget(_app());
    final Offset tap = tester.getCenter(find.text('open'));
    await tester.tap(find.text('open'));
    expect(TapPosition.last, tap);
    await tester.pump();
    await tester.pump(_half);

    final double t = Curves.fastOutSlowIn.transform(0.5);
    final double farthest =
        math.sqrt(math.pow(800 - tap.dx, 2) + math.pow(600 - tap.dy, 2));
    _expectCircle(_circle(tester), tap, farthest * t);

    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(_pageKey)), Offset.zero);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 225));
    _expectCircle(_circle(tester), tap, farthest * t);

    await tester.pumpAndSettle();
    expect(find.byKey(_pageKey), findsNothing);
  });

  testWidgets('an explicit center wins over the tap', (tester) async {
    await tester.pumpWidget(_app(center: const Offset(600, 450)));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(_half);

    final double t = Curves.fastOutSlowIn.transform(0.5);
    _expectCircle(_circle(tester), const Offset(600, 450), 750 * t);
  });

  testWidgets('without a tap, grows from the middle', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Text('home')));
    tester.state<NavigatorState>(find.byType(Navigator)).push(_route());
    await tester.pump();
    await tester.pump(_half);

    final double t = Curves.fastOutSlowIn.transform(0.5);
    _expectCircle(_circle(tester), const Offset(400, 300), 500 * t);
  });

  testWidgets('edge swipe closes it', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.dragFrom(const Offset(5, 300), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.byKey(_pageKey), findsNothing);
  });
}
