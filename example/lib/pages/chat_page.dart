import 'package:flutter/material.dart';

import '../demo_data.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key, required this.chat});

  final Chat chat;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCE6EE),
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: chat.color,
              child: Text(
                chat.name[0],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chat.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'online',
                  style: TextStyle(fontSize: 12, color: chat.color),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFFFFF4CE),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: const Row(
              children: [
                Icon(Icons.swipe_right, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Swipe right from anywhere on the screen to go back',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 86,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12),
              itemCount: 10,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => Container(
                width: 62,
                decoration: BoxDecoration(
                  color: HSVColor.fromAHSV(
                    1,
                    (i * 36) % 360,
                    0.45,
                    0.95,
                  ).toColor(),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo, color: Colors.white),
              ),
            ),
          ),
          Text(
            'The media strip scrolls on its own without triggering the swipe '
            'back',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: 24,
              itemBuilder: (_, i) {
                final bool mine = i.isOdd;
                return Align(
                  alignment:
                      mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    constraints: const BoxConstraints(maxWidth: 260),
                    decoration: BoxDecoration(
                      color: mine ? const Color(0xFFE6FBD4) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(chatMessages[i % chatMessages.length]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
