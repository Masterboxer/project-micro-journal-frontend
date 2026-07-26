import 'package:flutter/material.dart';
import 'score_rows.dart';

class ReflectoScoreSection extends StatelessWidget {
  final int score;
  final bool hasPostedToday;

  const ReflectoScoreSection({
    super.key,
    required this.score,
    required this.hasPostedToday,
  });

  ({String label, Color color, IconData icon}) _tierFor(
    ThemeData theme,
    int score,
  ) {
    if (score >= 100) {
      return (
        label: 'Legend',
        color: const Color(0xFFFFD700),
        icon: Icons.auto_awesome,
      );
    } else if (score >= 50) {
      return (
        label: 'Pro',
        color: const Color(0xFF9C27B0),
        icon: Icons.workspace_premium,
      );
    } else if (score >= 20) {
      return (
        label: 'Rising',
        color: const Color(0xFF2196F3),
        icon: Icons.trending_up,
      );
    }
    return (
      label: 'Starter',
      color: theme.colorScheme.primary,
      icon: Icons.star_outline,
    );
  }

  DateTime _nextDeadline() {
    final now = DateTime.now();
    if (now.hour < 12) {
      return DateTime(now.year, now.month, now.day, 12, 0, 0);
    }
    final tomorrow = now.add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 12, 0, 0);
  }

  Duration _timeUntilDeadline() {
    return _nextDeadline().difference(DateTime.now());
  }

  String _formatTimeUntilDeadline() {
    final d = _timeUntilDeadline();
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  void _showScoringCriteriaSheet(BuildContext context) {
    final theme = Theme.of(context);
    final tier = _tierFor(theme, score);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: tier.color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(tier.icon, color: tier.color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How your score is calculated',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'You\'re ${tier.label} tier · $score pts',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: tier.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ScoreRow(
                emoji: '✍️',
                label: 'Create a post',
                points: '+5 pts',
                color: Colors.green,
                theme: theme,
              ),
              const SizedBox(height: 12),
              ScoreRow(
                emoji: '💬',
                label: 'Leave a comment',
                points: '+2 pts',
                color: Colors.blue,
                theme: theme,
              ),
              const SizedBox(height: 12),
              ScoreRow(
                emoji: '❤️',
                label: 'React to a post',
                points: '+1 pt',
                color: Colors.red,
                theme: theme,
              ),
              const SizedBox(height: 12),
              ScoreRow(
                emoji: '🌙',
                label: 'Miss a day',
                points: '-1 pt',
                color: Colors.grey,
                theme: theme,
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 54),
                child: Text(
                  'Score Decay keeps your posting habit strong, and helps you spot which friends are still active.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Divider(color: theme.colorScheme.outlineVariant),
              const SizedBox(height: 16),
              Text(
                'Tiers',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TierRow(
                icon: Icons.star_outline,
                label: 'Starter',
                range: '0–19 pts',
                color: theme.colorScheme.primary,
                theme: theme,
              ),
              const SizedBox(height: 8),
              TierRow(
                icon: Icons.trending_up,
                label: 'Rising',
                range: '20–49 pts',
                color: const Color(0xFF2196F3),
                theme: theme,
              ),
              const SizedBox(height: 8),
              TierRow(
                icon: Icons.workspace_premium,
                label: 'Pro',
                range: '50–99 pts',
                color: const Color(0xFF9C27B0),
                theme: theme,
              ),
              const SizedBox(height: 8),
              TierRow(
                icon: Icons.auto_awesome,
                label: 'Legend',
                range: '100+ pts',
                color: const Color(0xFFFFD700),
                theme: theme,
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeLeft = _formatTimeUntilDeadline();
    final hoursLeft = _timeUntilDeadline().inHours;
    final tier = _tierFor(theme, score);

    final Color freshnessBg;
    final Color freshnessText;
    final IconData freshnessIcon;
    final String freshnessLabel;

    if (hasPostedToday) {
      freshnessBg = Colors.green.withOpacity(0.12);
      freshnessText = Colors.green.shade700;
      freshnessIcon = Icons.check_circle_outline_rounded;
      freshnessLabel = 'Post Created Today ✓';
    } else if (hoursLeft <= 3) {
      freshnessBg = Colors.red.withOpacity(0.10);
      freshnessText = Colors.red.shade700;
      freshnessIcon = Icons.timer_outlined;
      freshnessLabel = 'Post soon — $timeLeft left today';
    } else {
      freshnessBg = Colors.orange.withOpacity(0.10);
      freshnessText = Colors.orange.shade800;
      freshnessIcon = Icons.hourglass_bottom_rounded;
      freshnessLabel = '$timeLeft left to maintain your Reflecto Score';
    }

    return GestureDetector(
      onTap: () => _showScoringCriteriaSheet(context),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tier.color.withOpacity(0.25), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          tier.color.withOpacity(0.25),
                          tier.color.withOpacity(0.06),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(tier.icon, color: tier.color, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reflecto Score',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$score',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: tier.color,
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: tier.color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                tier.label,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: tier.color,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: freshnessBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(freshnessIcon, size: 14, color: freshnessText),
                    const SizedBox(width: 8),
                    Text(
                      freshnessLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: freshnessText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
