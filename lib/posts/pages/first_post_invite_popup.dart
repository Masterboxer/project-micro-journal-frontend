import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class FirstPostInvitePopup extends StatelessWidget {
  final String postText;
  final String userName;

  const FirstPostInvitePopup({
    super.key,
    required this.postText,
    required this.userName,
  });

  static Future<void> show(
    BuildContext context, {
    required String postText,
    required String userName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => FirstPostInvitePopup(postText: postText, userName: userName),
    );
  }

  String _buildShareText() {
    final snippet =
        postText.length > 120 ? '${postText.substring(0, 117)}...' : postText;

    // No indentation inside the string literal — each line must start at col 0
    return '$userName shared something on Micro Journal:\n\n'
        '"$snippet"\n\n'
        "It's a small app for staying close with the people who matter — "
        'one post a day, just between you and a few friends. No feed, no noise.\n\n'
        'Join my circle → [your-app-link]';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final snippet =
        postText.length > 100 ? '${postText.substring(0, 97)}...' : postText;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 28),

          Text(
            'Your first post is live.',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Who do you want to share it with?',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 24),

          // Post preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.45),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '"$snippet"',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Micro Journal works best when the people you care about are in your circle. There\'s room for up to 10 — no more.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.55,
            ),
          ),

          const SizedBox(height: 28),

          // Primary CTA
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Share.share(
                  _buildShareText(),
                  subject: 'Join my Micro Journal circle',
                );
              },
              icon: const Icon(Icons.person_add_outlined, size: 20),
              label: const Text('Invite someone'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Not now',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
