import 'package:flutter/material.dart';
import 'package:project_micro_journal/templates/template_model.dart';
import 'status_badge.dart';

/// Extracted from HomePageState._buildUserPostCard. All data (labels,
/// resolved template) is computed by HomePageState and passed in; all
/// actions are callbacks so the actual http/dialog logic stays put.
class UserPostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final PostTemplate? template;
  final String postedLabel;
  final Map<String, String> reactionEmojis;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReact;
  final VoidCallback onComment;
  final VoidCallback onViewReactions;

  const UserPostCard({
    super.key,
    required this.post,
    required this.template,
    required this.postedLabel,
    required this.reactionEmojis,
    required this.onEdit,
    required this.onDelete,
    required this.onReact,
    required this.onComment,
    required this.onViewReactions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = template?.name ?? 'Reflection';
    final commentCount = post['comment_count'] as int;
    final totalReactions = post['total_reactions'] as int? ?? 0;
    final userReaction = post['user_reaction'] as String?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  template?.iconData ?? Icons.help_outline,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: theme.colorScheme.primary.withOpacity(0.7),
                  ),
                  tooltip: 'Edit post',
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: theme.colorScheme.error.withOpacity(0.7),
                  ),
                  tooltip: 'Delete post',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                StatusBadge(
                  icon: Icons.schedule,
                  label: postedLabel,
                  background: theme.colorScheme.surfaceVariant,
                  foreground: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(post['text'], style: theme.textTheme.bodyLarge),
            const SizedBox(height: 12),
            const Divider(),
            _PostActionsRow(
              userReaction: userReaction,
              totalReactions: totalReactions,
              commentCount: commentCount,
              reactionEmojis: reactionEmojis,
              onReact: onReact,
              onComment: onComment,
              onViewReactions: onViewReactions,
            ),
          ],
        ),
      ),
    );
  }
}

/// Extracted from HomePageState._buildFriendPostCard.
class FriendPostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final PostTemplate? template;
  final String expirationLabel;
  final Map<String, String> reactionEmojis;
  final VoidCallback onTapAvatar;
  final VoidCallback onReact;
  final VoidCallback onComment;
  final VoidCallback onViewReactions;

  const FriendPostCard({
    super.key,
    required this.post,
    required this.template,
    required this.expirationLabel,
    required this.reactionEmojis,
    required this.onTapAvatar,
    required this.onReact,
    required this.onComment,
    required this.onViewReactions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userName = post['userName'] ?? 'Friend';
    final commentCount = post['comment_count'] as int;
    final totalReactions = post['total_reactions'] as int? ?? 0;
    final userReaction = post['user_reaction'] as String?;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onTapAvatar,
              child: Row(
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
                          expirationLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
                      template!.iconData,
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
            const SizedBox(height: 12),
            const Divider(),
            _PostActionsRow(
              userReaction: userReaction,
              totalReactions: totalReactions,
              commentCount: commentCount,
              reactionEmojis: reactionEmojis,
              onReact: onReact,
              onComment: onComment,
              onViewReactions: onViewReactions,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared reaction/comment row used by both card types — was duplicated
/// verbatim in the original file, so this also removes that duplication.
class _PostActionsRow extends StatelessWidget {
  final String? userReaction;
  final int totalReactions;
  final int commentCount;
  final Map<String, String> reactionEmojis;
  final VoidCallback onReact;
  final VoidCallback onComment;
  final VoidCallback onViewReactions;

  const _PostActionsRow({
    required this.userReaction,
    required this.totalReactions,
    required this.commentCount,
    required this.reactionEmojis,
    required this.onReact,
    required this.onComment,
    required this.onViewReactions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        InkWell(
          onTap: onReact,
          onLongPress: onReact,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                if (userReaction != null)
                  Text(
                    reactionEmojis[userReaction]!,
                    style: const TextStyle(fontSize: 20),
                  )
                else
                  Icon(
                    Icons.favorite_border,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                const SizedBox(width: 4),
                Text('$totalReactions', style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        InkWell(
          onTap: onComment,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.comment_outlined,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text('$commentCount', style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ),
        const Spacer(),
        if (totalReactions > 0)
          TextButton(
            onPressed: onViewReactions,
            child: const Text('View Reactions'),
          ),
      ],
    );
  }
}
