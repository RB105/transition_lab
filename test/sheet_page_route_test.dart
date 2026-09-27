import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transition_lab/transition_lab.dart';

const _homeKey = ValueKey('home');
const _half = Duration(milliseconds: 250); // half of the default 500 ms
final _eased = Curves.easeOutCubic.transform(0.5);

// On the 800 x 600 test screen, without safe areas, the sheet's top rests
// 10 px down and it travels the other 590 px.
Widget _page(String name, {bool canPop = true}) => PopScope(
      canPop: canPop,
      child: Scaffold(
        key: ValueKey(name),
        body: ListView(
          children: [for (var i = 0; i < 40; i++) ListTile(title: Text('$i'))],
        ),
      ),
    );

Future<void> _pumpHome(WidgetTester tester) => tester.pumpWidget(
      const MaterialApp(home: Scaffold(key: _homeKey, body: Text('home'))),
    );

NavigatorState _navigator(WidgetTester tester) =>
    tester.state<NavigatorState>(find.byType(Navigator).first);

Offset _topLeft(WidgetTester tester, Key key) =>
    tester.getTopLeft(find.byKey(key));

// Where the top-left corner of a page with its top at [from] lands once
// covered by a sheet to extent [q].
Offset _covered(double q, {double from = 0}) {
  final double scale = 1 - 0.08 * q;
  return Offset(400 - 400 * scale, from * (1 - q));
}

void _expectOffset(Offset actual, Offset expected) {
  expect(actual.dx, moreOrLessEquals(expected.dx, epsilon: 0.01));
  expect(actual.dy, moreOrLessEquals(expected.dy, epsilon: 0.01));
}

void main() {
  testWidgets('slides up while the page underneath shrinks back',
      (tester) async {
    await _pumpHome(tester);
    _navigator(tester).push(SheetPageRoute<void>(builder: (_) => _page('a')));
    await tester.pump();
    await tester.pump(_half);

    _expectOffset(_topLeft(tester, const ValueKey('a')),
        Offset(0, 10 + 590 * (1 - _eased)));
    _expectOffset(_topLeft(tester, _homeKey), _covered(_eased));

    await tester.pumpAndSettle();
    _expectOffset(_topLeft(tester, const ValueKey('a')), const Offset(0, 10));
    expect(tester.getBottomRight(find.byKey(const ValueKey('a'))),
        const Offset(800, 600));
    // The page underneath still peeks out.
    _expectOffset(_topLeft(tester, _homeKey), _covered(1));

    _navigator(tester).pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('a')), findsNothing);
    expect(_topLeft(tester, _homeKey), Offset.zero);
  });

  testWidgets('a pull drags it down with the finger and closes it',
      (tester) async {
    await _pumpHome(tester);
    _navigator(tester).push(SheetPageRoute<void>(builder: (_) => _page('a')));
    await tester.pumpAndSettle();

    final TestGesture gesture = await tester.startGesture(
      const Offset(400, 300),
    );
    await gesture.moveBy(const Offset(0, 20));
    await gesture.moveBy(const Offset(0, 275));
    await tester.pump();
    // Pulled 295 px, half its travel.
    _expectOffset(_topLeft(tester, const ValueKey('a')), const Offset(0, 305));
    _expectOffset(_topLeft(tester, _homeKey), _covered(0.5));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('a')), findsNothing);
  });

  testWidgets('a short pull springs back', (tester) async {
    await _pumpHome(tester);
    _navigator(tester).push(SheetPageRoute<void>(builder: (_) => _page('a')));
    await tester.pumpAndSettle();

    await tester.timedDragFrom(
      const Offset(400, 300),
      const Offset(0, 80),
      const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();
    _expectOffset(_topLeft(tester, const ValueKey('a')), const Offset(0, 10));
  });

  testWidgets('scrolls its content back to the top before pulling',
      (tester) async {
    await _pumpHome(tester);
    _navigator(tester).push(SheetPageRoute<void>(builder: (_) => _page('a')));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.timedDragFrom(
      const Offset(400, 300),
      const Offset(0, 250),
      const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();
    _expectOffset(_topLeft(tester, const ValueKey('a')), const Offset(0, 10));
    expect(find.text('0'), findsOneWidget); // scrolled back instead
  });

  testWidgets('a pull does nothing while PopScope blocks popping',
      (tester) async {
    await _pumpHome(tester);
    _navigator(tester).push(
      SheetPageRoute<void>(builder: (_) => _page('a', canPop: false)),
    );
    await tester.pumpAndSettle();

    await tester.timedDragFrom(
      const Offset(400, 300),
      const Offset(0, 400),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();
    _expectOffset(_topLeft(tester, const ValueKey('a')), const Offset(0, 10));
  });

  testWidgets('a sheet over a sheet shrinks it back', (tester) async {
    await _pumpHome(tester);
    _navigator(tester).push(SheetPageRoute<void>(builder: (_) => _page('a')));
    await tester.pumpAndSettle();
    _navigator(tester).push(SheetPageRoute<void>(builder: (_) => _page('b')));
    await tester.pump();
    await tester.pump(_half);

    _expectOffset(
        _topLeft(tester, const ValueKey('a')), _covered(_eased, from: 10));
    _expectOffset(_topLeft(tester, _homeKey), _covered(1));

    await tester.pumpAndSettle();
    _expectOffset(_topLeft(tester, const ValueKey('a')), _covered(1, from: 10));
    _expectOffset(_topLeft(tester, const ValueKey('b')), const Offset(0, 10));
  });
}
