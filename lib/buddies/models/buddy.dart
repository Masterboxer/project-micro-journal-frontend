class Buddy {
  final int id;
  final String username;
  final String displayName;

  Buddy({required this.id, required this.username, required this.displayName});

  factory Buddy.fromJson(Map<String, dynamic> json) {
    return Buddy(
      id: json['id'],
      username: json['username'],
      displayName: json['display_name'],
    );
  }
}
