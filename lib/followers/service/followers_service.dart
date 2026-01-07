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

  // Follow a user
  Future<void> followUser(int followingId) async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('User not authenticated');

    final response = await http.post(
      Uri.parse('${_baseUrl}users/$userId/follow'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'following_id': followingId}),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to follow user: ${response.body}');
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

  // Get list of followers
  Future<List<Follower>> getFollowers() async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('User not authenticated');

    final response = await http.get(
      Uri.parse('${_baseUrl}users/$userId/followers'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Follower.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch followers: ${response.body}');
    }
  }

  // Get list of users being followed
  Future<List<Follower>> getFollowing() async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('User not authenticated');

    final response = await http.get(
      Uri.parse('${_baseUrl}users/$userId/following'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Follower.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch following: ${response.body}');
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
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => UserSearchResult.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search users: ${response.body}');
    }
  }
}
