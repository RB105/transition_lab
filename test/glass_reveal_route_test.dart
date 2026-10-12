import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transition_lab/transition_lab.dart';

const _homeKey = ValueKey('home');
const _pageKey = ValueKey('page');
final double _eased = Curves.easeOutCubic.transform(0.5);

Future<void> _pushHalfway(WidgetTester tester, {Offset? center}) async {
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(key: _homeKey, body: Text('home'))),
  );
  tester.state<NavigatorState>(find.byType(Navigator)).push(
        GlassRevealRoute<void>(
          center: center,
          builder: (_) => const Scaffold(key: _pageKey, body: Text('page')),
        ),
      );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 325)); // half of 650 ms
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
  testWidgets('the ripple grows from the middle without a tap', (tester) async {
    await _pushHalfway(tester);

    // 500 px reach the corners from the middle of an 800 x 600 screen.
    final double radius = 500 * _eased;
    final Path path = _uncovered(tester);
    expect(path.contains(Offset(400, 300 - radius + 5)), isTrue);
    expect(path.contains(Offset(400, 300 - radius - 5)), isFalse);
  });

  testWidgets('it grows from the point it was given', (tester) async {
    await _pushHalfway(tester, center: const Offset(100, 500));

    final Path path = _uncovered(tester);
    expect(path.contains(const Offset(110, 495)), isTrue);
    expect(path.contains(const Offset(790, 20)), isFalse);
  });

  testWidgets('the glass rides the edge and is gone at rest', (tester) async {
    await _pushHalfway(tester);
    expect(find.byType(BackdropFilter), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(BackdropFilter), findsNothing);
    expect(tester.getSize(find.byKey(_pageKey)), const Size(800, 600));
  });

  testWidgets('edge swipe goes back', (tester) async {
    await _pushHalfway(tester);
    await tester.pumpAndSettle();

    await tester.dragFrom(const Offset(5, 300), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.byKey(_pageKey), findsNothing);
  });
}
