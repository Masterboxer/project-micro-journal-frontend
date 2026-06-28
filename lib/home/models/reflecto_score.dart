class ReflectoScore {
  final int score;

  const ReflectoScore({required this.score});

  factory ReflectoScore.fromJson(Map<String, dynamic> json) {
    return ReflectoScore(score: json['score'] as int? ?? 0);
  }
}
