class UserSearchResult {
  final int id;
  final String username;
  final String displayName;
  final String email;
  final bool? isFollowing;  // Current user follows this user
  final bool? isFollower;   // This user follows current user

  UserSearchResult({
    required this.id,
    required this.username,
    required this.displayName,
    required this.email,
    this.isFollowing,
    this.isFollower,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'],
      username: json['username'],
      displayName: json['display_name'],
      email: json['email'],
      isFollowing: json['is_following'],
      isFollower: json['is_follower'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'email': email,
      'is_following': isFollowing,
      'is_follower': isFollower,
    };
  }
}
