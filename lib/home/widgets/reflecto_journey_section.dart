import 'package:flutter/material.dart';
import 'package:project_micro_journal/home/models/reflecto_progress.dart';

class ReflectionJourneySection extends StatelessWidget {
  final int daysPosted;
  final GrowthStage stage;
  final int daysToNext;
  final double progressInStage;
  final bool hasPostedToday;

  const ReflectionJourneySection({
    super.key,
    required this.daysPosted,
    required this.stage,
    required this.daysToNext,
    required this.progressInStage,
    required this.hasPostedToday,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMax = daysToNext < 0;
    final nextStage = isMax ? null : GrowthStage.values[stage.index + 1];
    final accent = theme.colorScheme.primary;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    stage.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stage.label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '$daysPosted reflection${daysPosted == 1 ? '' : 's'} this month',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasPostedToday)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          size: 13,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Today',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: List.generate(GrowthStage.values.length, (i) {
                final filled = i <= stage.index;
                final isCurrent = i == stage.index;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: i == GrowthStage.values.length - 1 ? 0 : 4,
                    ),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: 0,
                        end:
                            filled
                                ? (isCurrent
                                    ? progressInStage.clamp(0.0, 1.0)
                                    : 1.0)
                                : 0.0,
                      ),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder:
                          (context, value, _) => ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Stack(
                              children: [
                                Container(
                                  height: 6,
                                  color: theme.colorScheme.outlineVariant
                                      .withOpacity(0.3),
                                ),
                                FractionallySizedBox(
                                  widthFactor: value,
                                  child: Container(height: 6, color: accent),
                                ),
                              ],
                            ),
                          ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),
            Text(
              isMax
                  ? 'Full bloom this month 🎉'
                  : '$daysToNext more to ${nextStage!.label}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
