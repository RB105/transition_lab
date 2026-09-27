import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transition_lab/transition_lab.dart';

const _homeKey = ValueKey('home');
const _pageKey = ValueKey('page');
final _eased = Curves.easeOutCubic.transform(0.5);

Future<void> _pushHalfway(WidgetTester tester, {double blurSigma = 12}) async {
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(key: _homeKey, body: Text('home'))),
  );
  tester.state<NavigatorState>(find.byType(Navigator)).push(
        DepthPageRoute<void>(
          blurSigma: blurSigma,
          builder: (_) => const Scaffold(key: _pageKey, body: Text('page')),
        ),
      );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 225)); // half of 450 ms
}

// The top-left corner of an 800 x 600 page scaled by [scale] around its
// middle.
Offset _scaled(double scale) => Offset(400 - 400 * scale, 300 - 300 * scale);

void _expectOffset(Offset actual, Offset expected) {
  expect(actual.dx, moreOrLessEquals(expected.dx, epsilon: 0.01));
  expect(actual.dy, moreOrLessEquals(expected.dy, epsilon: 0.01));
}

ImageFiltered _blur(WidgetTester tester) => tester.widget<ImageFiltered>(
      find.ancestor(
          of: find.byKey(_homeKey), matching: find.byType(ImageFiltered)),
    );

void main() {
  testWidgets('the page underneath recedes into a blur', (tester) async {
    await _pushHalfway(tester);

    _expectOffset(
        tester.getTopLeft(find.byKey(_homeKey)), _scaled(1 - 0.06 * _eased));
    _expectOffset(
        tester.getTopLeft(find.byKey(_pageKey)), _scaled(1.08 - 0.08 * _eased));
    expect(_blur(tester).enabled, isTrue);

    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(_pageKey)), Offset.zero);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(_homeKey)), Offset.zero);
    expect(
      find.ancestor(
          of: find.byKey(_homeKey), matching: find.byType(ImageFiltered)),
      findsNothing,
    );
  });

  testWidgets('a zero blurSigma leaves the blur out', (tester) async {
    await _pushHalfway(tester, blurSigma: 0);
    expect(_blur(tester).enabled, isFalse);
  });

  testWidgets('edge swipe goes back', (tester) async {
    await _pushHalfway(tester);
    await tester.pumpAndSettle();

    await tester.dragFrom(const Offset(5, 300), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.byKey(_pageKey), findsNothing);
  });
}
