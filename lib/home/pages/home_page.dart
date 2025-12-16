import 'package:flutter/material.dart';
import 'package:project_micro_journal/posts/pages/create_post_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Mock data - replace with actual data from backend/DB
  final Map<String, dynamic>? _todayPost = {
    'template': 'What went well today?',
    'text':
        'What went well today? Had a productive meeting and learned Flutter!',
    'photoPath': 'mock_photo.jpg',
    'timestamp': DateTime.now(),
  };

  // Mock friends' posts - fetch from backend
  final List<Map<String, dynamic>> _friendsPosts = [
    {
      'userName': 'Sarah Johnson',
      'userAvatar': 'assets/avatar1.jpg',
      'template': 'Grateful for:',
      'text': 'Grateful for: My supportive team and sunny weather today',
      'photoPath': null,
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
    },
    {
      'userName': 'Mike Chen',
      'userAvatar': 'assets/avatar2.jpg',
      'template': 'One thing to improve tomorrow:',
      'text': 'One thing to improve tomorrow: Better time management',
      'photoPath': 'mock_photo2.jpg',
      'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
    },
    {
      'userName': 'Emily Davis',
      'userAvatar': 'assets/avatar3.jpg',
      'template': 'What went well today?',
      'text': 'What went well today? Finished my project ahead of schedule!',
      'photoPath': null,
      'timestamp': DateTime.now().subtract(const Duration(hours: 8)),
    },
  ];

  void _createNewPost() {
    // Navigate to create post page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreatePostPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Micro Journal'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _createNewPost,
            tooltip: 'Create new post',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: Refresh posts from backend
          await Future.delayed(const Duration(seconds: 1));
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 1 + (_todayPost != null ? 1 : 0) + _friendsPosts.length,
          itemBuilder: (context, index) {
            // Section header
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  "Today's Post",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }

            // Today's post (pinned at top)
            if (_todayPost != null && index == 1) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTodayPostCard(theme, _todayPost!),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Friends Activity',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            }

            // Friends' posts
            final friendPostIndex = index - (_todayPost != null ? 2 : 1);
            if (friendPostIndex < _friendsPosts.length) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildFriendPostCard(
                  theme,
                  _friendsPosts[friendPostIndex],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
      floatingActionButton:
          _todayPost == null
              ? FloatingActionButton.extended(
                onPressed: _createNewPost,
                icon: const Icon(Icons.edit),
                label: const Text('Create Today\'s Post'),
              )
              : null,
    );
  }

  Widget _buildTodayPostCard(ThemeData theme, Map<String, dynamic> post) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "Your Post" indicator
            Row(
              children: [
                Icon(Icons.person, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Your Post',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'Today',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Template tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                post['template'],
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Post text
            Text(post['text'], style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),

            // Photo indicator
            if (post['photoPath'] != null)
              Row(
                children: [
                  Icon(
                    Icons.photo,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Photo attached',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 8),

            // Note about editing
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Posts cannot be edited after submission',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendPostCard(ThemeData theme, Map<String, dynamic> post) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    post['userName'][0],
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['userName'],
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatTimestamp(post['timestamp']),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Template tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                post['template'],
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Post text
            Text(post['text'], style: theme.textTheme.bodyMedium),

            // Photo indicator
            if (post['photoPath'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.photo,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Photo attached',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
