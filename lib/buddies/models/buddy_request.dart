class BuddyRequest {
  final int id;
  final int userId;
  final String username;
  final String displayName;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  BuddyRequest({
    required this.id,
    required this.userId,
    required this.username,
    required this.displayName,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BuddyRequest.fromJson(Map<String, dynamic> json) {
    return BuddyRequest(
      id: json['id'],
      userId: json['user_id'],
      username: json['username'],
      displayName: json['display_name'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'display_name': displayName,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
