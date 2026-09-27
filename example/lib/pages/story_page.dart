import 'package:flutter/material.dart';
import 'package:transition_lab/transition_lab.dart';

import '../demo_data.dart';

class StoryPage extends StatelessWidget {
  const StoryPage({super.key, required this.index});

  final int index;

  void _next(BuildContext context) {
    if (index + 1 < stories.length) {
      Navigator.of(context).pushReplacement(
        CubePageRoute<void>(builder: (_) => StoryPage(index: index + 1)),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previous(BuildContext context) {
    if (index > 0) {
      Navigator.of(context).pushReplacement(
        CubePageRoute<void>(
          backward: true,
          builder: (_) => StoryPage(index: index - 1),
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Story story = stories[index];
    final TextStyle hintStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.85),
      fontSize: 13,
    );
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) {
          if (details.globalPosition.dx >
              MediaQuery.sizeOf(context).width / 2) {
            _next(context);
          } else {
            _previous(context);
          }
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: story.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < stories.length; i++)
                        Expanded(
                          child: Container(
                            height: 3,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(
                                alpha: i <= index ? 0.95 : 0.35,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        child: Text(
                          story.name[0],
                          style: TextStyle(
                            color: story.colors.first,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        story.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${index + 2} h', style: hintStyle),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: Icon(story.icon, size: 150, color: Colors.white),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('‹ previous', style: hintStyle),
                      Text('next ›', style: hintStyle),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
