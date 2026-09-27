import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transition_lab/transition_lab.dart';

const _homeKey = ValueKey('home');
const _pageKey = ValueKey('page');

Widget _app({TextDirection direction = TextDirection.ltr}) => MaterialApp(
      builder: (context, child) =>
          Directionality(textDirection: direction, child: child!),
      home: const Scaffold(key: _homeKey, body: Text('home')),
    );

void _push(WidgetTester tester) =>
    tester.state<NavigatorState>(find.byType(Navigator)).push(
          FlipPageRoute<void>(
            builder: (_) => const Scaffold(key: _pageKey, body: Text('page')),
          ),
        );

// Whether the card face holding [key] is shown. Pages have other Opacity
// widgets of their own, so this looks only under the face.
bool _shown(WidgetTester tester, Key key) {
  final Finder face = find
      .ancestor(
        of: find.byKey(key),
        matching: find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_CardFace',
        ),
      )
      .first;
  return tester
          .widget<Opacity>(
            find.descendant(of: face, matching: find.byType(Opacity)).first,
          )
          .opacity ==
      1;
}

void main() {
  testWidgets('shows the front, then the back, of a turning card',
      (tester) async {
    await tester.pumpWidget(_app());
    _push(tester);
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 150)); // a quarter
    expect(_shown(tester, _homeKey), isTrue);
    expect(_shown(tester, _pageKey), isFalse);

    await tester.pump(const Duration(milliseconds: 300)); // three quarters
    expect(_shown(tester, _homeKey), isFalse);
    expect(_shown(tester, _pageKey), isTrue);
    // Turning in, its trailing edge is nearer and so taller.
    expect(tester.getTopRight(find.byKey(_pageKey)).dy,
        lessThan(tester.getTopLeft(find.byKey(_pageKey)).dy));

    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(_pageKey)), Offset.zero);
    expect(tester.getBottomRight(find.byKey(_pageKey)), const Offset(800, 600));
  });

  testWidgets('turns the other way in right-to-left layouts', (tester) async {
    await tester.pumpWidget(_app(direction: TextDirection.rtl));
    _push(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    expect(tester.getTopLeft(find.byKey(_pageKey)).dy,
        lessThan(tester.getTopRight(find.byKey(_pageKey)).dy));
  });

  testWidgets('edge swipe turns the card back', (tester) async {
    await tester.pumpWidget(_app());
    _push(tester);
    await tester.pumpAndSettle();

    final TestGesture gesture = await tester.startGesture(
      const Offset(5, 300),
    );
    await gesture.moveBy(const Offset(200, 0)); // a quarter of the width
    await tester.pump();
    expect(_shown(tester, _pageKey), isTrue);
    expect(_shown(tester, _homeKey), isFalse);

    await gesture.moveBy(const Offset(400, 0));
    await tester.pump();
    expect(_shown(tester, _pageKey), isFalse);
    expect(_shown(tester, _homeKey), isTrue);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byKey(_pageKey), findsNothing);
    expect(tester.getTopLeft(find.byKey(_homeKey)), Offset.zero);
  });
}
