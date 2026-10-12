import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transition_lab/transition_lab.dart';

const _homeKey = ValueKey('home');
const _pageKey = ValueKey('page');

// The pass sits at (100, 50) and is 200 x 100 on the 800 x 600 screen.
Widget _app() => MaterialApp(
      home: Scaffold(
        key: _homeKey,
        body: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(left: 100, top: 50),
            child: Align(
              alignment: Alignment.topLeft,
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  WalletPageRoute<void>(
                    tag: 'pass',
                    builder: (_) => const Scaffold(
                      key: _pageKey,
                      body: Text('page'),
                    ),
                  ),
                ),
                child: const ZoomSource(
                  tag: 'pass',
                  borderRadius: 14,
                  child: SizedBox(width: 200, height: 100, child: Text('pass')),
                ),
              ),
            ),
          ),
        ),
      ),
    );

// The page hangs below the top of the window, centred on it.
Offset _pageTopLeft(double p) {
  final Rect window = Rect.lerp(
    const Rect.fromLTWH(100, 50, 200, 100),
    const Rect.fromLTWH(0, 0, 800, 600),
    p,
  )!;
  return Offset(window.center.dx - 400, window.top);
}

void main() {
  testWidgets('the pass rises out of the stack', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('pass'));
    await tester.pump();
    await tester.pump(); // the HeroController keeps it offstage for a frame

    expect(tester.getSize(find.byKey(_pageKey)), const Size(800, 600));
    Offset expected = _pageTopLeft(0);
    Offset actual = tester.getTopLeft(find.byKey(_pageKey));
    expect(actual.dx, moreOrLessEquals(expected.dx, epsilon: 0.01));
    expect(actual.dy, moreOrLessEquals(expected.dy, epsilon: 0.01));

    await tester.pump(const Duration(milliseconds: 260)); // half of 520 ms
    expected = _pageTopLeft(Curves.easeOutCubic.transform(0.5));
    actual = tester.getTopLeft(find.byKey(_pageKey));
    expect(actual.dx, moreOrLessEquals(expected.dx, epsilon: 0.01));
    expect(actual.dy, moreOrLessEquals(expected.dy, epsilon: 0.01));

    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(_pageKey)), Offset.zero);
  });

  testWidgets('the stack underneath drops away', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('pass'));
    await tester.pumpAndSettle();

    // Shrunk to 0.94 around its bottom edge, then dropped by 8% of the
    // screen height.
    final Offset topLeft = tester.getTopLeft(find.byKey(_homeKey));
    expect(topLeft.dy,
        moreOrLessEquals(600 - 600 * 0.94 + 0.08 * 600, epsilon: 0.01));

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(_homeKey)), Offset.zero);
  });

  testWidgets('pulling the pass down drops it back', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('pass'));
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
