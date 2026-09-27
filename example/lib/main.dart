import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:transition_lab/transition_lab.dart';

import 'demo_data.dart';
import 'pages/app_page.dart';
import 'pages/boarding_pass.dart';
import 'pages/book_page.dart';
import 'pages/chat_page.dart';
import 'pages/destination_page.dart';
import 'pages/photo_viewer.dart';
import 'pages/place_sheet.dart';
import 'pages/player.dart';
import 'pages/room_page.dart';
import 'pages/shortcut_page.dart';
import 'pages/story_page.dart';
import 'pages/venue_page.dart';

void main() => runApp(const TransitionsDemoApp());

class TransitionsDemoApp extends StatelessWidget {
  const TransitionsDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transition Lab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF009DE0),
        // Every MaterialPageRoute in the app now swings in.
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: SwingPageTransitionsBuilder(),
            TargetPlatform.iOS: SwingPageTransitionsBuilder(),
          },
        ),
      ),
      // Circular reveal opens from wherever the finger went down, and the
      // mini-player stays above every page.
      builder: (context, child) =>
          TapPosition.tracker(child: MiniPlayer(child: child!)),
      home: const DemoHomePage(),
    );
  }
}

class DemoHomePage extends StatefulWidget {
  const DemoHomePage({super.key});

