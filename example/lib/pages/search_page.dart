import 'package:flutter/material.dart';

/// The page the glass ripple uncovers.
class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101418),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: TextField(
                      autofocus: false,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Color(0xFF1E252D),
                        prefixIcon: Icon(Icons.search, color: Colors.white54),
                        hintText: 'Search',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              for (final String recent in const [
                'Registan at sunrise',
                'Night train to Bukhara',
                'Plov, the good one',
              ])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history, color: Colors.white54),
                  title: Text(
                    recent,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              const Spacer(),
              const Text(
                'The ripple opened from the point you touched, with a band of '
                'blurred, lit glass riding its edge. Swipe from the left edge '
                'to close it.',
                style: TextStyle(color: Colors.white54, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
