import 'package:flutter/material.dart';

class Venue {
  const Venue(this.name, this.tagline, this.color, this.icon);

  final String name;
  final String tagline;
  final Color color;
  final IconData icon;
}

const venues = [
  Venue(
    'Burger Lab',
    'Smash burgers · 25–35 min',
    Color(0xFFFF7043),
    Icons.lunch_dining,
  ),
  Venue(
    'Sushi Go',
    'Rolls & poke · 30–40 min',
    Color(0xFF26A69A),
    Icons.set_meal,
  ),
  Venue(
    'Pizza Napoli',
    'Wood-fired · 20–30 min',
    Color(0xFFEF5350),
    Icons.local_pizza,
  ),
  Venue(
    'Green Bowl',
    'Salads & bowls · 15–25 min',
    Color(0xFF66BB6A),
    Icons.eco,
  ),
  Venue(
    'Coffee Point',
    'Coffee & desserts · 10–20 min',
    Color(0xFF8D6E63),
    Icons.coffee,
  ),
];

class Destination {
  const Destination(this.city, this.tagline, this.color, this.icon);

  final String city;
  final String tagline;
  final Color color;
  final IconData icon;
}

const destinations = [
  Destination(
    'Samarkand',
    'Registan · 3 days',
    Color(0xFF1E6FE8),
    Icons.mosque,
  ),
  Destination(
    'Istanbul',
    'Bosphorus · 5 days',
    Color(0xFFE53935),
    Icons.sailing,
  ),
  Destination(
    'Dubai',
    'Burj Khalifa · 4 days',
    Color(0xFFF59E0B),
    Icons.apartment,
  ),
  Destination(
    'Tokyo',
    'Shibuya · 7 days',
    Color(0xFF7C3AED),
    Icons.temple_buddhist,
  ),
];

class Story {
  const Story(this.name, this.icon, this.colors);

  final String name;
  final IconData icon;
  final List<Color> colors;
}

const stories = [
  Story('Aziza', Icons.beach_access, [Color(0xFFFF6A88), Color(0xFFFF99AC)]),
  Story('Jasur', Icons.hiking, [Color(0xFF4FACFE), Color(0xFF00C6FB)]),
  Story('Madina', Icons.local_cafe, [Color(0xFFF7971E), Color(0xFFFFD200)]),
  Story(
    'Bekzod',
    Icons.directions_bike,
    [Color(0xFF11998E), Color(0xFF38EF7D)],
  ),
  Story('Nigora', Icons.photo_camera, [Color(0xFF8E2DE2), Color(0xFFDA22FF)]),
];

class Shortcut {
  const Shortcut(this.title, this.icon, this.color);

  final String title;
  final IconData icon;
  final Color color;
}

const shortcuts = [
  Shortcut('Tickets', Icons.airplane_ticket, Color(0xFF00897B)),
  Shortcut('Hotels', Icons.hotel, Color(0xFF5E35B1)),
  Shortcut('Visas', Icons.badge, Color(0xFFD81B60)),
];

const newTrip = Shortcut('New trip', Icons.add_location_alt, Color(0xFF009DE0));

class Chat {
  const Chat(this.name, this.lastMessage, this.time, this.color);

  final String name;
  final String lastMessage;
  final String time;
  final Color color;
}

const chats = [
  Chat(
    'Travel Support',
    'Your ticket is confirmed',
    '12:40',
    Color(0xFF009DE0),
  ),
  Chat('Family', 'What time is your flight?', '11:02', Color(0xFF43A047)),
  Chat(
    'Design team',
    'Have you seen the new animation?',
    '09:15',
    Color(0xFFFB8C00),
  ),
];

const chatMessages = [
  'Hi! Is the ticket ready?',
  'Yes, just sent it',
  'Thanks! What time is the flight?',
  'Tomorrow at 07:30, from Tashkent',
  "I'll get to the airport two hours early",
  'Good call!',
];

class Place {
  const Place(this.name, this.kind, this.rating, this.color, this.icon);

  final String name;
  final String kind;
  final double rating;
  final Color color;
  final IconData icon;
}

const places = [
  Place('Registan Square', 'Landmark', 4.9, Color(0xFF1E88E5), Icons.mosque),
  Place('Chorsu Bazaar', 'Market', 4.7, Color(0xFF43A047), Icons.storefront),
  Place('Amir Timur Museum', 'Museum', 4.6, Color(0xFF8E24AA), Icons.museum),
];

// A grid of photos: each is a color and an icon.
const photoIcons = [
  Icons.landscape,
  Icons.beach_access,
  Icons.local_florist,
  Icons.pets,
  Icons.restaurant,
  Icons.directions_boat,
  Icons.nightlife,
  Icons.park,
  Icons.cake,
];

Color photoColor(int index) =>
    HSVColor.fromAHSV(1, (index * 40 + 10) % 360, 0.55, 0.85).toColor();

class DemoApp {
  const DemoApp(this.name, this.icon, this.color);

  final String name;
  final IconData icon;
  final Color color;
}

