class UserSearchResult {
  final int id;
  final String username;
  final String displayName;
  final String email;
  final bool isPrivate;
  final bool? isFollowing;
  final bool? isFollower;
  final bool? followRequestSent;
  final String? followStatus; // "none", "pending", "accepted", "rejected"

  UserSearchResult({
    required this.id,
    required this.username,
    required this.displayName,
    required this.email,
    this.isPrivate = false,
    this.isFollowing,
    this.isFollower,
    this.followRequestSent,
    this.followStatus,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'],
      username: json['username'],
      displayName: json['display_name'],
      email: json['email'],
      isPrivate: json['is_private'] ?? false,
      isFollowing: json['is_following'],
      isFollower: json['is_follower'],
      followRequestSent: json['follow_request_sent'],
      followStatus: json['follow_status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'email': email,
      'is_private': isPrivate,
      'is_following': isFollowing,
      'is_follower': isFollower,
      'follow_request_sent': followRequestSent,
      'follow_status': followStatus,
    };
  }
}
