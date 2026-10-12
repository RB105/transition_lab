import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transition_lab/transition_lab.dart';

const _homeKey = ValueKey('home');
const _pageKey = ValueKey('page');

Future<void> _pushHalfway(WidgetTester tester, WipeStyle style) async {
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(key: _homeKey, body: Text('home'))),
  );
  tester.state<NavigatorState>(find.byType(Navigator)).push(
        WipePageRoute<void>(
          style: style,
          builder: (_) => const Scaffold(key: _pageKey, body: Text('page')),
        ),
      );
  await tester.pump();
  // Half of 450 ms: easeInOutCubic is a little past half there.
  await tester.pump(const Duration(milliseconds: 225));
}

// The part of the screen the new page shows through.
Path _uncovered(WidgetTester tester) {
  final ClipPath clip = tester.widget<ClipPath>(
    find
        .ancestor(of: find.byKey(_pageKey), matching: find.byType(ClipPath))
        .first,
  );
  return clip.clipper!.getClip(const Size(800, 600));
}

void main() {
  testWidgets('the shutter opens every slat at once', (tester) async {
    await _pushHalfway(tester, WipeStyle.shutter);

    final Path path = _uncovered(tester);
    // Five slats of 120 px, each open a little over half from its own top.
    expect(path.contains(const Offset(400, 30)), isTrue);
    expect(path.contains(const Offset(400, 100)), isFalse);
    expect(path.contains(const Offset(400, 150)), isTrue);
    expect(path.contains(const Offset(400, 220)), isFalse);
  });

  testWidgets('the diagonal sweeps from the leading top corner',
      (tester) async {
    await _pushHalfway(tester, WipeStyle.diagonal);

    final Path path = _uncovered(tester);
    // The edge is the line x + y = k, a little past the middle of the
    // 1400 px it travels.
    expect(path.contains(const Offset(100, 100)), isTrue);
    expect(path.contains(const Offset(600, 500)), isFalse);
  });

  testWidgets('the clock sweeps around from the top', (tester) async {
    await _pushHalfway(tester, WipeStyle.clock);

    final Path path = _uncovered(tester);
    // Halfway around is the trailing half of the screen.
    expect(path.contains(const Offset(600, 300)), isTrue);
    expect(path.contains(const Offset(200, 300)), isFalse);
  });

  testWidgets('the iris opens in the middle', (tester) async {
    await _pushHalfway(tester, WipeStyle.iris);

    final Path path = _uncovered(tester);
    // A circle of a little over half of the 500 px that reach the corners.
    expect(path.contains(const Offset(400, 100)), isTrue);
    expect(path.contains(const Offset(400, 20)), isFalse);
  });

  testWidgets('every style uncovers the whole page at rest', (tester) async {
    for (final WipeStyle style in WipeStyle.values) {
      await _pushHalfway(tester, style);
      await tester.pumpAndSettle();

      final Path path = _uncovered(tester);
      expect(path.contains(const Offset(1, 1)), isTrue, reason: '$style');
      expect(path.contains(const Offset(799, 599)), isTrue, reason: '$style');

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('edge swipe goes back', (tester) async {
    await _pushHalfway(tester, WipeStyle.diagonal);
    await tester.pumpAndSettle();

    await tester.dragFrom(const Offset(5, 300), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.byKey(_pageKey), findsNothing);
  });
}
