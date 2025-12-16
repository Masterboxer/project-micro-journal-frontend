import 'package:flutter/material.dart';
import 'package:project_micro_journal/posts/pages/create_post_page.dart';
import 'package:project_micro_journal/templates/template_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TemplateService _templateService = TemplateService.instance;

  Map<String, dynamic>? _todayPost;

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

  @override
  void initState() {
    super.initState();
    _loadTodayPost();
  }

  Future<void> _loadTodayPost() async {
    // TODO: Load today's post from backend/local DB
    // Check if user has already posted today
    // setState(() {
    //   _todayPost = fetchedPost;
    // });
  }

  Future<void> _createNewPost() async {
    // Navigate to create post page and wait for result
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const CreatePostPage()),
    );

    // If post was created, update the UI
    if (result != null) {
      setState(() {
        _todayPost = result;
      });
    }
  }

  Future<void> _refreshPosts() async {
    // TODO: Refresh posts from backend
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      // Reload data
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Micro Journal'),
        centerTitle: false,
        actions: [
          if (_todayPost == null)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _createNewPost,
              tooltip: 'Create today\'s post',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        child:
            _todayPost == null
                ? _buildEmptyState(theme)
                : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 3 + _friendsPosts.length,
                  itemBuilder: (context, index) {
                    // "Today's Post" header
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

                    // Today's post card
                    if (index == 1) {
                      return _buildTodayPostCard(theme, _todayPost!);
                    }

                    // "Friends Activity" header
                    if (index == 2) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 24, bottom: 16),
                        child: Text(
                          'Friends Activity',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }

                    // Friends' posts
                    final friendPostIndex = index - 3;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildFriendPostCard(
                        theme,
                        _friendsPosts[friendPostIndex],
                      ),
                    );
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

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.edit_note_outlined,
              size: 80,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No post yet today',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Share your thoughts and reflections for today',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _createNewPost,
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Post'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayPostCard(ThemeData theme, Map<String, dynamic> post) {
    // Get template details from service
    final templateId = post['templateId'] as String?;
    final template =
        templateId != null
            ? _templateService.getTemplateById(templateId)
            : null;

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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (template != null) ...[
                    Icon(
                      template.icon,
                      size: 16,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    post['template'],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(post['text'], style: theme.textTheme.bodyLarge),
            // ... rest of your existing card code ...
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
            Text(post['text'], style: theme.textTheme.bodyMedium),
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
