import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transition_lab/transition_lab.dart';

const _pageKey = ValueKey('page');

// A horizontal strip wider than the screen on top, a vertical list below.
Widget _app({
  bool canPop = true,
  TextDirection direction = TextDirection.ltr,
}) =>
    MaterialApp(
      builder: (context, child) =>
          Directionality(textDirection: direction, child: child!),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              FullSwipePageRoute<void>(
                builder: (_) => PopScope(
                  canPop: canPop,
                  child: Scaffold(
                    key: _pageKey,
                    body: Column(
                      children: [
                        SizedBox(
                          height: 100,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              for (var i = 0; i < 20; i++)
                                SizedBox(width: 80, child: Text('media $i')),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            children: [
                              for (var i = 0; i < 40; i++)
                                ListTile(title: Text('message $i')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

double _progress(WidgetTester tester) =>
    ModalRoute.of(tester.element(find.byKey(_pageKey)))!.animation!.value;

void main() {
  testWidgets('a swipe from the middle of the page drives the transition',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final TestGesture gesture = await tester.startGesture(
      const Offset(300, 400),
    );
    await gesture.moveBy(const Offset(40, 0)); // past the touch slop
    await tester.pump();
    final double before = _progress(tester);
    await gesture.moveBy(const Offset(312, 0));
    await tester.pump();
    // 312 px of the 1.3 x 800 px the page travels.
    expect(_progress(tester), moreOrLessEquals(before - 0.3, epsilon: 1e-6));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byKey(_pageKey), findsNothing);
  });

  testWidgets('a short swipe settles back', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.timedDragFrom(
      const Offset(300, 400),
      const Offset(100, 0),
      const Duration(milliseconds: 500),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(_pageKey)), Offset.zero);
  });

  testWidgets('a horizontal scrollable keeps its own drags', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.timedDragFrom(
      const Offset(300, 50),
      const Offset(-300, 0),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();
    await tester.timedDragFrom(
      const Offset(300, 50),
      const Offset(400, 0),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(_pageKey)), Offset.zero);
  });

  testWidgets('swipes left in right-to-left layouts', (tester) async {
    await tester.pumpWidget(_app(direction: TextDirection.rtl));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.timedDragFrom(
      const Offset(500, 400),
      const Offset(400, 0),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(_pageKey)), Offset.zero);

    await tester.timedDragFrom(
      const Offset(500, 400),
      const Offset(-400, 0),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(_pageKey), findsNothing);
  });

  testWidgets('respects PopScope', (tester) async {
    await tester.pumpWidget(_app(canPop: false));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.timedDragFrom(
      const Offset(300, 400),
      const Offset(400, 0),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(_pageKey)), Offset.zero);
  });
}
