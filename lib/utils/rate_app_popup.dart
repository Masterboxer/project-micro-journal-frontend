import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class RateAppPopup {
  static const _kPostCountKey = 'total_post_count';
  static const _kHasRatedKey = 'has_rated_or_dismissed';

  static Future<void> onPostCreated(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getBool(_kHasRatedKey) ?? false) return;

    final count = (prefs.getInt(_kPostCountKey) ?? 0) + 1;

    await prefs.setInt(_kPostCountKey, count);

    if (count == 3) {
      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const _RateAppDialog(),
        );
      }
    }
  }
}

class _RateAppDialog extends StatelessWidget {
  const _RateAppDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? const Color(0xFF1E2A38)
                            : const Color(0xFFE8F4FD),
                    shape: BoxShape.circle,
                  ),
                ),
                const Text('⭐', style: TextStyle(fontSize: 36)),
              ],
            ),

            const SizedBox(height: 20),

            Text(
              'Hey, it\'s Sriharish here',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 14),

            Text(
              'Okay, real talk — this is my very first app. '
              'I built this thing fuelled by caffeine, Stack Overflow, '
              'and a concerning amount of optimism.\n\n'
              'You\'ve just made your 3rd post. THREE! '
              'That means you\'re actually using it, which honestly '
              'made my day. 🥹\n\n'
              'If Micro Journal has been even a tiny bit useful to you, '
              'a rating on the App Store would mean the absolute world '
              'to me. It takes 10 seconds and it\'ll keep me going '
              'through the next 3 AM bug fix. 🙏',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('has_rated_or_dismissed', true);

                  const storeUrl =
                      'https://play.google.com/store/apps/details?id=com.masterboxer.reflecto';
                  final uri = Uri.parse(storeUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.star_rounded),
                label: const Text('Sure, I\'ll rate it! ⭐'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setInt('total_post_count', 0);
                },
                child: Text(
                  'Maybe later (no hard feelings 😅)',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ),
            ),

            GestureDetector(
              onTap: () async {
                Navigator.of(context).pop();
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('has_rated_or_dismissed', true);
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Don\'t ask again',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.55),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
