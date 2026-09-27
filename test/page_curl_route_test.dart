import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transition_lab/transition_lab.dart';

const _pageKey = ValueKey('page');

Future<void> _open(WidgetTester tester, {bool settle = true}) async {
  await tester.pumpWidget(const MaterialApp(home: Text('home')));
  tester.state<NavigatorState>(find.byType(Navigator)).push(
        PageCurlRoute<void>(
          builder: (_) => const Scaffold(key: _pageKey, body: Text('page')),
        ),
      );
  await tester.pump();
  if (settle) await tester.pumpAndSettle();
}

bool _curling(WidgetTester tester) => tester
    .widget<SnapshotWidget>(
      find.ancestor(
          of: find.byKey(_pageKey), matching: find.byType(SnapshotWidget)),
    )
    .controller
    .allowSnapshotting;

double _laid(WidgetTester tester) =>
    ModalRoute.of(tester.element(find.byKey(_pageKey)))!.animation!.value;

void main() {
  testWidgets('curls only while turning', (tester) async {
    await _open(tester, settle: false);
    await tester.pump(const Duration(milliseconds: 350));
    expect(_curling(tester), isTrue);

    await tester.pumpAndSettle();
    expect(_curling(tester), isFalse);
    expect(tester.getTopLeft(find.byKey(_pageKey)), Offset.zero);
  });

  testWidgets('the corner follows a drag from the leading edge',
      (tester) async {
    await _open(tester);

    final TestGesture gesture = await tester.startGesture(
      const Offset(10, 500),
    );
    await gesture.moveBy(const Offset(40, 0)); // past the touch slop
    await tester.pump();
    final double before = _laid(tester);
    await gesture.moveBy(const Offset(200, 0));
    await tester.pump();
    // The corner moves twice as far as the page turns: 200 px of 2 x 800.
    expect(_laid(tester), moreOrLessEquals(before - 0.125, epsilon: 1e-6));
    expect(_curling(tester), isTrue);

    await gesture.moveBy(const Offset(200, 0));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byKey(_pageKey), findsNothing);
  });

  testWidgets('a short drag lays the page back down', (tester) async {
    await _open(tester);

    await tester.timedDragFrom(
      const Offset(10, 500),
      const Offset(150, 0),
      const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();
    expect(_laid(tester), 1);
    expect(_curling(tester), isFalse);
  });

  testWidgets('a drag away from the edge does not turn the page',
      (tester) async {
    await _open(tester);

    await tester.dragFrom(const Offset(300, 300), const Offset(450, 0));
    await tester.pumpAndSettle();
    expect(_laid(tester), 1);
  });
}
