import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transition_lab/transition_lab.dart';

const _pageKey = ValueKey('page');

// The thumbnail sits at (100, 50) and is 200 x 100 on the 800 x 600 screen.
Widget _app({Object tag = 'photo', bool canPop = true}) => MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(left: 100, top: 50),
            child: Align(
              alignment: Alignment.topLeft,
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  PinchDismissPageRoute<void>(
                    tag: tag,
                    builder: (_) => PopScope(
                      canPop: canPop,
                      child: const Scaffold(
                        key: _pageKey,
                        body: Text('page'),
                      ),
                    ),
                  ),
                ),
                child: const ZoomSource(
                  tag: 'photo',
                  child:
                      SizedBox(width: 200, height: 100, child: Text('thumb')),
                ),
              ),
            ),
          ),
        ),
      ),
    );

void _expectRect(WidgetTester tester, Rect expected) {
  final Offset topLeft = tester.getTopLeft(find.byKey(_pageKey));
  final Offset bottomRight = tester.getBottomRight(find.byKey(_pageKey));
  expect(topLeft.dx, moreOrLessEquals(expected.left, epsilon: 0.01));
  expect(topLeft.dy, moreOrLessEquals(expected.top, epsilon: 0.01));
  expect(bottomRight.dx, moreOrLessEquals(expected.right, epsilon: 0.01));
  expect(bottomRight.dy, moreOrLessEquals(expected.bottom, epsilon: 0.01));
}

// Pinches the two fingers [by] pixels closer together, around (400, 300).
Future<List<TestGesture>> _pinch(WidgetTester tester, double by) async {
  final TestGesture first = await tester.startGesture(const Offset(300, 300));
  final TestGesture second = await tester.startGesture(const Offset(500, 300));
  await first.moveBy(Offset(by / 2, 0));
  await second.moveBy(Offset(-by / 2, 0));
  await tester.pump();
  return [first, second];
}

void main() {
  testWidgets('the page grows out of its thumbnail', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('thumb'));
    await tester.pump();
    await tester.pump(); // the HeroController keeps it offstage for a frame

    // Scaled down to the thumbnail's width, centred on it.
    _expectRect(tester, const Rect.fromLTWH(100, 25, 200, 150));

    await tester.pumpAndSettle();
    _expectRect(tester, const Rect.fromLTWH(0, 0, 800, 600));
  });

  testWidgets('two fingers shrink it around the point between them',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('thumb'));
    await tester.pumpAndSettle();

    // The fingers are 200 px apart and end up 100 px apart: half the scale.
    final List<TestGesture> fingers = await _pinch(tester, 100);
    _expectRect(tester, const Rect.fromLTWH(200, 150, 400, 300));

    await fingers.first.up();
    await fingers.last.up();
    await tester.pumpAndSettle();
    expect(find.byKey(_pageKey), findsNothing);
  });

  testWidgets('a small pinch springs back', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('thumb'));
    await tester.pumpAndSettle();

    final List<TestGesture> fingers = await _pinch(tester, 10);
    await fingers.first.up();
    await fingers.last.up();
    await tester.pumpAndSettle();
    _expectRect(tester, const Rect.fromLTWH(0, 0, 800, 600));
  });

  testWidgets('one finger is left to the content', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('thumb'));
    await tester.pumpAndSettle();

    await tester.dragFrom(const Offset(400, 300), const Offset(0, 300));
    await tester.pumpAndSettle();
    _expectRect(tester, const Rect.fromLTWH(0, 0, 800, 600));
  });

  testWidgets('a pinch does nothing while PopScope blocks popping',
      (tester) async {
    await tester.pumpWidget(_app(canPop: false));
    await tester.tap(find.text('thumb'));
    await tester.pumpAndSettle();

    final List<TestGesture> fingers = await _pinch(tester, 150);
    _expectRect(tester, const Rect.fromLTWH(0, 0, 800, 600));
    await fingers.first.up();
    await fingers.last.up();
    await tester.pumpAndSettle();
    expect(find.byKey(_pageKey), findsOneWidget);
  });
}
