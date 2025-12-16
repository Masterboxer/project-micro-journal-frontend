import 'package:flutter/material.dart';

class PostTemplate {
  final String id;
  final String name;
  final String description;
  final IconData icon;

  const PostTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });

  // You can add toJson/fromJson methods for backend integration later
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'description': description};
  }

  factory PostTemplate.fromJson(Map<String, dynamic> json) {
    return PostTemplate(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      icon: Icons.text_fields, // Default icon when loading from backend
    );
  }
}
