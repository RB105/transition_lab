import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transition_lab/transition_lab.dart';

const _pageKey = ValueKey('page');

// The pill is 126 x 37, 11 px below the top of the 800 x 600 screen.
const Rect _pill = Rect.fromLTWH(337, 11, 126, 37);

Future<void> _push(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: Text('home'))),
  );
  tester.state<NavigatorState>(find.byType(Navigator)).push(
        IslandPageRoute<void>(
          builder: (_) => const Scaffold(key: _pageKey, body: Text('page')),
        ),
      );
  await tester.pump();
  await tester.pump(); // the HeroController keeps it offstage for a frame
}

// The page hangs below the top of the window, centred on it.
Offset _pageTopLeft(double p) {
  final Rect window = Rect.lerp(_pill, const Rect.fromLTWH(0, 0, 800, 600), p)!;
  return Offset(window.center.dx - 400, window.top);
}

void _expectTopLeft(WidgetTester tester, Offset expected) {
  final Offset actual = tester.getTopLeft(find.byKey(_pageKey));
  expect(actual.dx, moreOrLessEquals(expected.dx, epsilon: 0.01));
  expect(actual.dy, moreOrLessEquals(expected.dy, epsilon: 0.01));
}

void main() {
  testWidgets('the page stretches out of the pill at the top', (tester) async {
    await _push(tester);

    expect(tester.getSize(find.byKey(_pageKey)), const Size(800, 600));
    _expectTopLeft(tester, _pageTopLeft(0));

    await tester.pump(const Duration(milliseconds: 260)); // half of 520 ms
    _expectTopLeft(tester, _pageTopLeft(Curves.easeOutCubic.transform(0.5)));

    await tester.pumpAndSettle();
    _expectTopLeft(tester, Offset.zero);
  });

  testWidgets('pulling it down closes it', (tester) async {
    await _push(tester);
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
