## 0.3.0

* `ContainerTransformRoute`: Material 3's container transform. The card grows
  into the page at full size, instead of the page being scaled into the card.
* `SharedAxisPageRoute`, `SharedAxisPageTransitionsBuilder` and `SharedAxis`:
  Material 3's shared axis, along X, Y or Z.
* `FadeThroughPageRoute` and `FadeThroughPageTransitionsBuilder`: Material 3's
  fade through.
* `PinchDismissPageRoute`: a photo viewer closed with a two-finger pinch. One
  finger is left to the content.
* `FoldPageRoute`: Flipboard's fold, along a crease across the middle.
* `CardStackRoute`: a card dealt onto a stack, thrown away to go back.
* `TopSheetRoute`: the iOS Control Center sheet, pushed back up to close.
* `DrawerPageRoute`: a side menu over the page, with a scrim that closes it.
* `WipePageRoute` and `WipeStyle`: four masks in one route, shutter, diagonal,
  clock and iris.
* `GlassRevealRoute`: the iOS 26 glass ripple, with a lit band on its edge.
* `TurnstileRoute`: the Windows Phone turnstile.
* `IslandPageRoute`: a page growing out of the Dynamic Island.
* `WalletPageRoute`: an Apple Wallet pass rising out of the stack.
* `BackDragGesture` can now run towards the leading edge, for panels that came
  in from there.
* The example app and the README cover all twenty-five transitions.

## 0.2.0

* Renamed from `swing_page_transition` to `transition_lab`. Import
  `package:transition_lab/transition_lab.dart`.
* `ZoomPageRoute` and `ZoomSource`: the iOS 18 zoom. The page grows out of a
  widget and a pull down shrinks it back.
* `SheetPageRoute`: the iOS page sheet, pulled down from anywhere to close.
  Sheets stack.
* `DragDismissPageRoute`: a photo viewer that follows the finger and flies
  back into its thumbnail.
* `CubePageRoute`: the Instagram Stories cube.
* `FlipPageRoute`: a card turning over.
* `DepthPageRoute`: the page underneath recedes into a blur.
* `DoorPageRoute`: the page underneath opens like a pair of doors.
* `PageCurlRoute`: an Apple Books page turn, with a corner that follows the
  finger.
* `CircularRevealRoute` and `TapPosition`: a circular reveal that opens from
  the last tap.
* `FullSwipePageRoute`: Telegram's swipe back from anywhere on the page, with
  the swing transition.
* `MiniPlayer`: a page that minimizes into a bar and stays alive, as in
  YouTube and Spotify.
* The example app shows every transition.
* A GIF of every transition in the README.

## 0.1.0

* Initial release: `SwingPageTransitionsBuilder` and `SwingPageRoute`.
