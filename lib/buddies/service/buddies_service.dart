import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project_micro_journal/authentication/services/authentication_token_storage_service.dart';
import 'package:project_micro_journal/environment/development.dart';
import '../models/buddy.dart';
import '../models/user_search_result.dart';

class BuddiesService {
  final AuthenticationTokenStorageService _authStorage =
      AuthenticationTokenStorageService();

  Future<List<Buddy>> getBuddies() async {
    final userId = await _authStorage.getUserId();
    if (userId == null) throw Exception('User not authenticated');

    final response = await http.get(
      Uri.parse('${Environment.baseUrl}users/$userId/buddies'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      if (response.body.isEmpty || response.body == 'null') {
        return [];
      }

      final dynamic data = json.decode(response.body);

      if (data == null) {
        return [];
      }

      if (data is! List) {
        return [];
      }

      return data.map((json) => Buddy.fromJson(json)).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Failed to load buddies: ${response.statusCode}');
    }
  }

  Future<List<UserSearchResult>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    final response = await http.get(
      Uri.parse(
        '${Environment.baseUrl}users/search?q=${Uri.encodeComponent(query)}',
      ),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      if (response.body.isEmpty || response.body == 'null') {
        return [];
      }

      final dynamic data = json.decode(response.body);

      if (data == null || data is! List) {
        return [];
      }

      return data.map((json) => UserSearchResult.fromJson(json)).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Search failed: ${response.statusCode}');
    }
  }

  Future<void> addBuddy(int buddyId) async {
    final userId = await _authStorage.getUserId();
    if (userId == null) throw Exception('User not authenticated');

    final response = await http.post(
      Uri.parse('${Environment.baseUrl}users/$userId/buddies'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'buddy_id': buddyId}),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add buddy');
    }
  }

  Future<void> removeBuddy(int buddyId) async {
    final userId = await _authStorage.getUserId();
    if (userId == null) throw Exception('User not authenticated');

    final response = await http.delete(
      Uri.parse('${Environment.baseUrl}users/$userId/buddies/$buddyId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to remove buddy');
    }
  }
}
