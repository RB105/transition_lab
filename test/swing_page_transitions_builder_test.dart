import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transition_lab/transition_lab.dart';

const _homeKey = ValueKey('home');
const _pageKey = ValueKey('page');
const _defaults = SwingPageTransitionsBuilder();
const _half = Duration(milliseconds: 275); // half of the default 550 ms
final _eased = Curves.easeOut.transform(0.5); // progress at half time

ThemeData _theme([SwingPageTransitionsBuilder builder = _defaults]) =>
    ThemeData(
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {for (final p in TargetPlatform.values) p: builder},
      ),
    );

class _Page extends StatefulWidget {
  const _Page({this.canPop = true});

  final bool canPop;
  static int initCount = 0;

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  @override
  void initState() {
    super.initState();
    _Page.initCount++;
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: widget.canPop,
        child: const Scaffold(key: _pageKey, body: Text('page')),
      );
}

Widget _home({bool canPop = true, Route<void> Function()? route}) => Scaffold(
      key: _homeKey,
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(
            route?.call() ??
                MaterialPageRoute<void>(builder: (_) => _Page(canPop: canPop)),
          ),
          child: const Text('open'),
        ),
      ),
    );

// The React Navigation cardStyleInterpolator, computed independently of
// Matrix4: where the incoming page's top-left corner lands on an 800x600
// screen at progress p.
Offset _enteringTopLeft(double p,
    [SwingPageTransitionsBuilder spec = _defaults]) {
  const w = 800.0, h = 600.0;
  final t = 1 - p;
  final s = 1 + (spec.enterScale - 1) * t;
  final theta = spec.enterAngle * t;
  final dx = -w / 2 * s, dy = -h / 2 * s;
  final x = dx * math.cos(theta) + spec.enterOffset * w * t;
  final z = -dx * math.sin(theta);
  final pw = 1 - z / spec.perspective;
  return Offset(x / pw + w / 2, dy / pw + h / 2);
}

Offset _coveredTopLeft(double q) {
  const w = 800.0, h = 600.0;
  final s = 1 - 0.1 * q;
  return Offset(-w / 2 * s - 0.3 * w * q + w / 2, -h / 2 * s + h / 2);
}

void _expectOffset(Offset actual, Offset expected) {
  expect(actual.dx, moreOrLessEquals(expected.dx, epsilon: 0.01));
  expect(actual.dy, moreOrLessEquals(expected.dy, epsilon: 0.01));
}

double _overlayOpacity(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find
        .ancestor(
          of: find.byKey(_homeKey),
          matching: find.byWidgetPredicate(
            (w) =>
                w is DecoratedBox &&
                w.position == DecorationPosition.foreground,
          ),
        )
        .first,
  );
  return (box.decoration as BoxDecoration).color?.a ?? 0;
}

