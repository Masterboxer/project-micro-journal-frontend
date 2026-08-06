import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_micro_journal/home/models/reflecto_progress.dart';
import 'stage_up_celebration.dart';

class ReflectionJourneySection extends StatefulWidget {
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
  State<ReflectionJourneySection> createState() =>
      _ReflectionJourneySectionState();
}

class _ReflectionJourneySectionState extends State<ReflectionJourneySection> {
  static const List<int> _stageThresholds = [3, 7, 13, 19, 25];
  static const double _totalSpan = 25.0;

  @override
  void didUpdateWidget(covariant ReflectionJourneySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stage.index > oldWidget.stage.index) {
      HapticFeedback.mediumImpact();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        StageUpCelebration.show(
          context,
          stageLabel: widget.stage.label,
          icon: widget.stage.icon,
        );
      });
    }
  }

  void _showJourneyInfoSheet(BuildContext context) {
    final theme = Theme.of(context);
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
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.stage.icon,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Reflection Journey',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'You\'re at ${widget.stage.label} · ${widget.daysPosted} this month',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Post once a day to grow your tree. It resets each month — post 25 of 30 days to reach Full Bloom.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Divider(color: theme.colorScheme.outlineVariant),
              const SizedBox(height: 12),
              ...List.generate(GrowthStage.values.length, (i) {
                final s = GrowthStage.values[i];
                final minDay = i == 0 ? 0 : _stageThresholds[i - 1];
                final isCurrent = s == widget.stage;
                final isReached = widget.daysPosted >= minDay;
                final rangeLabel =
                    i == GrowthStage.values.length - 1
                        ? '$minDay+ days'
                        : '$minDay–${_stageThresholds[i] - 1} days';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color:
                              isReached
                                  ? theme.colorScheme.primary.withOpacity(
                                    isCurrent ? 0.18 : 0.10,
                                  )
                                  : theme.colorScheme.outlineVariant
                                      .withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          s.icon,
                          size: 17,
                          color:
                              isReached
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant
                                      .withOpacity(0.4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          s.label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight:
                                isCurrent ? FontWeight.w700 : FontWeight.w500,
                            color:
                                isReached
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurfaceVariant
                                        .withOpacity(0.5),
                          ),
                        ),
                      ),
                      Text(
                        rangeLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMax = widget.daysToNext < 0;
    final nextStage = isMax ? null : GrowthStage.values[widget.stage.index + 1];
    final accent = theme.colorScheme.primary;
    final fillFraction = (widget.daysPosted / _totalSpan).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => _showJourneyInfoSheet(context),
      child: Card(
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
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.85, end: 1.0),
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.elasticOut,
                    builder:
                        (context, scale, child) =>
                            Transform.scale(scale: scale, child: child),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(widget.stage.icon, color: accent, size: 21),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.stage.label,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${widget.daysPosted} reflection${widget.daysPosted == 1 ? '' : 's'} this month',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.hasPostedToday)
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
                    )
                  else
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.4,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 14,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    return Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            height: 10,
                            width: width,
                            color: theme.colorScheme.outlineVariant.withOpacity(
                              0.3,
                            ),
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: fillFraction),
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeOutCubic,
                            builder:
                                (context, value, _) => Container(
                                  height: 10,
                                  width: width * value,
                                  color: accent,
                                ),
                          ),
                        ),
                        ..._stageThresholds.map((day) {
                          final f = day / _totalSpan;
                          final left = (width * f - 3).clamp(0.0, width - 6.0);
                          final cleared = widget.daysPosted >= day;
                          return Positioned(
                            left: left,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: cleared ? 1.0 : 0.0),
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.elasticOut,
                              builder:
                                  (context, t, _) => Container(
                                    width: 6 + (2 * t),
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color:
                                          cleared
                                              ? theme
                                                  .colorScheme
                                                  .surfaceContainerLow
                                              : theme
                                                  .colorScheme
                                                  .surfaceContainerLow
                                                  .withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(3),
                                      border:
                                          cleared
                                              ? Border.all(
                                                color: accent.withOpacity(0.5),
                                                width: 1,
                                              )
                                              : null,
                                    ),
                                  ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isMax
                    ? 'Full bloom this month 🎉'
                    : '${widget.daysToNext} more reflection${widget.daysToNext == 1 ? '' : 's'} to ${nextStage!.label}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
