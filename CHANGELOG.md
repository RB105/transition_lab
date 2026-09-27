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
