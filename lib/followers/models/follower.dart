class Follower {
  final int id;
  final String username;
  final String displayName;
  final DateTime followedAt;

  Follower({
    required this.id,
    required this.username,
    required this.displayName,
    required this.followedAt,
  });

  factory Follower.fromJson(Map<String, dynamic> json) {
    return Follower(
      id: json['id'],
      username: json['username'],
      displayName: json['display_name'],
      followedAt: DateTime.parse(json['followed_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'followed_at': followedAt.toIso8601String(),
    };
  }
}
