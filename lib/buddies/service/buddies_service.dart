import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project_micro_journal/authentication/services/authentication_token_storage_service.dart';
import 'package:project_micro_journal/environment/development.dart';
import '../models/buddy.dart';
import '../models/buddy_request.dart';
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

      if (data == null || data is! List) {
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

  Future<void> sendBuddyRequest(int recipientId) async {
    final userId = await _authStorage.getUserId();
    if (userId == null) throw Exception('User not authenticated');

    final response = await http.post(
      Uri.parse('${Environment.baseUrl}users/$userId/buddy-requests'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'recipient_id': recipientId}),
    );

    if (response.statusCode == 201) {
      return;
    } else if (response.statusCode == 409) {
      final errorBody = response.body;
      throw Exception(
        errorBody.isNotEmpty ? errorBody : 'Request already exists',
      );
    } else {
      throw Exception('Failed to send buddy request: ${response.body}');
    }
  }

  Future<List<BuddyRequest>> getReceivedRequests() async {
    final userId = await _authStorage.getUserId();
    if (userId == null) throw Exception('User not authenticated');

    final response = await http.get(
      Uri.parse('${Environment.baseUrl}users/$userId/buddy-requests/received'),
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

      return data.map((json) => BuddyRequest.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to load received requests: ${response.statusCode}',
      );
    }
  }

  Future<List<BuddyRequest>> getSentRequests() async {
    final userId = await _authStorage.getUserId();
    if (userId == null) throw Exception('User not authenticated');

    final response = await http.get(
      Uri.parse('${Environment.baseUrl}users/$userId/buddy-requests/sent'),
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

      return data.map((json) => BuddyRequest.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load sent requests: ${response.statusCode}');
    }
  }

  Future<void> acceptBuddyRequest(int requestId) async {
    final userId = await _authStorage.getUserId();
    if (userId == null) throw Exception('User not authenticated');

    final response = await http.post(
      Uri.parse('${Environment.baseUrl}buddy-requests/$requestId/accept'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'user_id': int.parse(userId)}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to accept buddy request: ${response.body}');
    }
  }

  Future<void> rejectBuddyRequest(int requestId) async {
    final userId = await _authStorage.getUserId();
    if (userId == null) throw Exception('User not authenticated');

    final response = await http.post(
      Uri.parse('${Environment.baseUrl}buddy-requests/$requestId/reject'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'user_id': int.parse(userId)}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to reject buddy request: ${response.body}');
    }
  }

  Future<void> cancelBuddyRequest(int requestId) async {
    final userId = await _authStorage.getUserId();
    if (userId == null) throw Exception('User not authenticated');

    final response = await http.delete(
      Uri.parse('${Environment.baseUrl}buddy-requests/$requestId/cancel'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'user_id': int.parse(userId)}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to cancel buddy request: ${response.body}');
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
      throw Exception('Failed to remove buddy: ${response.body}');
    }
  }
}
