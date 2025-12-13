import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthenticationTokenStorageService {
  final _storage = const FlutterSecureStorage();

  Future<void> saveTokensAndId(
    String accessToken,
    String refreshToken,
    String userId,
  ) async {
    try {
      await _storage.write(key: 'access_token', value: accessToken);
      await _storage.write(key: 'refresh_token', value: refreshToken);
      await _storage.write(key: 'user_id', value: userId);
    } catch (err) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', accessToken);
      await prefs.setString('refresh_token', refreshToken);
      await prefs.setString('user_id', userId);
    }
  }

  Future<String?> getUserId() async {
    final userId = await _storage.read(key: 'user_id');
    if (userId == null) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_id');
    } else {
      return userId;
    }
  }

  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: 'access_token');
    } catch (err) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('access_token');
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: 'refresh_token');
    } catch (err) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('refresh_token');
    }
  }

  Future<void> clearTokens() async {
    try {
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
      await _storage.delete(key: 'user_id');
    } catch (err) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('user_id');
    }
  }
}
