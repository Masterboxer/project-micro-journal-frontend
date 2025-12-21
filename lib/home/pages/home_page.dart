import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:project_micro_journal/authentication/services/authentication_token_storage_service.dart';
import 'package:project_micro_journal/environment/development.dart';
import 'package:project_micro_journal/posts/pages/create_post_page.dart';
import 'package:project_micro_journal/templates/template_model.dart';
import 'package:project_micro_journal/templates/template_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TemplateService _templateService = TemplateService.instance;
  final AuthenticationTokenStorageService _authStorage =
      AuthenticationTokenStorageService();

  Map<String, dynamic>? _todayPost;
  List<Map<String, dynamic>> _friendsPosts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    _error = null;

    try {
      await _templateService.fetchTemplatesFromBackend();
      await _loadFeed();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadFeed() async {
    try {
      final String? userId = await _authStorage.getUserId();
      if (userId == null) return;

      final response = await http.get(
        Uri.parse('${Environment.baseUrl}posts/$userId/feed'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> feedData = json.decode(response.body);

        if (mounted) {
          setState(() {
            if (feedData.isNotEmpty) {
              final firstPost = feedData[0];
              _todayPost = {
                'id': firstPost['id'],
                'user_id': firstPost['user_id'],
                'templateId': firstPost['template_id'],
                'text': firstPost['text'],
                'photoPath': firstPost['photo_path'],
                'timestamp': DateTime.parse(firstPost['created_at']),
                'userName': firstPost['display_name'] ?? 'You',
              };

              _friendsPosts =
                  feedData.length > 1
                      ? feedData
                          .sublist(1)
                          .map(
                            (post) => {
                              'id': post['id'],
                              'user_id': post['user_id'],
                              'templateId': post['template_id'],
                              'text': post['text'],
                              'photoPath': post['photo_path'],
                              'timestamp': DateTime.parse(post['created_at']),
                              'userName':
                                  post['display_name'] ??
                                  post['username'] ??
                                  'Friend',
                            },
                          )
                          .toList()
                      : [];
            } else {
              _todayPost = null;
              _friendsPosts = [];
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _todayPost = null;
        _friendsPosts = [];
      }
    }
  }

  Future<void> _createNewPost() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const CreatePostPage()),
    );

    if (result != null && mounted) {
      await _loadFeed();
    }
  }

  Future<void> _refreshPosts() async {
    await _initializeData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text('Failed to load feed', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(_error!, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _initializeData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        child:
            _todayPost == null
                ? _buildEmptyState(theme)
                : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount:
                      _friendsPosts.isEmpty ? 2 : 3 + _friendsPosts.length,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          "Your Post",
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }

                    if (index == 1) {
                      return _buildTodayPostCard(theme, _todayPost!);
                    }

                    if (_friendsPosts.isNotEmpty && index == 2) {
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

                    final friendIndex = index - 3;
                    if (friendIndex < _friendsPosts.length) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildFriendPostCard(
                          theme,
                          _friendsPosts[friendIndex],
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
    final templateId = post['templateId'] as int?;
    PostTemplate? template =
        templateId != null
            ? _templateService.getTemplateById(templateId)
            : null;

    final displayName = template?.name;

    return Card(
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
                      template.iconData,
                      size: 16,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 6),
                  ] else ...[
                    Icon(
                      Icons.help_outline,
                      size: 16,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      displayName ?? "Unknown Template",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(post['text'], style: theme.textTheme.bodyLarge),
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
            const SizedBox(height: 12),
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
                  Expanded(
                    child: Text(
                      'Posts cannot be edited after submission',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
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
    final templateId = post['templateId'] as int?;
    final template =
        templateId != null
            ? _templateService.getTemplateById(templateId)
            : null;
    final userName = post['userName'] ?? 'Friend';

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
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
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
                        userName,
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (template != null) ...[
                    Icon(
                      template.iconData,
                      size: 16,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      template?.name ?? 'Unknown template',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(post['text'], style: theme.textTheme.bodyMedium),
            if (post['photoPath'] != null &&
                post['photoPath'].toString().isNotEmpty) ...[
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
