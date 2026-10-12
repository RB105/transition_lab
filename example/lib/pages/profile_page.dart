import 'package:flutter/material.dart';

import '../demo_data.dart';

/// A profile in the list.
class ProfileTile extends StatelessWidget {
  const ProfileTile({super.key, required this.profile, required this.onTap});

  final Profile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: profile.color,
        child: Icon(profile.icon, color: Colors.white, size: 20),
      ),
      title: Text(
        '${profile.name}, ${profile.age}',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(profile.bio),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

/// A profile dealt onto the stack as a card.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: profile.color,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
              const Spacer(),
              Icon(profile.icon, size: 96, color: Colors.white),
              const SizedBox(height: 24),
              Text(
                '${profile.name}, ${profile.age}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                profile.bio,
                style: const TextStyle(color: Colors.white70, fontSize: 17),
              ),
              const Spacer(),
              const Text(
                'Throw the card towards the right edge to send it away; the '
                'card underneath comes back up to full size.',
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
