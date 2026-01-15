import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project_micro_journal/authentication/services/authentication_token_storage_service.dart';
import 'package:project_micro_journal/environment/development.dart';
import '../models/follower.dart';
import '../models/user_search_result.dart';
import '../models/follow_stats.dart';

class FollowersService {
  static final FollowersService _instance = FollowersService._internal();
  factory FollowersService() => _instance;
  FollowersService._internal();

  final AuthenticationTokenStorageService _authStorage =
      AuthenticationTokenStorageService();
  final String _baseUrl = Environment.baseUrl;

  Future<String?> _getUserId() async {
    return await _authStorage.getUserId();
  }

  // Follow a user (instant follow for public, pending for private)
  Future<Map<String, dynamic>> followUser(int followingId) async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('User not authenticated');

    final response = await http.post(
      Uri.parse('${_baseUrl}users/$userId/follow'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'following_id': followingId}),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to follow user: ${response.body}');
    }
  }

  // Accept a follow request
  Future<void> acceptFollowRequest(int followerId) async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('User not authenticated');

    final response = await http.post(
      Uri.parse('${_baseUrl}users/$userId/follow-requests/$followerId/accept'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to accept follow request: ${response.body}');
    }
  }

  // Reject a follow request
  Future<void> rejectFollowRequest(int followerId) async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('User not authenticated');

    final response = await http.post(
      Uri.parse('${_baseUrl}users/$userId/follow-requests/$followerId/reject'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to reject follow request: ${response.body}');
    }
  }

  // Cancel a sent follow request
  Future<void> cancelFollowRequest(int followingId) async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('User not authenticated');

    final response = await http.delete(
      Uri.parse('${_baseUrl}users/$userId/follow-requests/$followingId/cancel'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to cancel follow request: ${response.body}');
    }
  }

  // Get pending follow requests (received)
  Future<List<Follower>> getPendingFollowRequests() async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('User not authenticated');

    final response = await http.get(
      Uri.parse('${_baseUrl}users/$userId/follow-requests/pending'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded == null) return [];
      final List<dynamic> data = decoded is List ? decoded : [];
      return data.map((json) => Follower.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch pending requests: ${response.body}');
    }
  }

  // Get list of followers (accepted only)
  Future<List<Follower>> getFollowers() async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('User not authenticated');

    final response = await http.get(
      Uri.parse('${_baseUrl}users/$userId/followers'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded == null) return [];
      final List<dynamic> data = decoded is List ? decoded : [];
      return data.map((json) => Follower.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch followers: ${response.body}');
    }
  }

  // Get list of users being followed (accepted only)
  Future<List<Follower>> getFollowing() async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('User not authenticated');

    final response = await http.get(
      Uri.parse('${_baseUrl}users/$userId/following'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded == null) return [];
      final List<dynamic> data = decoded is List ? decoded : [];
      return data.map((json) => Follower.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch following: ${response.body}');
    }
  }

  // Search users with follow status
  Future<List<UserSearchResult>> searchUsers(String query) async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('User not authenticated');

    final response = await http.get(
      Uri.parse(
        '${_baseUrl}users/search?q=${Uri.encodeComponent(query)}&requesting_user_id=$userId',
      ),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded == null) return [];
      final List<dynamic> data = decoded is List ? decoded : [];
      return data.map((json) => UserSearchResult.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search users: ${response.body}');
    }
  }

  // Get sent follow requests
  Future<List<Follower>> getSentFollowRequests() async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('User not authenticated');

    final response = await http.get(
      Uri.parse('${_baseUrl}users/$userId/follow-requests/sent'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded == null) return [];
      final List<dynamic> data = decoded is List ? decoded : [];
      return data.map((json) => Follower.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch sent requests: ${response.body}');
    }
  }

  // Unfollow a user
  Future<void> unfollowUser(int followingId) async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('User not authenticated');

    final response = await http.delete(
      Uri.parse('${_baseUrl}users/$userId/following/$followingId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to unfollow user: ${response.body}');
    }
  }

  // Remove a follower
  Future<void> removeFollower(int followerId) async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('User not authenticated');

    final response = await http.delete(
      Uri.parse('${_baseUrl}users/$userId/followers/$followerId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to remove follower: ${response.body}');
    }
  }

  // Unfollow and remove (disconnect both ways)
  Future<void> disconnectUser(int targetUserId) async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('User not authenticated');

    final response = await http.delete(
      Uri.parse('${_baseUrl}users/$userId/disconnect/$targetUserId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to disconnect: ${response.body}');
    }
  }

  // Get follower and following stats
  Future<FollowStats> getFollowStats() async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('User not authenticated');

    final response = await http.get(
      Uri.parse('${_baseUrl}users/$userId/follow-stats'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return FollowStats.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch stats: ${response.body}');
    }
  }
}
