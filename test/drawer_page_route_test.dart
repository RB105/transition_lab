import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transition_lab/transition_lab.dart';

const _homeKey = ValueKey('home');
const _pageKey = ValueKey('page');
final double _eased = Curves.easeOutCubic.transform(0.5);

// 78% of an 800 px wide screen.
const double _panel = 624;

Future<void> _pushHalfway(WidgetTester tester, {bool canPop = true}) async {
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(key: _homeKey, body: Text('home'))),
  );
  tester.state<NavigatorState>(find.byType(Navigator)).push(
        DrawerPageRoute<void>(
          builder: (_) => PopScope(
            canPop: canPop,
            child: const Scaffold(key: _pageKey, body: Text('page')),
          ),
        ),
      );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 190)); // half of 380 ms
}

void main() {
  testWidgets('the panel slides in from the leading edge', (tester) async {
    await _pushHalfway(tester);

    expect(tester.getSize(find.byKey(_pageKey)).width, _panel);
    expect(tester.getTopLeft(find.byKey(_pageKey)).dx,
        moreOrLessEquals(-_panel * (1 - _eased), epsilon: 0.01));

    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(_pageKey)), Offset.zero);
  });

  testWidgets('the page underneath slides the other way and shrinks',
      (tester) async {
    await _pushHalfway(tester);
    await tester.pumpAndSettle();

    // Moved a tenth of the screen width and scaled to 0.94 around its middle.
    final Offset topLeft = tester.getTopLeft(find.byKey(_homeKey));
    expect(topLeft.dx, moreOrLessEquals(400 - 400 * 0.94 + 80, epsilon: 0.01));
    expect(topLeft.dy, moreOrLessEquals(300 - 300 * 0.94, epsilon: 0.01));
  });

  testWidgets('a tap on the scrim closes the panel', (tester) async {
    await _pushHalfway(tester);
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(750, 300));
    await tester.pumpAndSettle();
    expect(find.byKey(_pageKey), findsNothing);
  });

  testWidgets('dragging the panel back closes it', (tester) async {
    await _pushHalfway(tester);
    await tester.pumpAndSettle();

    await tester.dragFrom(const Offset(300, 300), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(find.byKey(_pageKey), findsNothing);
  });

  testWidgets('a short drag settles the panel back', (tester) async {
    await _pushHalfway(tester);
    await tester.pumpAndSettle();

    await tester.timedDragFrom(
      const Offset(300, 300),
      const Offset(-60, 0),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(_pageKey)), Offset.zero);
  });

  testWidgets('neither closes it while PopScope blocks popping',
      (tester) async {
    await _pushHalfway(tester, canPop: false);
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(750, 300));
    await tester.dragFrom(const Offset(300, 300), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(_pageKey)), Offset.zero);
  });
}
