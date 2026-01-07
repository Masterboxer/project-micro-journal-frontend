class FollowStats {
  final int followersCount;
  final int followingCount;

  FollowStats({
    required this.followersCount,
    required this.followingCount,
  });

  factory FollowStats.fromJson(Map<String, dynamic> json) {
    return FollowStats(
      followersCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'followers_count': followersCount,
      'following_count': followingCount,
    };
  }
}
