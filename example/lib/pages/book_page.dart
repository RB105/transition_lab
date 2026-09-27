import 'package:flutter/material.dart';
import 'package:transition_lab/transition_lab.dart';

import '../demo_data.dart';

const _paper = Color(0xFFFBF6EC);
const _ink = Color(0xFF3E2723);

/// The book's cover on the home page.
class BookCover extends StatelessWidget {
  const BookCover({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 170,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8D2B0B), Color(0xFFB5541C)],
          ),
          borderRadius: BorderRadius.circular(6),
          boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black26)],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_stories, color: Color(0xFFFFE0B2), size: 40),
            SizedBox(height: 8),
            Text(
              bookTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFFFE0B2),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A page of the book, turned in with [PageCurlRoute].
class BookPage extends StatelessWidget {
  const BookPage({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final bool last = index == bookPages.length - 1;
    return Scaffold(
      backgroundColor: _paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).popUntil(
                      (route) => route is! PageCurlRoute,
                    ),
                    icon: const Icon(Icons.close, color: _ink),
                  ),
                  const Spacer(),
                  Text(
                    bookTitle.toUpperCase(),
                    style: const TextStyle(
                      color: _ink,
                      letterSpacing: 2,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Chapter ${index + 1}',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 26,
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                bookPages[index],
                style: const TextStyle(
                  color: _ink,
                  fontSize: 19,
                  height: 1.6,
                  fontFamily: 'serif',
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      index == 0
                          ? 'Drag from the left edge to close the book'
                          : 'Drag from the left edge to turn back',
                      style: TextStyle(color: _ink.withValues(alpha: 0.6)),
                    ),
                  ),
                  Text('${index + 1}', style: const TextStyle(color: _ink)),
                ],
              ),
              const SizedBox(height: 12),
              if (!last)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      PageCurlRoute<void>(
                        builder: (_) => BookPage(index: index + 1),
                      ),
                    ),
                    child: const Text('Turn the page ›'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
