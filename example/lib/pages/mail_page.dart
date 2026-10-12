import 'package:flutter/material.dart';

import '../demo_data.dart';

/// A mail in the inbox: the card the container transform grows into a page.
class MailCard extends StatelessWidget {
  const MailCard({super.key, required this.mail});

  final Mail mail;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: mail.color,
            child: Text(
              mail.sender[0],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mail.sender,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  mail.subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          Text(mail.time, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

/// The mail, opened out of its card.
class MailPage extends StatelessWidget {
  const MailPage({super.key, required this.mail});

  final Mail mail;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mail.color,
        foregroundColor: Colors.white,
        title: Text(mail.sender),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            mail.subject,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text('to me · ${mail.time}',
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 20),
          Text(mail.preview, style: const TextStyle(fontSize: 16, height: 1.5)),
          const SizedBox(height: 16),
          const Text(
            'The card you tapped kept its place on the screen and grew into '
            'this page, rounding its corners out as it went. Pull the page '
            'down to put it back.',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }
}
