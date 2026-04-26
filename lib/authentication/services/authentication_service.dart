import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:project_micro_journal/authentication/models/login_response.dart';
import 'package:project_micro_journal/authentication/pages/signup_page.dart';
import 'package:project_micro_journal/authentication/services/authentication_token_storage_service.dart';
import 'package:project_micro_journal/environment/development.dart';

class AuthenticationService {
  late final Dio _dio;
  final authenticationTokenStorageService = AuthenticationTokenStorageService();

  AuthenticationService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: Environment.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }

  Future<LoginResponse> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/login',
        data: {'email': email, 'password': password},
      );

      return LoginResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<Response> signup(
    String username,
    String displayName,
    String dob,
    String gender,
    String email,
    String password,
  ) async {
    try {
      final response = await _dio.post(
        '/users',
        data: {
          'username': username,
          'display_name': displayName,
          'dob': dob,
          'gender': gender,
          'email': email,
          'password': password,
        },
      );
      return response;
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<Map<String, dynamic>> googleSignIn(String idToken) async {
    try {
      final response = await _dio.post(
        '/auth/google',
        data: {'id_token': idToken},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Google sign-in failed');
    }
  }

  Future<Map<String, dynamic>> completeGoogleSignUp({
    required String googleId,
    required String email,
    required String username,
    required String displayName,
    required String dob,
    required String gender,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/google/complete',
        data: {
          'google_id': googleId,
          'email': email,
          'username': username,
          'display_name': displayName,
          'dob': dob,
          'gender': gender,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Failed to complete sign up');
    }
  }

  Future<Response> logout(BuildContext context, String refreshToken) async {
    try {
      final response = await _dio.post(
        '/logout',
        data: {'refresh_token': refreshToken},
      );

      authenticationTokenStorageService.clearTokens();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SignupPage()),
        (Route<dynamic> route) => false,
      );

      return response;
    } on DioException catch (e) {
      authenticationTokenStorageService.clearTokens();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SignupPage()),
        (Route<dynamic> route) => false,
      );

      throw Exception(_handleError(e));
    }
  }

  String _handleError(DioException error) {
    if (error.response != null) {
      return "Server error: ${error.response?.statusCode} ${error.response?.data}";
    } else {
      return "Connection error: ${error.message}";
    }
  }
}
