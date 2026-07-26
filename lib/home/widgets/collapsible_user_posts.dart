import 'package:flutter/material.dart';

class CollapsibleUserPosts extends StatefulWidget {
  final List<Map<String, dynamic>> posts;
  final Widget Function(Map<String, dynamic> post) buildCard;
  final ThemeData theme;

  const CollapsibleUserPosts({
    super.key,
    required this.posts,
    required this.buildCard,
    required this.theme,
  });

  @override
  State<CollapsibleUserPosts> createState() => _CollapsibleUserPostsState();
}

class _CollapsibleUserPostsState extends State<CollapsibleUserPosts> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Your Posts (${widget.posts.length})',
                    style: widget.theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: widget.theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: widget.theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: [
              const SizedBox(height: 12),
              ...widget.posts.map(
                (post) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: widget.buildCard(post),
                ),
              ),
            ],
          ),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }
}
