# transition_lab

Page transitions for Flutter, re-created from well-known apps. Each one is a
drop-in route, keeps a back gesture that follows the finger, respects
`PopScope` and works right to left. No dependencies.

| | | |
| :-: | :-: | :-: |
| **[Swing](#swing)**<br>`SwingPageRoute`<br>Wolt<br><img src="https://raw.githubusercontent.com/RB105/transition_lab/main/doc/gifs/swing.gif" width="220" alt="Swing transition"> | **[Zoom](#zoom)**<br>`ZoomPageRoute`<br>iOS 18 Photos, App Store<br><img src="https://raw.githubusercontent.com/RB105/transition_lab/main/doc/gifs/zoom.gif" width="220" alt="Zoom transition"> | **[Sheet](#sheet)**<br>`SheetPageRoute`<br>Apple Maps, Music<br><img src="https://raw.githubusercontent.com/RB105/transition_lab/main/doc/gifs/sheet.gif" width="220" alt="Sheet transition"> |
| **[Drag to dismiss](#drag-to-dismiss)**<br>`DragDismissPageRoute`<br>Instagram, Telegram<br><img src="https://raw.githubusercontent.com/RB105/transition_lab/main/doc/gifs/drag_dismiss.gif" width="220" alt="Drag to dismiss transition"> | **[Cube](#cube)**<br>`CubePageRoute`<br>Instagram Stories<br><img src="https://raw.githubusercontent.com/RB105/transition_lab/main/doc/gifs/cube.gif" width="220" alt="Cube transition"> | **[Flip](#flip)**<br>`FlipPageRoute`<br>A card turning over<br><img src="https://raw.githubusercontent.com/RB105/transition_lab/main/doc/gifs/flip.gif" width="220" alt="Flip transition"> |
| **[Depth blur](#depth-blur)**<br>`DepthPageRoute`<br>iOS app launch, visionOS<br><img src="https://raw.githubusercontent.com/RB105/transition_lab/main/doc/gifs/depth.gif" width="220" alt="Depth blur transition"> | **[Door](#door)**<br>`DoorPageRoute`<br>A doorway<br><img src="https://raw.githubusercontent.com/RB105/transition_lab/main/doc/gifs/door.gif" width="220" alt="Door transition"> | **[Page curl](#page-curl)**<br>`PageCurlRoute`<br>Apple Books<br><img src="https://raw.githubusercontent.com/RB105/transition_lab/main/doc/gifs/page_curl.gif" width="220" alt="Page curl transition"> |
| **[Circular reveal](#circular-reveal)**<br>`CircularRevealRoute`<br>Android, Telegram<br><img src="https://raw.githubusercontent.com/RB105/transition_lab/main/doc/gifs/circular_reveal.gif" width="220" alt="Circular reveal transition"> | **[Full-screen swipe back](#full-screen-swipe-back)**<br>`FullSwipePageRoute`<br>Telegram<br><img src="https://raw.githubusercontent.com/RB105/transition_lab/main/doc/gifs/full_swipe.gif" width="220" alt="Full-screen swipe back transition"> | **[Mini-player](#mini-player)**<br>`MiniPlayer`<br>YouTube, Spotify<br><img src="https://raw.githubusercontent.com/RB105/transition_lab/main/doc/gifs/mini_player.gif" width="220" alt="Mini-player transition"> |

The [example app](example/lib/main.dart) shows every one of them. Turn on
its slow motion switch to watch them closely.

```yaml
dependencies:
  transition_lab: ^0.2.0
```

This package was called `swing_page_transition` up to 0.1.0.

## Swing

The new page swings in from the side, rotating around the vertical axis and
zooming down to size like a book page being turned, while the page
underneath slides back, shrinks and dims. The defaults reproduce the page
transition of the Wolt app, following
[Shadi F's React Navigation re-creation](https://iamshadi.medium.com/re-creating-the-wolts-smooth-page-transition-with-expo-router-in-react-native-0b34541452db).
This package is not affiliated with Wolt, or with any other app named here.

- **One line in your theme.** Every `MaterialPageRoute` swings in, including
  `Navigator.pushNamed` and routers that build on it.
- **`SwingPageRoute`** swings in a single page, whatever the theme.
- **iOS edge swipe back** is kept (it is Flutter's own Cupertino gesture).
- **The page underneath recedes** even when it is not a `MaterialPageRoute`,
  such as a `PageRouteBuilder` root.

### Every route

```dart
MaterialApp(
  theme: ThemeData(
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: SwingPageTransitionsBuilder(),
        TargetPlatform.iOS: SwingPageTransitionsBuilder(),
      },
    ),
  ),
  home: const HomePage(),
);
```

### A single route

```dart
Navigator.of(context).push(
  SwingPageRoute(builder: (_) => const DetailsPage()),
);
```

### Tuning

```dart
const SwingPageTransitionsBuilder(
  duration: Duration(milliseconds: 450),
  enterAngle: math.pi / 6, // 30° instead of 60°
  enterScale: 1.3,
  coveredOverlayColor: Color(0x66000000),
)
```

| Parameter | Default | Effect |
| --- | --- | --- |
| `duration` | 550 ms | Push duration. |
| `reverseDuration` | `duration` | Pop duration. |
| `curve` | `Curves.easeOut` | Easing. A pop plays it backwards. |
| `enterOffset` | `1.6` | Where the new page starts, in screen widths. |
| `enterAngle` | `pi / 3` (60°) | Its starting rotation around the vertical axis. |
| `enterScale` | `1.6` | Its starting scale. |
| `enterOpacity` | `0.8` | Its starting opacity. |
| `perspective` | `1000` | Viewer distance in logical pixels, like CSS `perspective()`. |
| `coveredOffset` | `-0.3` | How far the page underneath slides, in screen widths. |
| `coveredScale` | `0.9` | How far the page underneath shrinks. |
| `coveredOverlayColor` | 50% black | How much the page underneath dims. |
| `backdropColor` | black | Shown around the shrunk page; `null` for none. |
| `swipeBackEnabled` | `true` | Whether an edge swipe pops the route. |

### Coming from React Navigation

| `@react-navigation/stack` | transition_lab |
| --- | --- |
| `current.progress` | the route's `animation` |
| `next.progress` | the route's `secondaryAnimation` |
| `transitionSpec`: 550 ms, `Easing.out(Easing.ease)` / `Easing.in(Easing.ease)` | `duration`, `curve: Curves.easeOut` (played backwards on pop, which equals `Easing.in`) |
| `translateX` 1.6 × width, `rotateY` 60°, `scale` 1.6, `perspective` 1000 | `enterOffset`, `enterAngle`, `enterScale`, `perspective` |
| card opacity 0.8 → 1 | `enterOpacity` |
| `next`: `translateX` −0.3 × width, `scale` 0.9 | `coveredOffset`, `coveredScale` |
| `cardOverlayEnabled`, overlay opacity 0 → 0.5 | `coveredOverlayColor` |
| `gestureEnabled` | `swipeBackEnabled` |

## Zoom

The iOS 18 zoom: the page grows out of the widget that was tapped, and
shrinks back into it when popped. Mark that widget with a `ZoomSource` and
push a `ZoomPageRoute` with the same `tag`:

```dart
GestureDetector(
  onTap: () => Navigator.of(context).push(
    ZoomPageRoute(tag: item, builder: (_) => ItemPage(item: item)),
  ),
  child: ZoomSource(tag: item, borderRadius: 20, child: ItemCard(item)),
)
```

Pulling the page down while its content is scrolled to the top shrinks it
around the finger; letting go far or fast enough closes it. The source is
hidden while the page is open and cross-fades into it at the start. Like
`Hero` tags, a tag should belong to one mounted `ZoomSource` at a time.

## Sheet

The iOS page sheet: the page slides up as a card with rounded top corners,
while the page underneath shrinks back, dims and peeks out above it.

```dart
Navigator.of(context).push(
  SheetPageRoute(builder: (_) => PlaceDetails(place: place)),
);
```

Pulling the sheet down from anywhere while its content is scrolled to the
top drags it with the finger. Sheets stack: a sheet pushed over another one
shrinks it back in turn.

## Drag to dismiss

The photo viewer of Instagram, Telegram and iOS Photos: the page opens over
a dark background, and a vertical drag lets it follow the finger in any
direction while the background fades.

```dart
GestureDetector(
  onTap: () => Navigator.of(context).push(
    DragDismissPageRoute(tag: photo, builder: (_) => PhotoViewer(photo)),
  ),
  child: ZoomSource(tag: photo, child: Thumbnail(photo)),
)
```

With a `tag`, the photo grows out of its thumbnail and flies back into it.
Without one, it fades in and is thrown off the screen the way it was
dragged. Only vertical drags start it, so a horizontal `PageView` of photos
inside still swipes between them. Make the page's background transparent:
the route paints `backgroundColor` behind it.

## Cube

The Instagram Stories cube: the two pages are faces of a cube that turns.
The new page comes in from the trailing edge; pass `backward: true` to bring
it in from the leading edge, as when going back to the previous story:

```dart
// Next story.
Navigator.of(context).pushReplacement(
  CubePageRoute(builder: (_) => StoryPage(index: index + 1)),
);

// Previous story.
Navigator.of(context).pushReplacement(
  CubePageRoute(backward: true, builder: (_) => StoryPage(index: index - 1)),
);
```

## Flip

The two pages are the front and the back of a card that turns over around
its vertical axis, moving back a little as it turns.

```dart
Navigator.of(context).push(
  FlipPageRoute(builder: (_) => const TicketBackPage()),
);
```

## Depth blur

As when an app opens on iOS or a window comes forward on visionOS: the page
underneath recedes, blurs and dims, while the new page settles in from
slightly in front of the screen.

```dart
Navigator.of(context).push(
  DepthPageRoute(builder: (_) => const SettingsPage()),
);
```

Blurring a whole page every frame is costly on low-end devices: lower
`blurSigma`, or set it to 0 to leave the blur out.

## Door

A doorway: the page underneath splits down the middle and its two halves
swing open like double doors, revealing the new page as it comes forward.
Popping closes the doors again.

```dart
Navigator.of(context).push(
  DoorPageRoute(builder: (_) => const RoomPage()),
);
```

## Page curl

Apple Books: the page is a sheet of paper whose bottom corner lifts and
folds over, the flap showing the back of the paper, until the page has
turned away. A push lays the page down the same way in reverse.

```dart
Navigator.of(context).push(
  PageCurlRoute(builder: (_) => BookPage(number: number + 1)),
);
```

Dragging from the leading edge of the page lifts the corner under the
finger; letting go far or fast enough turns the page away.

## Circular reveal

Material's circular reveal: the page opens as a circle growing from where the
user tapped. Track taps once for the whole app, then push the route:

```dart
MaterialApp(
  builder: (context, child) => TapPosition.tracker(child: child!),
  home: const HomePage(),
);

Navigator.of(context).push(
  CircularRevealRoute(builder: (_) => const SearchPage()),
);
```

Pass `center` to open from a specific point instead. Without either, the
circle grows from the middle of the screen.

## Full-screen swipe back

Telegram's back gesture: swipe towards the trailing edge from anywhere on the
page, not only from the screen edge. The page moves with the swing transition.

```dart
Navigator.of(context).push(
  FullSwipePageRoute(builder: (_) => ChatPage(chat: chat)),
);
```

Horizontal scrollables inside the page, such as a photo strip, still get
their own drags. Pass `transitions` to tune the swing, leaving its
`swipeBackEnabled` off.

## Mini-player

The player of YouTube and Spotify: a page that minimizes into a bar at the
bottom of the screen and stays alive there, so whatever plays in it carries
on. Put `MiniPlayer` above the navigator, then open pages in it:

```dart
MaterialApp(
  builder: (context, child) => MiniPlayer(child: child!),
  home: const HomePage(),
);

MiniPlayer.of(context).open(
  builder: (_) => PlayerPage(track: track),
  barBuilder: (_) => PlayerBar(track: track),
);
```

Pulling the page down from anywhere while its content is scrolled to the top
shrinks it into the bar; tapping the bar or dragging it up expands it, and
dragging it down closes the player. `MiniPlayer.of(context)` also has
`expand()`, `minimize()` and `close()`, and `MiniPlayer.barSpaceOf(context)`
tells pages how much room to leave for the bar.

The player lives outside the app's navigator, in an overlay of its own, so
`Navigator.of` does not reach the app's navigator from inside it.

## Notes

- Requires Flutter 3.27 or newer. On Flutter 3.27 and 3.28, `MaterialPageRoute`
  ignores `duration` and runs for 300 ms; `SwingPageRoute` always honors it.
- During a back swipe both pages follow the finger linearly with the same
  geometry, so the swinging page moves faster than the finger, as in the
  original.
- `ZoomPageRoute`, `DragDismissPageRoute` and `CircularRevealRoute` assume
  their navigator fills the screen, as the app's root navigator does.
- `DoorPageRoute` and `PageCurlRoute` draw from a snapshot of the page taken
  as the transition starts, so that page does not animate meanwhile. Pages
  with platform views are not snapshotted and simply stay in place.