void main() {
  setUp(() => _Page.initCount = 0);

  testWidgets('push follows the React Navigation interpolator', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: _theme(), home: _home()));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(_half);

    _expectOffset(
        tester.getTopLeft(find.byKey(_pageKey)), _enteringTopLeft(_eased));
    _expectOffset(
        tester.getTopLeft(find.byKey(_homeKey)), _coveredTopLeft(_eased));
    expect(
        _overlayOpacity(tester), moreOrLessEquals(0.5 * _eased, epsilon: 0.01));

    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(_pageKey)), Offset.zero);
    expect(tester.getBottomRight(find.byKey(_pageKey)), const Offset(800, 600));
    expect(find.byKey(_homeKey), findsNothing); // offstage once covered
  });

  testWidgets('lasts 550 ms and pop plays it backwards', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: _theme(), home: _home()));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 549));
    expect(tester.getTopLeft(find.byKey(_pageKey)).dx, greaterThan(0));
    await tester.pump(const Duration(milliseconds: 1));
    expect(tester.getTopLeft(find.byKey(_pageKey)), Offset.zero);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(_half);
    _expectOffset(
        tester.getTopLeft(find.byKey(_pageKey)), _enteringTopLeft(_eased));
    _expectOffset(
        tester.getTopLeft(find.byKey(_homeKey)), _coveredTopLeft(_eased));

    await tester.pumpAndSettle();
    expect(find.byKey(_pageKey), findsNothing);
    expect(tester.getTopLeft(find.byKey(_homeKey)), Offset.zero);
    expect(_overlayOpacity(tester), 0);
  });

  testWidgets('edge swipe pops linearly without rebuilding the page',
      (tester) async {
    await tester.pumpWidget(MaterialApp(theme: _theme(), home: _home()));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(_Page.initCount, 1);

    final gesture = await tester.startGesture(const Offset(5, 300));
    await gesture.moveBy(const Offset(400, 0)); // half the width
    await tester.pump();

    _expectOffset(
        tester.getTopLeft(find.byKey(_pageKey)), _enteringTopLeft(0.5));
    _expectOffset(
        tester.getTopLeft(find.byKey(_homeKey)), _coveredTopLeft(0.5));
    expect(_Page.initCount, 1);

    await gesture.moveBy(const Offset(100, 0));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byKey(_pageKey), findsNothing);
    expect(tester.getTopLeft(find.byKey(_homeKey)), Offset.zero);
  });

  testWidgets('edge swipe respects PopScope', (tester) async {
    await tester
        .pumpWidget(MaterialApp(theme: _theme(), home: _home(canPop: false)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.dragFrom(const Offset(5, 300), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(_pageKey)), Offset.zero);
  });

  testWidgets('swipeBackEnabled: false disables the edge swipe',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: _theme(const SwingPageTransitionsBuilder(swipeBackEnabled: false)),
      home: _home(),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.dragFrom(const Offset(5, 300), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(_pageKey)), Offset.zero);
  });

  testWidgets('a PageRouteBuilder root recedes through delegatedTransition',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: _theme(),
      onGenerateRoute: (settings) => PageRouteBuilder<void>(
        settings: settings,
        pageBuilder: (context, animation, secondaryAnimation) => _home(),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(_half);

    _expectOffset(
        tester.getTopLeft(find.byKey(_homeKey)), _coveredTopLeft(_eased));
    expect(
        _overlayOpacity(tester), moreOrLessEquals(0.5 * _eased, epsilon: 0.01));
  });

  testWidgets('SwingPageRoute brings its own transition, whatever the theme',
      (tester) async {
    const spec = SwingPageTransitionsBuilder(
      duration: Duration(milliseconds: 300),
      enterOffset: 1,
      enterAngle: 0,
      enterScale: 1,
    );
    await tester.pumpWidget(MaterialApp(
      home: _home(
          route: () => SwingPageRoute<void>(
              transitions: spec, builder: (_) => const _Page())),
    ));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    // A plain slide with these settings, and the default-themed page below
    // still recedes.
    _expectOffset(
        tester.getTopLeft(find.byKey(_pageKey)), Offset(800 * (1 - _eased), 0));
    _expectOffset(
        tester.getTopLeft(find.byKey(_homeKey)), _coveredTopLeft(_eased));

    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.getTopLeft(find.byKey(_pageKey)), Offset.zero);
  });

  testWidgets('mirrors in right-to-left layouts', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: _theme(),
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: _home(),
    ));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(_half);

    final ltrPage = _enteringTopLeft(_eased);
    final ltrHome = _coveredTopLeft(_eased);
    _expectOffset(tester.getTopRight(find.byKey(_pageKey)),
        Offset(800 - ltrPage.dx, ltrPage.dy));
    _expectOffset(tester.getTopRight(find.byKey(_homeKey)),
        Offset(800 - ltrHome.dx, ltrHome.dy));
  });

  test('has value equality', () {
    // ignore: prefer_const_constructors
    expect(SwingPageTransitionsBuilder(), _defaults);
    // ignore: prefer_const_constructors
    expect(SwingPageTransitionsBuilder().hashCode, _defaults.hashCode);
    expect(
        const SwingPageTransitionsBuilder(enterScale: 1.2), isNot(_defaults));
  });
}
