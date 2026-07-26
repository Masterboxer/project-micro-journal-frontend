import 'package:flutter/material.dart';

const Map<String, String> kReactionEmojis = {
  'heart': '❤️',
  'laugh': '😂',
  'sad': '😢',
  'angry': '😠',
  'surprised': '🤯',
  'fire': '🔥',
  'clap': '👏',
  'thinking': '🤔',
  'party': '🥳',
  'cool': '😎',
};

class ReactionPicker {
  static Future<void> show(
    BuildContext context, {
    required String? currentReaction,
    required void Function(
      String reactionType,
      Offset tapPosition,
      bool isUnselecting,
    )
    onSelect,
  }) {
    final theme = Theme.of(context);
    return showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'React to this post',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children:
                        kReactionEmojis.entries.map((entry) {
                          final isSelected = currentReaction == entry.key;
                          Offset tapPosition = Offset.zero;
                          return InkWell(
                            onTapDown:
                                (details) =>
                                    tapPosition = details.globalPosition,
                            onTap: () {
                              Navigator.pop(context);
                              onSelect(entry.key, tapPosition, isSelected);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? theme.colorScheme.primaryContainer
                                        : theme.colorScheme.surfaceVariant
                                            .withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    isSelected
                                        ? Border.all(
                                          color: theme.colorScheme.primary,
                                          width: 2,
                                        )
                                        : null,
                              ),
                              child: Text(
                                entry.value,
                                style: const TextStyle(fontSize: 32),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  static void showReactionsList(BuildContext context, List<dynamic> reactions) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Reactions (${reactions.length})'),
            content:
                reactions.isEmpty
                    ? const Text('No reactions yet')
                    : SizedBox(
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: reactions.length,
                        itemBuilder: (context, index) {
                          final reaction = reactions[index];
                          return ListTile(
                            leading: Text(
                              kReactionEmojis[reaction['reaction_type']] ??
                                  '❤️',
                              style: const TextStyle(fontSize: 24),
                            ),
                            title: Text(reaction['display_name'] ?? 'Unknown'),
                            subtitle: Text(
                              '@${reaction['username'] ?? 'unknown'}',
                            ),
                          );
                        },
                      ),
                    ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}