const demoApps = [
  DemoApp('Settings', Icons.settings, Color(0xFF8E8E93)),
  DemoApp('Wallet', Icons.account_balance_wallet, Color(0xFF1C1C1E)),
  DemoApp('Weather', Icons.wb_sunny, Color(0xFF2F80ED)),
  DemoApp('Notes', Icons.sticky_note_2, Color(0xFFF2C94C)),
];

class Room {
  const Room(this.name, this.details, this.color);

  final String name;
  final String details;
  final Color color;
}

const rooms = [
  Room('Room 204', 'Double · city view', Color(0xFF6D4C41)),
  Room('Suite 501', 'King · terrace', Color(0xFF455A64)),
];

const bookTitle = 'The Silk Road';

const bookPages = [
  'Long before there were maps of it, there was the road. Caravans left '
      'the oases at dawn, and the dust they raised could be seen for miles '
      'across the steppe.',
  'Samarkand sat where the routes crossed. Merchants traded silk for '
      'silver, paper for glass, and stories for more stories, which were '
      'worth the most of all.',
  'Each city was a page, and every traveller read them in a different '
      'order. Some never reached the last one; some never wanted to.',
  'This is the last page of the sample. Pull the corner of the page from '
      'the left edge to turn back.',
];

class Track {
  const Track(this.title, this.artist, this.colors, this.icon);

  final String title;
  final String artist;
  final List<Color> colors;
  final IconData icon;
}

const tracks = [
  Track('Caravan', 'Oasis Trio', [Color(0xFFFF512F), Color(0xFFDD2476)],
      Icons.album),
  Track('Night Train', 'Steppe Lines', [Color(0xFF1D2B64), Color(0xFF6A82FB)],
      Icons.train),
  Track('Blue Domes', 'Registan Choir', [Color(0xFF00B4DB), Color(0xFF0083B0)],
      Icons.graphic_eq),
];

class Mail {
  const Mail(this.sender, this.subject, this.preview, this.time, this.color);

  final String sender;
  final String subject;
  final String preview;
  final String time;
  final Color color;
}

const mails = [
  Mail(
    'Silk Road Airlines',
    'Your boarding pass',
    'Check in is open for TAS - IST on Friday.',
    '08:12',
    Color(0xFF0B3D91),
  ),
  Mail(
    'Nilufar Karimova',
    'Re: Samarkand photos',
    'These came out great. Can you send the raw files?',
    '09:40',
    Color(0xFF8E24AA),
  ),
  Mail(
    'Registan Hotel',
    'Booking confirmed',
    'Room 204, two nights, breakfast included.',
    '11:05',
    Color(0xFF00897B),
  ),
];

class Profile {
  const Profile(this.name, this.age, this.bio, this.color, this.icon);

  final String name;
  final int age;
  final String bio;
  final Color color;
  final IconData icon;
}

const profiles = [
  Profile('Dilnoza', 27, 'Ceramics, long walks, bad puns.', Color(0xFFE91E63),
      Icons.palette),
  Profile('Sardor', 31, 'Mountains on weekends, code on weekdays.',
      Color(0xFF3949AB), Icons.terrain),
  Profile('Kamila', 24, 'Tea, film cameras, old maps.', Color(0xFF00897B),
      Icons.camera_alt),
];

class Pass {
  const Pass(this.from, this.to, this.code, this.gate, this.color);

  final String from;
  final String to;
  final String code;
  final String gate;
  final Color color;
}

const passes = [
  Pass('Tashkent', 'Istanbul', 'TK 369', 'B12', Color(0xFF0B3D91)),
  Pass('Istanbul', 'Lisbon', 'TK 1047', 'A7', Color(0xFF8E24AA)),
  Pass('Lisbon', 'Tashkent', 'TK 1048', 'C3', Color(0xFF00695C)),
];

class LibrarySection {
  const LibrarySection(this.name, this.detail, this.color, this.icon);

  final String name;
  final String detail;
  final Color color;
  final IconData icon;
}

const librarySections = [
  LibrarySection('Listen now', '12 new tracks', Color(0xFFD81B60), Icons.radio),
  LibrarySection(
      'Library', '340 songs', Color(0xFF1E88E5), Icons.library_music),
  LibrarySection('Search', 'Everything else', Color(0xFF43A047), Icons.search),
];

// The three steps of a checkout, shown with the shared axis transition.
const checkoutSteps = [
  ('Cart', 'Two items, 420 000 so\'m'),
  ('Delivery', 'Amir Temur 15, Tashkent'),
  ('Payment', 'Card ending 4417'),
];

const articleTitle = 'The road that folded the map';

const articleBody =
    'Every caravan city on the route kept its own account of the road, and '
    'none of them agreed. Samarkand measured it in days to the next well, '
    'Bukhara in the price of silk, Merv in the number of gates a traveller '
    'had to pass before dark.\n\n'
    'Put the accounts side by side and the road folds in on itself: the same '
    'stretch of dust is three days long, a week long, and no distance at all, '
    'depending on who is doing the counting and what they are carrying.';

class Pivot {
  const Pivot(this.title, this.detail, this.color);

  final String title;
  final String detail;
  final Color color;
}

const pivots = [
  Pivot('people', '14 online', Color(0xFF00838F)),
  Pivot('photos', '2 albums', Color(0xFF6A1B9A)),
];
