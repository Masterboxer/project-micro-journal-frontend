class FollowStats {
  final int followersCount;
  final int followingCount;
  final int pendingRequestsCount;

  FollowStats({
    required this.followersCount,
    required this.followingCount,
    this.pendingRequestsCount = 0,
  });

  factory FollowStats.fromJson(Map<String, dynamic> json) {
    return FollowStats(
      followersCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
      pendingRequestsCount: json['pending_requests_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'followers_count': followersCount,
      'following_count': followingCount,
      'pending_requests_count': pendingRequestsCount,
    };
  }
}
