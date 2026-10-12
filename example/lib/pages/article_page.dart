import 'package:flutter/material.dart';

import '../demo_data.dart';

/// The article's cover in the feed.
class ArticleCard extends StatelessWidget {
  const ArticleCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF263238),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LONG READ',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                articleTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The article, which arrives folded in half and opens flat.
class ArticlePage extends StatelessWidget {
  const ArticlePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF263238),
        foregroundColor: Colors.white,
        title: const Text('Long read'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            articleTitle,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          const Text(articleBody, style: TextStyle(fontSize: 16, height: 1.6)),
          const SizedBox(height: 24),
          Text(
            'The page came in folded along the crease across its middle, and '
            'the half that was turned away from the light was darker until it '
            'lay flat. Swipe from the left edge to fold it shut again.',
            style: TextStyle(color: Colors.grey.shade700, height: 1.5),
          ),
        ],
      ),
    );
  }
}
