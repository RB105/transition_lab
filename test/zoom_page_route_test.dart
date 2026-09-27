import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transition_lab/transition_lab.dart';

const _pageKey = ValueKey('page');

// The source card sits at (100, 50) and is 200 x 100 on the 800 x 600 screen.
Widget _app({Object tag = 'card', bool canPop = true}) => MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(left: 100, top: 50),
            child: Align(
              alignment: Alignment.topLeft,
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  ZoomPageRoute<void>(
                    tag: tag,
                    builder: (_) => PopScope(
                      canPop: canPop,
                      child: Scaffold(
                        key: _pageKey,
                        body: ListView(
                          children: const [
                            SizedBox(height: 2000, child: Text('page')),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                child: const ZoomSource(
                  tag: 'card',
                  borderRadius: 12,
                  child: SizedBox(width: 200, height: 100, child: Text('card')),
                ),
              ),
            ),
          ),
        ),
      ),
    );

double _sourceOpacity(WidgetTester tester) => tester
    .widget<Opacity>(
      find.descendant(
          of: find.byType(ZoomSource), matching: find.byType(Opacity)),
    )
    .opacity;

void _expectRect(WidgetTester tester, Rect expected) {
  final Offset topLeft = tester.getTopLeft(find.byKey(_pageKey));
  final Offset bottomRight = tester.getBottomRight(find.byKey(_pageKey));
  expect(topLeft.dx, moreOrLessEquals(expected.left, epsilon: 0.01));
  expect(topLeft.dy, moreOrLessEquals(expected.top, epsilon: 0.01));
  expect(bottomRight.dx, moreOrLessEquals(expected.right, epsilon: 0.01));
  expect(bottomRight.dy, moreOrLessEquals(expected.bottom, epsilon: 0.01));
}

void main() {
  testWidgets('grows out of its source, which hides meanwhile', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('card'));
    await tester.pump();
    await tester.pump(); // the HeroController keeps it offstage for a frame

    // Starts over the card, scaled down to its width.
    _expectRect(tester, const Rect.fromLTWH(100, 50, 200, 150));
    expect(_sourceOpacity(tester), 0);

    await tester.pump(const Duration(milliseconds: 250));
    final double p = Curves.easeOutCubic.transform(0.5);
    final double width = 200 + 600 * p;
    _expectRect(
      tester,
      Rect.fromLTWH(100 * (1 - p), 50 * (1 - p), width, width * 0.75),
    );

    await tester.pumpAndSettle();
    _expectRect(tester, const Rect.fromLTWH(0, 0, 800, 600));
    expect(_sourceOpacity(tester), 0);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(find.byKey(_pageKey), findsNothing);
    expect(_sourceOpacity(tester), 1);
  });

  testWidgets('without a source, grows out of the middle', (tester) async {
    await tester.pumpWidget(_app(tag: 'missing'));
    await tester.tap(find.text('card'));
    await tester.pump();
    await tester.pump(); // the HeroController keeps it offstage for a frame
    _expectRect(tester, const Rect.fromLTWH(200, 150, 400, 300));
    expect(_sourceOpacity(tester), 1);
  });

  testWidgets('shrinks around the finger when pulled down', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('card'));
    await tester.pumpAndSettle();

    final TestGesture gesture = await tester.startGesture(
      const Offset(400, 300),
    );
    await gesture.moveBy(const Offset(0, 20));
    await gesture.moveBy(const Offset(0, 130));
    await tester.pump();

    // Pulled 150 of the 300 px that shrink it fully: scaled to 1 - 0.45 / 2
    // around the point first touched.
    const double scale = 0.775;
    _expectRect(
      tester,
      const Rect.fromLTWH(
          400 * (1 - scale), 300 * (1 - scale) + 150, 800 * scale, 600 * scale),
    );
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byKey(_pageKey), findsNothing);
  });

  testWidgets('a short pull springs back', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('card'));
    await tester.pumpAndSettle();

    await tester.timedDragFrom(
      const Offset(400, 300),
      const Offset(0, 60),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();
    _expectRect(tester, const Rect.fromLTWH(0, 0, 800, 600));
  });

  testWidgets('a pull does nothing while PopScope blocks popping',
      (tester) async {
    await tester.pumpWidget(_app(canPop: false));
    await tester.tap(find.text('card'));
    await tester.pumpAndSettle();

    await tester.timedDragFrom(
      const Offset(400, 300),
      const Offset(0, 300),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();
    _expectRect(tester, const Rect.fromLTWH(0, 0, 800, 600));
  });
}
