class PersonalStreak {
  final int id;
  final int userId;
  final int streakCount;
  final String? lastPostDate;
  final int longestStreak;
  final DateTime startedAt;
  final DateTime updatedAt;

  PersonalStreak({
    required this.id,
    required this.userId,
    required this.streakCount,
    this.lastPostDate,
    required this.longestStreak,
    required this.startedAt,
    required this.updatedAt,
  });

  factory PersonalStreak.fromJson(Map<String, dynamic> json) {
    return PersonalStreak(
      id: json['id'],
      userId: json['user_id'],
      streakCount: json['streak_count'],
      lastPostDate: json['last_post_date'],
      longestStreak: json['longest_streak'],
      startedAt: DateTime.parse(json['started_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
