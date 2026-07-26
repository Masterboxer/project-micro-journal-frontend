import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:project_micro_journal/environment/development.dart';

class CommentsBottomSheet extends StatefulWidget {
  final int postId;
  final int currentUserId;
  final VoidCallback onCommentAdded;

  const CommentsBottomSheet({
    super.key,
    required this.postId,
    required this.currentUserId,
    required this.onCommentAdded,
  });

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${Environment.baseUrl}posts/${widget.postId}/comments?user_id=${widget.currentUserId}',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dynamic responseBody = json.decode(response.body);
        List<Map<String, dynamic>> commentsData;
        if (responseBody == null) {
          commentsData = [];
        } else if (responseBody is List) {
          commentsData = responseBody.cast<Map<String, dynamic>>();
        } else {
          commentsData = [];
        }
        if (mounted) {
          setState(() {
            _comments = commentsData;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _comments = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _comments = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading comments: $e')));
      }
    }
  }

  Future<void> _likeComment(int commentId) async {
    try {
      final response = await http.post(
        Uri.parse('${Environment.baseUrl}comments/$commentId/like'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': widget.currentUserId}),
      );
      if (response.statusCode == 200) {
        await _loadComments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteComment(int commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Comment'),
            content: const Text('Delete this comment?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm != true || !mounted) return;

    try {
      final response = await http.delete(
        Uri.parse('${Environment.baseUrl}comments/$commentId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': widget.currentUserId}),
      );
      if (response.statusCode == 200) {
        await _loadComments();
        widget.onCommentAdded();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSending = true);

    try {
      final response = await http.post(
        Uri.parse('${Environment.baseUrl}posts/${widget.postId}/comments'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.currentUserId,
          'text': _commentController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        _commentController.clear();
        await _loadComments();
        widget.onCommentAdded();
        if (mounted) FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error posting comment: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Comments (${_comments.length})',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _comments.isEmpty
                      ? SingleChildScrollView(
                        controller: scrollController,
                        child: SizedBox(
                          height: 280,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.comment_outlined,
                                  size: 64,
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No comments yet',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Be the first to comment!',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      : ListView.builder(
                        controller: scrollController,
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          final isOwner =
                              (comment['user_id'] as int) ==
                              widget.currentUserId;
                          final likeCount = comment['like_count'] as int? ?? 0;
                          final userLiked =
                              comment['user_liked'] as bool? ?? false;

                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                (comment['display_name'] ?? 'U')[0]
                                    .toUpperCase(),
                              ),
                            ),
                            title: Text(
                              comment['display_name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(comment['text']),
                                const SizedBox(height: 4),
                                Text(
                                  _formatCommentTime(comment['created_at']),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (likeCount > 0 && isOwner)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.favorite,
                                          size: 16,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '$likeCount',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                if (!isOwner)
                                  InkWell(
                                    onTap:
                                        () =>
                                            _likeComment(comment['id'] as int),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            userLiked
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            size: 16,
                                            color:
                                                userLiked
                                                    ? Colors.red
                                                    : theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                          ),
                                          if (likeCount > 0) ...[
                                            const SizedBox(width: 3),
                                            Text(
                                              '$likeCount',
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                if (isOwner)
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: theme.colorScheme.error
                                          .withOpacity(0.7),
                                    ),
                                    onPressed:
                                        () => _deleteComment(
                                          comment['id'] as int,
                                        ),
                                    tooltip: 'Delete comment',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
            const Divider(height: 1),
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      maxLength: 500,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Write a comment...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isSending ? null : _postComment,
                    icon:
                        _isSending
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatCommentTime(String timestamp) {
    final DateTime dateTime = DateTime.parse(timestamp);
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
