class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String username;
  final String displayName;
  final String email; // add this

  LoginResponse.fromJson(Map<String, dynamic> json)
    : accessToken = json['access_token'],
      refreshToken = json['refresh_token'],
      userId = json['user_id'],
      username = json['username'],
      displayName = json['display_name'],
      email = json['email'] ?? '';
}
