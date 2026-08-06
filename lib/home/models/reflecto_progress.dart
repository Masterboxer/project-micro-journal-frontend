enum GrowthStage {
  seed('Seed', '🌰'),
  sprout('Sprout', '🌱'),
  sapling('Sapling', '🌿'),
  youngTree('Young Tree', '🌳'),
  bloomingTree('Blooming Tree', '🌸'),
  fullBloom('Full Bloom', '🌳✨');

  final String label;
  final String emoji;
  const GrowthStage(this.label, this.emoji);

  static GrowthStage fromString(String s) {
    switch (s) {
      case 'seed':
        return GrowthStage.seed;
      case 'sprout':
        return GrowthStage.sprout;
      case 'sapling':
        return GrowthStage.sapling;
      case 'young_tree':
        return GrowthStage.youngTree;
      case 'blooming_tree':
        return GrowthStage.bloomingTree;
      case 'full_bloom':
        return GrowthStage.fullBloom;
      default:
        return GrowthStage.seed;
    }
  }
}

class ReflectoProgress {
  final int daysPosted;
  final GrowthStage stage;
  final int daysToNext;
  final double progressInStage;
  final bool hasPostedToday;
  final String monthKey;

  ReflectoProgress({
    required this.daysPosted,
    required this.stage,
    required this.daysToNext,
    required this.progressInStage,
    required this.hasPostedToday,
    required this.monthKey,
  });

  factory ReflectoProgress.fromJson(Map<String, dynamic> json) {
    return ReflectoProgress(
      daysPosted: json['days_posted'] as int? ?? 0,
      stage: GrowthStage.fromString(json['stage'] as String? ?? 'seed'),
      daysToNext: json['days_to_next'] as int? ?? -1,
      progressInStage: (json['progress_in_stage'] as num?)?.toDouble() ?? 0.0,
      hasPostedToday: json['has_posted_today'] as bool? ?? false,
      monthKey: json['month_key'] as String? ?? '',
    );
  }
}
