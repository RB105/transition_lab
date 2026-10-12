import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transition_lab/transition_lab.dart';

const _homeKey = ValueKey('home');
const _pageKey = ValueKey('page');

// How far the pages still have to travel at the halfway point.
final double _moved = 1 - Curves.easeInOutCubicEmphasized.transform(0.5);

Future<void> _pushHalfway(
  WidgetTester tester, {
  SharedAxis axis = SharedAxis.horizontal,
}) async {
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(key: _homeKey, body: Text('home'))),
  );
  tester.state<NavigatorState>(find.byType(Navigator)).push(
        SharedAxisPageRoute<void>(
          axis: axis,
          builder: (_) => const Scaffold(key: _pageKey, body: Text('page')),
        ),
      );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 150)); // half of 300 ms
}

// The top-left corner of an 800 x 600 page scaled by [scale] around its
// middle.
Offset _scaled(double scale) => Offset(400 - 400 * scale, 300 - 300 * scale);

double _opacityOf(WidgetTester tester, Key key) => tester
    .widget<Opacity>(
      find.ancestor(of: find.byKey(key), matching: find.byType(Opacity)).first,
    )
    .opacity;

void main() {
  testWidgets('the pages travel sideways together', (tester) async {
    await _pushHalfway(tester);

    expect(tester.getTopLeft(find.byKey(_pageKey)).dx,
        moreOrLessEquals(30 * _moved, epsilon: 0.01));
    // The page underneath goes on in the direction the new one came from.
    expect(tester.getTopLeft(find.byKey(_homeKey)).dx,
        moreOrLessEquals(-30 * _moved, epsilon: 0.01));

    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(_pageKey)), Offset.zero);
  });

  testWidgets('they cross-fade without overlapping', (tester) async {
    await _pushHalfway(tester);

    // The new page fades in over the last 70%, the old one out over the
    // first 30%, so at the halfway point only the new one is showing.
    expect(_opacityOf(tester, _pageKey),
        moreOrLessEquals(1 - 0.5 / 0.7, epsilon: 0.01));
    expect(_opacityOf(tester, _homeKey), 0);
  });

  testWidgets('the vertical axis moves them up and down', (tester) async {
    await _pushHalfway(tester, axis: SharedAxis.vertical);

    final Offset topLeft = tester.getTopLeft(find.byKey(_pageKey));
    expect(topLeft.dx, 0);
    expect(topLeft.dy, moreOrLessEquals(30 * _moved, epsilon: 0.01));
  });

  testWidgets('the scaled axis grows the new page in', (tester) async {
    await _pushHalfway(tester, axis: SharedAxis.scaled);

    final Offset expected = _scaled(1 - 0.2 * _moved);
    final Offset topLeft = tester.getTopLeft(find.byKey(_pageKey));
    expect(topLeft.dx, moreOrLessEquals(expected.dx, epsilon: 0.01));
    expect(topLeft.dy, moreOrLessEquals(expected.dy, epsilon: 0.01));
  });

  testWidgets('edge swipe goes back', (tester) async {
    await _pushHalfway(tester);
    await tester.pumpAndSettle();

    await tester.dragFrom(const Offset(5, 300), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.byKey(_pageKey), findsNothing);
  });
}
