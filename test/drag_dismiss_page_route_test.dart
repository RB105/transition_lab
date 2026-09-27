import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transition_lab/transition_lab.dart';

const _viewerKey = ValueKey('viewer');

// A 100 x 100 thumbnail at (100, 50), opening a viewer with three photos in
// a horizontal PageView.
Widget _app({Object? tag = 'photo'}) => MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(left: 100, top: 50),
            child: Align(
              alignment: Alignment.topLeft,
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  DragDismissPageRoute<void>(
                    tag: tag,
                    builder: (_) => Scaffold(
                      key: _viewerKey,
                      backgroundColor: Colors.transparent,
                      body: PageView(
                        children: [
                          for (var i = 1; i <= 3; i++)
                            Center(child: Text('$i')),
                        ],
                      ),
                    ),
                  ),
                ),
                child: const ZoomSource(
                  tag: 'photo',
                  child:
                      SizedBox(width: 100, height: 100, child: Text('thumb')),
                ),
              ),
            ),
          ),
        ),
      ),
    );

double _thumbOpacity(WidgetTester tester) => tester
    .widget<Opacity>(
      find.descendant(
          of: find.byType(ZoomSource), matching: find.byType(Opacity)),
    )
    .opacity;

Offset _viewerTopLeft(WidgetTester tester) =>
    tester.getTopLeft(find.byKey(_viewerKey));

void _expectOffset(Offset actual, Offset expected) {
  expect(actual.dx, moreOrLessEquals(expected.dx, epsilon: 0.01));
  expect(actual.dy, moreOrLessEquals(expected.dy, epsilon: 0.01));
}

Future<void> _open(WidgetTester tester, {Object? tag = 'photo'}) async {
  await tester.pumpWidget(_app(tag: tag));
  await tester.tap(find.text('thumb'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('grows out of its thumbnail and flies back after a drag up',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('thumb'));
    await tester.pump();
    await tester.pump(); // the HeroController keeps it offstage for a frame
    // Centered on the thumbnail and scaled to its width: 100 x 75.
    _expectOffset(_viewerTopLeft(tester), const Offset(100, 62.5));
    expect(_thumbOpacity(tester), 0);

    await tester.pumpAndSettle();
    expect(_viewerTopLeft(tester), Offset.zero);

    // Upwards works as well as downwards.
    await tester.timedDragFrom(
      const Offset(400, 400),
      const Offset(0, -250),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(_viewerKey), findsNothing);
    expect(_thumbOpacity(tester), 1);
  });

  testWidgets('follows the finger in any direction once dragged vertically',
      (tester) async {
    await _open(tester);

    final TestGesture gesture = await tester.startGesture(
      const Offset(400, 300),
    );
    await gesture.moveBy(const Offset(0, 20));
    await gesture.moveBy(const Offset(130, 130));
    await tester.pump();

    // Pulled (130, 150): 198 px of the 300 px that shrink it by a quarter,
    // around the point first touched.
    final double scale = 1 - 0.25 * (const Offset(130, 150).distance / 300);
    _expectOffset(
      _viewerTopLeft(tester),
      Offset(400 * (1 - scale) + 130, 300 * (1 - scale) + 150),
    );

    await gesture.moveBy(const Offset(-130, -150));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(_viewerTopLeft(tester), Offset.zero);
  });

  testWidgets('without a tag, fades in and is thrown the way it was dragged',
      (tester) async {
    await tester.pumpWidget(_app(tag: null));
    await tester.tap(find.text('thumb'));
    await tester.pump();
    await tester.pump();
    // Grows from 90% of the screen, centered.
    _expectOffset(_viewerTopLeft(tester), const Offset(40, 30));
    expect(_thumbOpacity(tester), 1);
    await tester.pumpAndSettle();

    final TestGesture gesture = await tester.startGesture(
      const Offset(400, 300),
    );
    await gesture.moveBy(const Offset(0, 20));
    await gesture.moveBy(const Offset(100, 130));
    await tester.pump();
    final Offset released = _viewerTopLeft(tester);
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final Offset flying = _viewerTopLeft(tester);
    expect(flying.dx, greaterThan(released.dx));
    expect(flying.dy, greaterThan(released.dy));
    await tester.pumpAndSettle();
    expect(find.byKey(_viewerKey), findsNothing);
  });

  testWidgets('a horizontal swipe pages through the photos instead',
      (tester) async {
    await _open(tester);

    await tester.timedDragFrom(
      const Offset(600, 300),
      const Offset(-500, 0),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();
    expect(_viewerTopLeft(tester), Offset.zero);
    expect(find.text('2'), findsOneWidget);
  });
}
