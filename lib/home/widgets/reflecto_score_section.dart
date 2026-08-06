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

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.9, end: 1.0),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                  builder:
                      (context, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                  child: Text(
                    stage.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Reflection Journey',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$daysPosted reflection${daysPosted == 1 ? '' : 's'} this month',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              stage.label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progressInStage.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder:
                    (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: theme.colorScheme.outlineVariant
                          .withOpacity(0.3),
                      color: theme.colorScheme.primary,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isMax
                  ? 'Full bloom this month 🎉'
                  : '$daysToNext more reflection${daysToNext == 1 ? '' : 's'} until ${nextStage!.label}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (hasPostedToday)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 14,
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Reflected today',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
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
}
