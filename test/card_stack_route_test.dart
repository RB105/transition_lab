import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transition_lab/transition_lab.dart';

const _homeKey = ValueKey('home');
const _pageKey = ValueKey('page');
final double _eased = Curves.easeOutCubic.transform(0.5);

Future<void> _pushHalfway(WidgetTester tester, {bool canPop = true}) async {
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(key: _homeKey, body: Text('home'))),
  );
  tester.state<NavigatorState>(find.byType(Navigator)).push(
        CardStackRoute<void>(
          builder: (_) => PopScope(
            canPop: canPop,
            child: const Scaffold(key: _pageKey, body: Text('page')),
          ),
        ),
      );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 210)); // half of 420 ms
}

void main() {
  testWidgets('the card flies in from the trailing edge', (tester) async {
    await _pushHalfway(tester);

    final double away = 1 - _eased;
    final Offset center = tester.getCenter(find.byKey(_pageKey));
    expect(center.dx, moreOrLessEquals(400 + 800 * 1.15 * away, epsilon: 0.01));
    expect(center.dy, moreOrLessEquals(300 + 20 * away, epsilon: 0.01));

    await tester.pumpAndSettle();
    expect(tester.getCenter(find.byKey(_pageKey)), const Offset(400, 300));
  });

  testWidgets('the card underneath sits back', (tester) async {
    await _pushHalfway(tester);

    final double scale = 1 - 0.06 * _eased;
    final Offset topLeft = tester.getTopLeft(find.byKey(_homeKey));
    expect(topLeft.dx, moreOrLessEquals(400 - 400 * scale, epsilon: 0.01));
    expect(topLeft.dy, moreOrLessEquals(300 - 300 * scale, epsilon: 0.01));
  });

  testWidgets('throwing the card away pops it', (tester) async {
    await _pushHalfway(tester);
    await tester.pumpAndSettle();

    await tester.dragFrom(const Offset(400, 300), const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(find.byKey(_pageKey), findsNothing);
  });

  testWidgets('a short drag settles the card back', (tester) async {
    await _pushHalfway(tester);
    await tester.pumpAndSettle();

    await tester.timedDragFrom(
      const Offset(400, 300),
      const Offset(80, 0),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();
    expect(tester.getCenter(find.byKey(_pageKey)), const Offset(400, 300));
  });

  testWidgets('a drag does nothing while PopScope blocks popping',
      (tester) async {
    await _pushHalfway(tester, canPop: false);
    await tester.pumpAndSettle();

    await tester.dragFrom(const Offset(400, 300), const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(tester.getCenter(find.byKey(_pageKey)), const Offset(400, 300));
  });
}
