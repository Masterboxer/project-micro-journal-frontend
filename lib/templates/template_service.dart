import 'package:flutter/material.dart';

import 'template_model.dart';

class TemplateService {
  // Private constructor
  TemplateService._privateConstructor();

  // Single instance
  static final TemplateService _instance =
      TemplateService._privateConstructor();

  // Factory constructor returns the same instance
  factory TemplateService() {
    return _instance;
  }

  // Getter for the singleton instance
  static TemplateService get instance => _instance;

  // Template list - this will be replaced with backend data in the future
  final List<PostTemplate> _templates = const [
    PostTemplate(
      id: 'template_001',
      name: 'What went well today?',
      description: 'Reflect on positive moments and achievements',
      icon: Icons.celebration,
    ),
    PostTemplate(
      id: 'template_002',
      name: 'One thing to improve tomorrow:',
      description: 'Identify areas for growth and development',
      icon: Icons.trending_up,
    ),
    PostTemplate(
      id: 'template_003',
      name: 'Grateful for:',
      description: 'Express gratitude for people, things, or experiences',
      icon: Icons.favorite,
    ),
  ];

  // Get all templates
  List<PostTemplate> getAllTemplates() {
    return List.unmodifiable(_templates);
  }

  // Get template by ID
  PostTemplate? getTemplateById(String id) {
    try {
      return _templates.firstWhere((template) => template.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get template by name (for backward compatibility)
  PostTemplate? getTemplateByName(String name) {
    try {
      return _templates.firstWhere((template) => template.name == name);
    } catch (e) {
      return null;
    }
  }

  // Future method for fetching templates from backend
  Future<List<PostTemplate>> fetchTemplatesFromBackend() async {
    // TODO: Implement API call to fetch templates
    // For now, return the local templates
    await Future.delayed(
      const Duration(milliseconds: 500),
    ); // Simulate API call
    return getAllTemplates();
  }

  // Method to refresh templates (for future use)
  Future<void> refreshTemplates() async {
    // TODO: Implement refresh logic from backend
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
