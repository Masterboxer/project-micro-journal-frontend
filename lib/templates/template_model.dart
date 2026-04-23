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

  static const Map<String, IconData> _iconMap = {
    'home': Icons.home,
    'sentiment_satisfied': Icons.sentiment_satisfied,
    'emoji_events': Icons.emoji_events,
    'flash_on': Icons.flash_on,
    'bookmark': Icons.bookmark,
    'favorite': Icons.favorite,
    'flag': Icons.flag,
    'lightbulb': Icons.lightbulb,
  };

  IconData get iconData {
    return _iconMap[icon] ?? Icons.help;
  }
}
