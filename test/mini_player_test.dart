import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transition_lab/transition_lab.dart';

const _playerKey = ValueKey('player');

class _Player extends StatefulWidget {
  const _Player();

  static int initCount = 0;

  @override
  State<_Player> createState() => _PlayerState();
}

class _PlayerState extends State<_Player> {
  @override
  void initState() {
    super.initState();
    _Player.initCount++;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        key: _playerKey,
        body: ListView(
          children: [for (var i = 0; i < 40; i++) ListTile(title: Text('$i'))],
        ),
      );
}

// On the 800 x 600 test screen the 64 px bar rests at y = 536.
Widget _app() => MaterialApp(
      builder: (context, child) => MiniPlayer(child: child!),
      home: Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: [
              TextButton(
                onPressed: () => MiniPlayer.of(context).open(
                  builder: (_) => const _Player(),
                  barBuilder: (_) => const Text('bar'),
                ),
                child: const Text('play'),
              ),
              Text('space ${MiniPlayer.barSpaceOf(context)}'),
            ],
          ),
        ),
      ),
    );

MiniPlayerState _state(WidgetTester tester) =>
    tester.state<MiniPlayerState>(find.byType(MiniPlayer));

Future<void> _openPlayer(WidgetTester tester) async {
  await tester.pumpWidget(_app());
  await tester.tap(find.text('play'));
  await tester.pumpAndSettle();
}

Future<void> _minimize(WidgetTester tester) async {
  await tester.timedDragFrom(
    const Offset(400, 200),
    const Offset(0, 350),
    const Duration(milliseconds: 600),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => _Player.initCount = 0);

  testWidgets('opens full screen', (tester) async {
    await tester.pumpWidget(_app());
    expect(find.text('space 0.0'), findsOneWidget);

    await tester.tap(find.text('play'));
    await tester.pumpAndSettle();
    expect(_state(tester).isOpen, isTrue);
    expect(_state(tester).expansion.value, 1);
    expect(tester.getTopLeft(find.byKey(_playerKey)), Offset.zero);
    expect(find.text('space 64.0'), findsOneWidget);
  });

  testWidgets('a pull down shrinks it into the bar with the finger',
      (tester) async {
    await _openPlayer(tester);

    final TestGesture gesture = await tester.startGesture(
      const Offset(400, 200),
    );
    await gesture.moveBy(const Offset(0, 20));
    await gesture.moveBy(const Offset(0, 248));
    await tester.pump();
    // Pulled 268 px, half the 536 px between full screen and the bar.
    expect(_state(tester).expansion.value, moreOrLessEquals(0.5));
    expect(tester.getTopLeft(find.byKey(_playerKey)).dy, moreOrLessEquals(268));

    await gesture.moveBy(const Offset(0, 50));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(_state(tester).expansion.value, 0);
    expect(tester.getTopLeft(find.text('bar')).dy, 536);
    // The page stays alive while minimized.
    expect(find.byKey(_playerKey), findsOneWidget);
  });

  testWidgets('the pages underneath take taps while it is minimized',
      (tester) async {
    await _openPlayer(tester);
    await _minimize(tester);

    await tester.tap(find.text('play'));
    await tester.pumpAndSettle();
    expect(_state(tester).expansion.value, 1);
  });

  testWidgets('tapping the bar expands it with the same page', (tester) async {
    await _openPlayer(tester);
    await _minimize(tester);

    await tester.tap(find.text('bar'));
    await tester.pumpAndSettle();
    expect(_state(tester).expansion.value, 1);
    expect(tester.getTopLeft(find.byKey(_playerKey)), Offset.zero);
    expect(_Player.initCount, 1);
  });

  testWidgets('dragging the bar up expands it', (tester) async {
    await _openPlayer(tester);
    await _minimize(tester);

    await tester.timedDragFrom(
      const Offset(400, 560),
      const Offset(0, -400),
      const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();
    expect(_state(tester).expansion.value, 1);
  });

  testWidgets('dragging the bar down closes the player', (tester) async {
    await _openPlayer(tester);
    await _minimize(tester);

    await tester.timedDragFrom(
      const Offset(400, 560),
      const Offset(0, 60),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();
    expect(_state(tester).isOpen, isFalse);
    expect(find.text('bar'), findsNothing);
    expect(find.text('space 0.0'), findsOneWidget);
  });

  testWidgets('close() minimizes it first and forgets the page',
      (tester) async {
    await _openPlayer(tester);

    _state(tester).close();
    await tester.pumpAndSettle();
    expect(_state(tester).isOpen, isFalse);
    expect(find.byKey(_playerKey), findsNothing);

    await tester.tap(find.text('play'));
    await tester.pumpAndSettle();
    expect(_Player.initCount, 2);
  });
}
