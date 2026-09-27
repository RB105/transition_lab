import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transition_lab/transition_lab.dart';

const _homeKey = ValueKey('home');
const _half = Duration(milliseconds: 325); // half of the default 650 ms

Widget _page(String name) => Scaffold(key: ValueKey(name), body: Text(name));

Widget _app({TextDirection direction = TextDirection.ltr}) => MaterialApp(
      builder: (context, child) =>
          Directionality(textDirection: direction, child: child!),
      home: const Scaffold(key: _homeKey, body: Text('home')),
    );

NavigatorState _navigator(WidgetTester tester) =>
    tester.state<NavigatorState>(find.byType(Navigator));

Offset _topLeft(WidgetTester tester, String name) =>
    tester.getTopLeft(find.byKey(ValueKey(name)));

Offset _topRight(WidgetTester tester, String name) =>
    tester.getTopRight(find.byKey(ValueKey(name)));

void _expectOffset(Offset actual, Offset expected) {
  expect(actual.dx, moreOrLessEquals(expected.dx, epsilon: 0.01));
  expect(actual.dy, moreOrLessEquals(expected.dy, epsilon: 0.01));
}

void main() {
  testWidgets('the pages turn around their shared edge', (tester) async {
    await tester.pumpWidget(_app());
    _navigator(tester).push(CubePageRoute<void>(builder: (_) => _page('a')));
    await tester.pump();
    await tester.pump(_half);

    // Halfway, both faces meet in the middle of the 800 px wide screen.
    _expectOffset(_topLeft(tester, 'a'), const Offset(400, 0));
    _expectOffset(
        tester.getTopRight(find.byKey(_homeKey)), const Offset(400, 0));

    await tester.pumpAndSettle();
    expect(_topLeft(tester, 'a'), Offset.zero);
    expect(find.byKey(_homeKey), findsNothing);
  });

  testWidgets('backward comes in from the left', (tester) async {
    await tester.pumpWidget(_app());
    _navigator(tester).push(
      CubePageRoute<void>(backward: true, builder: (_) => _page('a')),
    );
    await tester.pump();
    await tester.pump(_half);

    _expectOffset(_topRight(tester, 'a'), const Offset(400, 0));
    _expectOffset(
        tester.getTopLeft(find.byKey(_homeKey)), const Offset(400, 0));
  });

  testWidgets('comes in from the left in right-to-left layouts',
      (tester) async {
    await tester.pumpWidget(_app(direction: TextDirection.rtl));
    _navigator(tester).push(CubePageRoute<void>(builder: (_) => _page('a')));
    await tester.pump();
    await tester.pump(_half);

    _expectOffset(_topRight(tester, 'a'), const Offset(400, 0));
    _expectOffset(
        tester.getTopLeft(find.byKey(_homeKey)), const Offset(400, 0));
  });

  testWidgets('a replaced page turns the way the new one comes in',
      (tester) async {
    await tester.pumpWidget(_app());
    _navigator(tester).push(CubePageRoute<void>(builder: (_) => _page('a')));
    await tester.pumpAndSettle();

    _navigator(tester).pushReplacement(
      CubePageRoute<void>(builder: (_) => _page('b')),
    );
    await tester.pump();
    await tester.pump(_half);
    _expectOffset(_topRight(tester, 'a'), const Offset(400, 0));
    _expectOffset(_topLeft(tester, 'b'), const Offset(400, 0));
    await tester.pumpAndSettle();

    _navigator(tester).pushReplacement(
      CubePageRoute<void>(backward: true, builder: (_) => _page('c')),
    );
    await tester.pump();
    await tester.pump(_half);
    _expectOffset(_topLeft(tester, 'b'), const Offset(400, 0));
    _expectOffset(_topRight(tester, 'c'), const Offset(400, 0));
  });

  testWidgets('edge swipe turns the cube back with the finger', (tester) async {
    await tester.pumpWidget(_app());
    _navigator(tester).push(CubePageRoute<void>(builder: (_) => _page('a')));
    await tester.pumpAndSettle();

    final TestGesture gesture = await tester.startGesture(
      const Offset(5, 300),
    );
    await gesture.moveBy(const Offset(400, 0)); // half the width
    await tester.pump();
    _expectOffset(_topLeft(tester, 'a'), const Offset(400, 0));

    await gesture.moveBy(const Offset(100, 0));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('a')), findsNothing);
    expect(tester.getTopLeft(find.byKey(_homeKey)), Offset.zero);
  });

  testWidgets('a backward page has no edge swipe', (tester) async {
    await tester.pumpWidget(_app());
    _navigator(tester).push(
      CubePageRoute<void>(backward: true, builder: (_) => _page('a')),
    );
    await tester.pumpAndSettle();

    await tester.dragFrom(const Offset(5, 300), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(_topLeft(tester, 'a'), Offset.zero);
  });
}
