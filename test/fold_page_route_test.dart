import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transition_lab/transition_lab.dart';

const _homeKey = ValueKey('home');
const _pageKey = ValueKey('page');
final double _eased = Curves.easeOutCubic.transform(0.5);

Future<void> _pushHalfway(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(key: _homeKey, body: Text('home'))),
  );
  tester.state<NavigatorState>(find.byType(Navigator)).push(
        FoldPageRoute<void>(
          builder: (_) => const Scaffold(key: _pageKey, body: Text('page')),
        ),
      );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300)); // half of 600 ms
}

bool _snapshotting(WidgetTester tester) => tester
    .widget<SnapshotWidget>(
      find.ancestor(
          of: find.byKey(_pageKey), matching: find.byType(SnapshotWidget)),
    )
    .controller
    .allowSnapshotting;

void main() {
  testWidgets('the page is drawn from a snapshot while it folds open',
      (tester) async {
    await _pushHalfway(tester);
    expect(_snapshotting(tester), isTrue);

    // Once it lies flat the live page takes over again.
    await tester.pumpAndSettle();
    expect(_snapshotting(tester), isFalse);
    expect(tester.getTopLeft(find.byKey(_pageKey)), Offset.zero);
    expect(tester.getSize(find.byKey(_pageKey)), const Size(800, 600));
  });

  testWidgets('the page underneath sinks back', (tester) async {
    await _pushHalfway(tester);

    final double scale = 1 - 0.06 * _eased;
    final Offset topLeft = tester.getTopLeft(find.byKey(_homeKey));
    expect(topLeft.dx, moreOrLessEquals(400 - 400 * scale, epsilon: 0.01));
    expect(topLeft.dy, moreOrLessEquals(300 - 300 * scale, epsilon: 0.01));

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(_homeKey)), Offset.zero);
  });

  testWidgets('edge swipe goes back', (tester) async {
    await _pushHalfway(tester);
    await tester.pumpAndSettle();

    await tester.dragFrom(const Offset(5, 300), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.byKey(_pageKey), findsNothing);
  });
}
