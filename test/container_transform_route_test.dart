import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transition_lab/transition_lab.dart';

const _pageKey = ValueKey('page');

// The source card sits at (100, 50) and is 200 x 100 on the 800 x 600 screen.
Widget _app({Object tag = 'card'}) => MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(left: 100, top: 50),
            child: Align(
              alignment: Alignment.topLeft,
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  ContainerTransformRoute<void>(
                    tag: tag,
                    builder: (_) => const Scaffold(
                      key: _pageKey,
                      body: Text('page'),
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

// Where the full-size page sits once the card has grown [p] of the way: the
// window is the card stretched towards the whole screen, and the page is
// centred in it.
Offset _pageTopLeft(double p) {
  final Rect window = Rect.lerp(
    const Rect.fromLTWH(100, 50, 200, 100),
    const Rect.fromLTWH(0, 0, 800, 600),
    p,
  )!;
  return window.center - const Offset(400, 300);
}

void _expectTopLeft(WidgetTester tester, Offset expected) {
  final Offset actual = tester.getTopLeft(find.byKey(_pageKey));
  expect(actual.dx, moreOrLessEquals(expected.dx, epsilon: 0.01));
  expect(actual.dy, moreOrLessEquals(expected.dy, epsilon: 0.01));
}

double _sourceOpacity(WidgetTester tester) => tester
    .widget<Opacity>(
      find.descendant(
          of: find.byType(ZoomSource), matching: find.byType(Opacity)),
    )
    .opacity;

void main() {
  testWidgets('the card grows into the page without scaling it',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('card'));
    await tester.pump();
    await tester.pump(); // the HeroController keeps it offstage for a frame

    // The page is already full size, uncovered by the card's own rectangle.
    expect(tester.getSize(find.byKey(_pageKey)), const Size(800, 600));
    _expectTopLeft(tester, _pageTopLeft(0));
    expect(_sourceOpacity(tester), 0);

    await tester.pump(const Duration(milliseconds: 225)); // half of 450 ms
    _expectTopLeft(tester, _pageTopLeft(Curves.easeOutCubic.transform(0.5)));

    await tester.pumpAndSettle();
    _expectTopLeft(tester, Offset.zero);
  });

  testWidgets('it shrinks back into the card when popped', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('card'));
    await tester.pumpAndSettle();

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(find.byKey(_pageKey), findsNothing);
    expect(_sourceOpacity(tester), 1);
  });

  testWidgets('without a source it grows out of the middle', (tester) async {
    await tester.pumpWidget(_app(tag: 'missing'));
    await tester.tap(find.text('card'));
    await tester.pump();
    await tester.pump();

    // 60% of the screen, centred, so the page sits right where it will rest.
    _expectTopLeft(tester, Offset.zero);
    expect(_sourceOpacity(tester), 1);
  });

  testWidgets('pulling the page down closes it', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('card'));
    await tester.pumpAndSettle();

    final TestGesture gesture =
        await tester.startGesture(const Offset(400, 300));
    await gesture.moveBy(const Offset(0, 20));
    await gesture.moveBy(const Offset(0, 160));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byKey(_pageKey), findsNothing);
  });
}
