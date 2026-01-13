import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationPermissionPage extends StatelessWidget {
  final Function()? onPermissionGranted;

  const NotificationPermissionPage({super.key, this.onPermissionGranted});

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
                    // Notification Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notifications_active_outlined,
                        size: 60,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      'Stay Connected',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    Text(
                      'Enable notifications to stay up to date with your friends and never miss important updates.',
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
                      icon: Icons.people_outline,
                      title: 'Friend Updates',
                      description:
                          'Get notified when your friends share new posts',
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureCard(
                      theme,
                      icon: Icons.person_add_outlined,
                      title: 'Follow Requests',
                      description:
                          'Stay informed about new follow requests and approvals',
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureCard(
                      theme,
                      icon: Icons.favorite_outline,
                      title: 'Engagement',
                      description:
                          'Know when friends like or comment on your posts',
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
                      onPressed: () => _requestNotificationPermission(context),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Enable Notifications',
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

  Future<void> _requestNotificationPermission(BuildContext context) async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (!context.mounted) return;

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Permission granted
        onPermissionGranted?.call();
        Navigator.of(context).pop(true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notifications enabled successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        // Permission denied
        Navigator.of(context).pop(false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Notifications were not enabled. You can change this in Settings.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      Navigator.of(context).pop(false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error enabling notifications: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// Helper function to check and show notification permission page
Future<bool?> showNotificationPermissionPage(
  BuildContext context, {
  Function()? onPermissionGranted,
}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder:
          (context) => NotificationPermissionPage(
            onPermissionGranted: onPermissionGranted,
          ),
      fullscreenDialog: true,
    ),
  );
}

// Helper to check if we should show the permission page
Future<bool> shouldShowNotificationPermission() async {
  final messaging = FirebaseMessaging.instance;
  final settings = await messaging.getNotificationSettings();

  // Show page if notifications are not authorized
  return settings.authorizationStatus != AuthorizationStatus.authorized &&
      settings.authorizationStatus != AuthorizationStatus.provisional;
}