  @override
  State<DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<DemoHomePage> {
  bool _slowMotion = timeDilation > 1;
  final ValueNotifier<bool> _playing = ValueNotifier(true);

  @override
  void dispose() {
    _playing.dispose();
    super.dispose();
  }

  void _play(Track track) {
    _playing.value = true;
    MiniPlayer.of(context).open(
      builder: (_) => PlayerPage(track: track, playing: _playing),
      barBuilder: (_) => PlayerBar(track: track, playing: _playing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final NavigatorState navigator = Navigator.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transitions',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          const Text('Slow-mo'),
          Switch(
            value: _slowMotion,
            onChanged: (value) => setState(() {
              _slowMotion = value;
              timeDilation = value ? 5 : 1;
            }),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        // Keeps the last section clear of the mini-player's bar.
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          40 + MiniPlayer.barSpaceOf(context),
        ),
        children: [
          const SectionHeader(
            number: 1,
            title: 'Swing',
            source: 'Wolt',
            hint: 'Tap a venue. Swipe from the left edge to go back.',
          ),
          SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: venues.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) => VenueCard(
                venue: venues[i],
                // A plain MaterialPageRoute: the theme makes it swing.
                onTap: () => navigator.push(
                  MaterialPageRoute<void>(
                    builder: (_) => VenuePage(venue: venues[i]),
                  ),
                ),
              ),
            ),
          ),
          const SectionHeader(
            number: 2,
            title: 'Zoom',
            source: 'iOS 18 · Photos, App Store',
            hint:
                'Tap a card. Pull the page down, or tap close, to shrink it back.',
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.9,
            children: [
              for (final destination in destinations)
                GestureDetector(
                  onTap: () => navigator.push(
                    ZoomPageRoute<void>(
                      tag: destination,
                      builder: (_) => DestinationPage(destination: destination),
                    ),
                  ),
                  child: ZoomSource(
                    tag: destination,
                    borderRadius: 20,
                    child: DestinationCard(destination: destination),
                  ),
                ),
            ],
          ),
          const SectionHeader(
            number: 3,
            title: 'Cube',
            source: 'Instagram Stories',
            hint: 'Tap a story. Tap the right half for the next one, the left '
                'half for the previous one.',
          ),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: stories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, i) => StoryAvatar(
                story: stories[i],
                onTap: () => navigator.push(
                  CubePageRoute<void>(builder: (_) => StoryPage(index: i)),
                ),
              ),
            ),
          ),
          const SectionHeader(
            number: 4,
            title: 'Circular reveal',
            source: 'Android, Telegram',
            hint: 'Tap anywhere on a tile: the page opens from under your '
                'finger.',
          ),
          for (final shortcut in shortcuts)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ShortcutTile(
                shortcut: shortcut,
                onTap: () => navigator.push(
                  CircularRevealRoute<void>(
                    builder: (_) => ShortcutPage(shortcut: shortcut),
                  ),
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: FloatingActionButton(
              heroTag: null,
              onPressed: () => navigator.push(
                CircularRevealRoute<void>(
                  builder: (_) => const ShortcutPage(shortcut: newTrip),
                ),
              ),
              child: const Icon(Icons.add),
            ),
          ),
          const SectionHeader(
            number: 5,
            title: 'Full-screen swipe back',
            source: 'Telegram',
            hint: 'Open a chat and swipe right from anywhere on the screen.',
          ),
          for (final chat in chats)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: chat.color,
                child: Text(
                  chat.name[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              title: Text(
                chat.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(chat.lastMessage),
              trailing: Text(chat.time),
              onTap: () => navigator.push(
                FullSwipePageRoute<void>(builder: (_) => ChatPage(chat: chat)),
              ),
            ),
          const SectionHeader(
            number: 6,
            title: 'Sheet',
            source: 'Apple Maps, Music',
            hint: 'Tap a place. Pull the sheet down from anywhere to close '
                'it; open a place nearby to stack another sheet.',
          ),
          for (final place in places)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: place.color,
                child: Icon(place.icon, color: Colors.white),
              ),
              title: Text(
                place.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: PlaceRating(place: place),
              onTap: () => navigator.push(
                SheetPageRoute<void>(builder: (_) => PlaceSheet(place: place)),
              ),
            ),
          const SectionHeader(
            number: 7,
            title: 'Drag to dismiss',
            source: 'Instagram, Telegram photo viewer',
            hint: 'Tap a photo. Drag it up or down to close; it flies back '
                'into the grid.',
          ),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: [
              for (var i = 0; i < photoIcons.length; i++)
                GestureDetector(
                  onTap: () => navigator.push(
                    DragDismissPageRoute<void>(
                      tag: 'photo $i',
                      builder: (_) => PhotoViewer(initialIndex: i),
                    ),
                  ),
                  child: ZoomSource(
                    tag: 'photo $i',
                    child: Photo(index: i),
                  ),
                ),
            ],
          ),
          const SectionHeader(
            number: 8,
            title: 'Flip',
            source: 'A card turning over',
            hint: 'Tap the boarding pass to turn it over.',
          ),
          BoardingPassCard(
            onTap: () => navigator.push(
              FlipPageRoute<void>(builder: (_) => const BoardingPassPage()),
            ),
          ),
          const SectionHeader(
            number: 9,
            title: 'Depth blur',
            source: 'iOS app launch, visionOS',
            hint: 'Tap an app: this page sinks back and blurs.',
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final app in demoApps)
                AppIcon(
                  app: app,
                  onTap: () => navigator.push(
                    DepthPageRoute<void>(builder: (_) => AppPage(app: app)),
                  ),
                ),
            ],
          ),
          const SectionHeader(
            number: 10,
            title: 'Door',
            source: 'A doorway',
            hint: 'Open a door: this page splits and swings open.',
          ),
          Row(
            children: [
              for (final room in rooms) ...[
                Expanded(
                  child: DoorTile(
                    room: room,
                    onTap: () => navigator.push(
                      DoorPageRoute<void>(builder: (_) => RoomPage(room: room)),
                    ),
                  ),
                ),
                if (room != rooms.last) const SizedBox(width: 16),
              ],
            ],
          ),
          const SectionHeader(
            number: 11,
            title: 'Page curl',
            source: 'Apple Books',
            hint: 'Open the book and turn the pages. Drag from the left edge '
                'to lift the corner and turn back.',
          ),
          Center(
            child: BookCover(
              onTap: () => navigator.push(
                PageCurlRoute<void>(builder: (_) => const BookPage(index: 0)),
              ),
            ),
          ),
          const SectionHeader(
            number: 12,
            title: 'Mini-player',
            source: 'YouTube, Spotify',
            hint: 'Play a track, then pull the player down: it shrinks into a '
                'bar that stays over every page.',
          ),
          for (final track in tracks)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Artwork(track: track, size: 44),
              title: Text(
                track.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(track.artist),
              trailing: const Icon(Icons.play_arrow),
              onTap: () => _play(track),
            ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.number,
    required this.title,
    required this.source,
    required this.hint,
  });

  final int number;
  final String title;
  final String source;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: colors.primary,
                child: Text(
                  '$number',
                  style: TextStyle(
                    color: colors.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            source,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(hint, style: TextStyle(color: Colors.grey.shade800)),
        ],
      ),
    );
  }
}

class VenueCard extends StatelessWidget {
  const VenueCard({super.key, required this.venue, required this.onTap});

  final Venue venue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 130,
              width: double.infinity,
              decoration: BoxDecoration(
                color: venue.color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(venue.icon, size: 56, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              venue.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              venue.tagline,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class StoryAvatar extends StatelessWidget {
  const StoryAvatar({super.key, required this.story, required this.onTap});

  final Story story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Color(0xFFF58529),
                  Color(0xFFDD2A7B),
                  Color(0xFF8134AF),
                ],
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: CircleAvatar(
                backgroundColor: story.colors.first,
                child: Icon(story.icon, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(story.name, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class ShortcutTile extends StatelessWidget {
  const ShortcutTile({super.key, required this.shortcut, required this.onTap});

  final Shortcut shortcut;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: shortcut.color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(shortcut.icon, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                shortcut.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}
