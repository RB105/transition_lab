import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transition_lab_example/main.dart';
import 'package:transition_lab/transition_lab.dart';
import 'package:transition_lab_example/pages/app_page.dart';
import 'package:transition_lab_example/pages/boarding_pass.dart';
import 'package:transition_lab_example/pages/book_page.dart';
import 'package:transition_lab_example/pages/chat_page.dart';
import 'package:transition_lab_example/pages/destination_page.dart';
import 'package:transition_lab_example/pages/photo_viewer.dart';
import 'package:transition_lab_example/pages/place_sheet.dart';
import 'package:transition_lab_example/pages/player.dart';
import 'package:transition_lab_example/pages/room_page.dart';
import 'package:transition_lab_example/pages/shortcut_page.dart';
import 'package:transition_lab_example/pages/story_page.dart';
import 'package:transition_lab_example/pages/venue_page.dart';

// iPhone 17 sized screen: 402 x 874 logical pixels.
Future<void> _pumpDemo(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1206, 2622);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const TransitionsDemoApp());
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

int _storyIndex(WidgetTester tester) =>
    tester.widget<StoryPage>(find.byType(StoryPage)).index;

void main() {
  testWidgets('swing opens a venue and the edge swipe goes back',
      (tester) async {
    await _pumpDemo(tester);
    await tester.tap(find.text('Burger Lab'));
    await tester.pumpAndSettle();
    expect(find.byType(VenuePage), findsOneWidget);

    await tester.dragFrom(const Offset(5, 400), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(find.byType(VenuePage), findsNothing);
  });

  testWidgets('zoom grows out of the card and a pull closes it',
      (tester) async {
    await _pumpDemo(tester);
    await _scrollTo(tester, find.text('Samarkand'));
    await tester.tap(find.text('Samarkand'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200)); // mid-flight
    await tester.pumpAndSettle();
    expect(find.byType(DestinationPage), findsOneWidget);

    await tester.timedDragFrom(
      const Offset(200, 520),
      const Offset(0, 320),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DestinationPage), findsNothing);
  });

  testWidgets('the zoom close button shrinks it back', (tester) async {
    await _pumpDemo(tester);
    await _scrollTo(tester, find.text('Istanbul'));
    await tester.tap(find.text('Istanbul'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(DestinationPage), findsNothing);
  });

  testWidgets('cube moves between stories and closes', (tester) async {
    await _pumpDemo(tester);
    await _scrollTo(tester, find.text('Aziza'));
    await tester.tap(find.text('Aziza'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(_storyIndex(tester), 0);

    await tester.tapAt(const Offset(350, 450)); // right half: next
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(_storyIndex(tester), 1);

    await tester.tapAt(const Offset(50, 450)); // left half: previous
    await tester.pumpAndSettle();
    expect(_storyIndex(tester), 0);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(StoryPage), findsNothing);
  });

  testWidgets('circular reveal opens and closes', (tester) async {
    await _pumpDemo(tester);
    await _scrollTo(tester, find.text('Tickets'));
    await tester.tap(find.text('Tickets'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.byType(ShortcutPage), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(ShortcutPage), findsNothing);
  });

  testWidgets('full-screen swipe goes back from the middle of the page',
      (tester) async {
    await _pumpDemo(tester);
    await _scrollTo(tester, find.text('Family'));
    await tester.tap(find.text('Family'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatPage), findsOneWidget);

    // Dragging the horizontal media strip scrolls it and stays on the page.
    final Offset strip = tester.getCenter(
      find
          .descendant(
            of: find.byType(ChatPage),
            matching: find.byType(ListView),
          )
          .first,
    );
    await tester.timedDragFrom(
      strip,
      const Offset(-200, 0),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();
    await tester.timedDragFrom(
      strip,
      const Offset(280, 0),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ChatPage), findsOneWidget);

    await tester.timedDragFrom(
      const Offset(150, 600),
      const Offset(280, 0),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ChatPage), findsNothing);
  });

  testWidgets('sheet opens a place, stacks another and a pull closes it',
      (tester) async {
    await _pumpDemo(tester);
    await _scrollTo(tester, find.text('Registan Square'));
    await tester.tap(find.text('Registan Square'));
    await tester.pumpAndSettle();
    expect(find.byType(PlaceSheet), findsOneWidget);

    await tester.tap(find.text('Chorsu Bazaar').last);
    await tester.pumpAndSettle();
    expect(find.byType(PlaceSheet), findsNWidgets(2));

    await tester.timedDragFrom(
      const Offset(200, 400),
      const Offset(0, 400),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PlaceSheet), findsOneWidget);
  });

  testWidgets('drag dismiss opens a photo and a drag closes it',
      (tester) async {
    await _pumpDemo(tester);
    await _scrollTo(
        tester, find.text('Tap the boarding pass to turn it over.'));
    await tester.ensureVisible(find.byType(Photo, skipOffstage: false).at(4));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Photo).at(4));
    await tester.pumpAndSettle();
    expect(find.text('5 / 9'), findsOneWidget);

    // Sideways pages through the photos.
    await tester.timedDragFrom(
      const Offset(350, 450),
      const Offset(-300, 0),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();
    expect(find.text('6 / 9'), findsOneWidget);

    await tester.timedDragFrom(
      const Offset(200, 450),
      const Offset(0, -300),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PhotoViewer), findsNothing);
  });

  testWidgets('flip turns the boarding pass over and back', (tester) async {
    await _pumpDemo(tester);
    await _scrollTo(tester, find.text('TAS'));
    await tester.tap(find.text('TAS'));
    await tester.pumpAndSettle();
    expect(find.byType(BoardingPassPage), findsOneWidget);

    await tester.tap(find.text('Flip back'));
    await tester.pumpAndSettle();
    expect(find.byType(BoardingPassPage), findsNothing);
  });

  testWidgets('depth opens an app and the edge swipe goes back',
      (tester) async {
    await _pumpDemo(tester);
    await _scrollTo(tester, find.text('Weather'));
    await tester.tap(find.text('Weather'));
    await tester.pumpAndSettle();
    expect(find.byType(AppPage), findsOneWidget);

    await tester.dragFrom(const Offset(5, 400), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(find.byType(AppPage), findsNothing);
  });

  testWidgets('door opens a room and closes behind you', (tester) async {
    await _pumpDemo(tester);
    await _scrollTo(tester, find.text('Suite 501'));
    await tester.tap(find.text('Suite 501'));
    await tester.pumpAndSettle();
    expect(find.byType(RoomPage), findsOneWidget);

    await tester.tap(find.text('Leave the room'));
    await tester.pumpAndSettle();
    expect(find.byType(RoomPage), findsNothing);
  });

  testWidgets('page curl turns the pages and the corner turns them back',
      (tester) async {
    await _pumpDemo(tester);
    await _scrollTo(tester, find.text('The Silk Road'));
    await tester.tap(find.text('The Silk Road'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Turn the page ›'));
    await tester.pumpAndSettle();
    expect(find.text('Chapter 2'), findsOneWidget);

    await tester.timedDragFrom(
      const Offset(10, 700),
      const Offset(300, -40),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chapter 2'), findsNothing);
    expect(find.text('Chapter 1'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(BookPage), findsNothing);
  });

  testWidgets('the mini-player minimizes into a bar and closes',
      (tester) async {
    await _pumpDemo(tester);
    await _scrollTo(tester, find.text('Night Train'));
    await tester.tap(find.text('Night Train'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(PlayerPage), findsOneWidget);
    // Paused, so nothing keeps animating.
    await tester.tap(find.byIcon(Icons.pause_circle_filled).first);
    await tester.pumpAndSettle();

    await tester.timedDragFrom(
      const Offset(200, 300),
      const Offset(0, 500),
      const Duration(milliseconds: 400),
    );
    await tester.pumpAndSettle();
    final MiniPlayerState player =
        tester.state<MiniPlayerState>(find.byType(MiniPlayer));
    expect(player.expansion.value, 0);
    expect(find.byType(PlayerBar), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();
    expect(player.isOpen, isFalse);
  });
}
