import 'package:flutter/material.dart';

class PostTemplate {
  final int id;
  final String name;
  final String description;
  final String icon;
  final DateTime createdAt;

  PostTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.createdAt,
  });

  factory PostTemplate.fromJson(Map<String, dynamic> json) {
    return PostTemplate(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'created_at': createdAt.toIso8601String(),
    };
  }

  IconData get iconData {
    try {
      final codePoint = int.parse(icon, radix: 16);
      return IconData(codePoint, fontFamily: 'MaterialIcons');
    } catch (e) {
      return const IconData(0xe88a, fontFamily: 'MaterialIcons');
    }
  }
}
