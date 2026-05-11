class SignupResponse {
  final int id;
  final String username;
  final String displayName;
  final String dob;
  final String gender;
  final String email;
  final bool isPrivate;
  final DateTime createdAt;

  SignupResponse({
    required this.id,
    required this.username,
    required this.displayName,
    required this.dob,
    required this.gender,
    required this.email,
    required this.isPrivate,
    required this.createdAt,
  });

  factory SignupResponse.fromJson(Map<String, dynamic> json) {
    return SignupResponse(
      id: json['id'],
      username: json['username'],
      displayName: json['display_name'],
      dob: json['dob'],
      gender: json['gender'],
      email: json['email'],
      isPrivate: json['is_private'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'dob': dob,
      'gender': gender,
      'email': email,
      'is_private': isPrivate,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
