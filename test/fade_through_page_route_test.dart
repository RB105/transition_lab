import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transition_lab/transition_lab.dart';

const _homeKey = ValueKey('home');
const _pageKey = ValueKey('page');

Future<void> _pushHalfway(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(key: _homeKey, body: Text('home'))),
  );
  tester.state<NavigatorState>(find.byType(Navigator)).push(
        FadeThroughPageRoute<void>(
          builder: (_) => const Scaffold(key: _pageKey, body: Text('page')),
        ),
      );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 150)); // half of 300 ms
}

Offset _scaled(double scale) => Offset(400 - 400 * scale, 300 - 300 * scale);

double _opacityOf(WidgetTester tester, Key key) => tester
    .widget<Opacity>(
      find.ancestor(of: find.byKey(key), matching: find.byType(Opacity)).first,
    )
    .opacity;

void main() {
  testWidgets('the new page grows in as the old one fades out', (tester) async {
    await _pushHalfway(tester);

    final double grown =
        1 - 0.08 * (1 - Curves.easeInOutCubicEmphasized.transform(0.5));
    final Offset expected = _scaled(grown);
    final Offset topLeft = tester.getTopLeft(find.byKey(_pageKey));
    expect(topLeft.dx, moreOrLessEquals(expected.dx, epsilon: 0.01));
    expect(topLeft.dy, moreOrLessEquals(expected.dy, epsilon: 0.01));

    // The old page has already faded out; the new one is still fading in.
    expect(_opacityOf(tester, _homeKey), 0);
    expect(_opacityOf(tester, _pageKey),
        moreOrLessEquals(1 - 0.5 / 0.7, epsilon: 0.01));

    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(_pageKey)), Offset.zero);
  });

  testWidgets('the page does not move sideways', (tester) async {
    await _pushHalfway(tester);
    expect(tester.getCenter(find.byKey(_pageKey)), const Offset(400, 300));
  });

  testWidgets('edge swipe goes back', (tester) async {
    await _pushHalfway(tester);
    await tester.pumpAndSettle();

    await tester.dragFrom(const Offset(5, 300), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.byKey(_pageKey), findsNothing);
  });
}
