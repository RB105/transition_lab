import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transition_lab/transition_lab.dart';

const _homeKey = ValueKey('home');
const _pageKey = ValueKey('page');
final double _eased = Curves.easeOutCubic.transform(0.5);

// The sheet's bottom sits 10 px above the bottom of an 800 x 600 screen.
const double _travel = 590;

Future<void> _pushHalfway(WidgetTester tester, {bool canPop = true}) async {
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(key: _homeKey, body: Text('home'))),
  );
  tester.state<NavigatorState>(find.byType(Navigator)).push(
        TopSheetRoute<void>(
          builder: (_) => PopScope(
            canPop: canPop,
            child: const Scaffold(key: _pageKey, body: Text('page')),
          ),
        ),
      );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250)); // half of 500 ms
}

void main() {
  testWidgets('the sheet slides down from the top', (tester) async {
    await _pushHalfway(tester);

    expect(tester.getTopLeft(find.byKey(_pageKey)).dy,
        moreOrLessEquals(-(1 - _eased) * _travel, epsilon: 0.01));
    expect(tester.getSize(find.byKey(_pageKey)).height, _travel);

    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(_pageKey)), Offset.zero);
  });

  testWidgets('the page underneath shrinks towards the bottom', (tester) async {
    await _pushHalfway(tester);
    await tester.pumpAndSettle();

    // Shrunk to 0.92 around its bottom edge, and dropped so it peeks out
    // just below the sheet.
    final Offset bottomLeft = tester.getBottomLeft(find.byKey(_homeKey));
    expect(bottomLeft.dy, moreOrLessEquals(600, epsilon: 0.01));
    expect(tester.getTopLeft(find.byKey(_homeKey)).dy,
        moreOrLessEquals(600 - 600 * 0.92, epsilon: 0.01));
  });

  testWidgets('pushing the sheet up closes it', (tester) async {
    await _pushHalfway(tester);
    await tester.pumpAndSettle();

    await tester.dragFrom(const Offset(400, 300), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.byKey(_pageKey), findsNothing);
  });

  testWidgets('a short push springs back', (tester) async {
    await _pushHalfway(tester);
    await tester.pumpAndSettle();

    await tester.timedDragFrom(
      const Offset(400, 300),
      const Offset(0, -60),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(_pageKey)), Offset.zero);
  });

  testWidgets('a push does nothing while PopScope blocks popping',
      (tester) async {
    await _pushHalfway(tester, canPop: false);
    await tester.pumpAndSettle();

    await tester.dragFrom(const Offset(400, 300), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(_pageKey)), Offset.zero);
  });
}
