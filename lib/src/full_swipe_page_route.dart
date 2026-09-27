import 'package:flutter/material.dart';

import 'gestures.dart';
import 'swing_page_transitions_builder.dart';

/// The Telegram back gesture: swiping towards the trailing edge from anywhere
/// on the page pops it, not just from the screen edge. The page moves with
/// the swing transition.
///
/// ```dart
/// Navigator.of(context).push(
///   FullSwipePageRoute(builder: (_) => ChatPage(chat: chat)),
/// );
/// ```
///
/// Horizontal scrollables inside the page still get their own drags. The
/// swipe is disabled while a [PopScope] blocks popping.
class FullSwipePageRoute<T> extends PageRoute<T> {
  /// Creates a route that can be swiped back from anywhere on its page.
  FullSwipePageRoute({
    required this.builder,
    this.transitions = const SwingPageTransitionsBuilder(
      swipeBackEnabled: false,
    ),
    super.settings,
  });

  /// Builds the primary contents of the route.
  final WidgetBuilder builder;

  /// The transition used to push and pop this route.
  ///
  /// Keep its [SwingPageTransitionsBuilder.swipeBackEnabled] off, since this
  /// route brings its own swipe.
  final SwingPageTransitionsBuilder transitions;

  @override
  Duration get transitionDuration => transitions.transitionDuration;

  @override
  Duration get reverseTransitionDuration =>
      transitions.reverseTransitionDuration;

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      transitions.delegatedTransition;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: builder(context),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return transitions.buildTransitions<T>(
      this,
      context,
      animation,
      secondaryAnimation,
      BackDragGesture(
        route: this,
        controller: controller!,
        // Over the whole transition the default swing moves the page's edge
        // about 1.3 screen widths, so this keeps the edge under the finger.
        travel: 1.3,
        popDistance: 0.35,
        child: child,
      ),
    );
  }

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}
