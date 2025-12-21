class UserSearchResult {
  final int id;
  final String username;
  final String displayName;
  final String? email;
  final DateTime createdAt;

  UserSearchResult({
    required this.id,
    required this.username,
    required this.displayName,
    this.email,
    required this.createdAt,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'],
      username: json['username'],
      displayName: json['display_name'],
      email: json['email'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
