import 'package:flutter/material.dart';
import 'package:project_micro_journal/posts/pages/create_post_page.dart';
import 'package:project_micro_journal/utils/app_navigator.dart';

class MicroJournalingHabitPage extends StatelessWidget {
  const MicroJournalingHabitPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Journal Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_stories_outlined,
                        size: 60,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      'Build Your Daily Habit',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    Text(
                      'Micro journaling is about consistency, not perfection. Share a quick moment from your day so your friends can stay connected to your journey.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Feature Cards
                    _buildFeatureCard(
                      theme,
                      icon: Icons.calendar_today_outlined,
                      title: 'Daily Ritual',
                      description:
                          'Build a meaningful habit by sharing one moment each day',
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureCard(
                      theme,
                      icon: Icons.favorite_outline,
                      title: 'Stay Connected',
                      description:
                          'Let friends know you\'re doing well and what\'s happening in your life',
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureCard(
                      theme,
                      icon: Icons.psychology_outlined,
                      title: 'Track Your Journey',
                      description:
                          'Look back and see how you\'ve grown, one day at a time',
                    ),
                  ],
                ),
              ),

              // Action Buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        // Close habit page
                        Navigator.of(context).pop();

                        // Navigate to create post page
                        await appNavigatorKey.currentState?.push(
                          MaterialPageRoute(
                            builder: (_) => const CreatePostPage(),
                            fullscreenDialog: true,
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Post Today\'s Moment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Maybe Later',
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper function to show the micro journaling habit page
Future<bool?> showMicroJournalingHabitPage(BuildContext context) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (context) => const MicroJournalingHabitPage(),
      fullscreenDialog: true,
    ),
  );
}
