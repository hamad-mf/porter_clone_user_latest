import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/user_profile.dart';
import '../services/auth_api_service.dart';
import '../storage/auth_local_storage.dart';

class ProfileApiException implements Exception {
  ProfileApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ProfileApiService {
  const ProfileApiService();

  static final Uri _viewProfileUri = Uri.parse(
    'https://lorry.workwista.com/api/users/view/profile/',
  );
  static final Uri _updateProfileUri = Uri.parse(
    'https://lorry.workwista.com/api/users/profile/update/',
  );
  static const Duration _timeout = Duration(seconds: 20);

  /// Fetches user profile data from the backend
  /// Throws ProfileApiException on failure
  Future<UserProfile> viewProfile({required String accessToken}) async {
    final result = await _doViewProfile(accessToken: accessToken);

    // If we got a 401, try to refresh the token and retry once
    if (result == null) {
      debugPrint('GET $_viewProfileUri: 401 – attempting token refresh...');
      final refreshed = await _tryRefreshAndSave();
      if (refreshed == null) {
        throw ProfileApiException(
          'Session expired. Please log in again.',
        );
      }
      final retry = await _doViewProfile(accessToken: refreshed);
      if (retry == null) {
        throw ProfileApiException(
          'Session expired. Please log in again.',
        );
      }
      return retry;
    }

    return result;
  }

  /// Returns user profile on success, [null] specifically on 401.
  Future<UserProfile?> _doViewProfile({required String accessToken}) async {
    final trimmedToken = accessToken.trim();
    if (trimmedToken.isEmpty) {
      throw ProfileApiException('Authentication required. Please log in again.');
    }

    try {
      final response = await http.get(
        _viewProfileUri,
        headers: <String, String>{
          'Authorization': 'Bearer $trimmedToken',
          'Accept': 'application/json',
        },
      ).timeout(_timeout);

      final payload = _tryDecodePayload(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == 401) {
          return null; // Signal caller to refresh
        }
        throw ProfileApiException(
          _extractMessage(
            payload,
            fallback: 'Unable to fetch profile. Please try again later.',
          ),
        );
      }

      return UserProfile.fromJson(payload);
    } on TimeoutException {
      throw ProfileApiException(
        'Request timed out. Please check your connection.',
      );
    } on ProfileApiException {
      rethrow;
    } catch (e) {
      throw ProfileApiException(
        'Unable to fetch profile. Please try again later.',
      );
    }
  }

  /// Updates user profile with new data
  /// Throws ProfileApiException on failure
  Future<UserProfile> updateProfile({
    required String accessToken,
    required String fullName,
  }) async {
    final result = await _doUpdateProfile(
      accessToken: accessToken,
      fullName: fullName,
    );

    // If we got a 401, try to refresh the token and retry once
    if (result == null) {
      debugPrint('POST $_updateProfileUri: 401 – attempting token refresh...');
      final refreshed = await _tryRefreshAndSave();
      if (refreshed == null) {
        throw ProfileApiException(
          'Session expired. Please log in again.',
        );
      }
      final retry = await _doUpdateProfile(
        accessToken: refreshed,
        fullName: fullName,
      );
      if (retry == null) {
        throw ProfileApiException(
          'Session expired. Please log in again.',
        );
      }
      return retry;
    }

    return result;
  }

  /// Returns updated profile on success, [null] specifically on 401.
  Future<UserProfile?> _doUpdateProfile({
    required String accessToken,
    required String fullName,
  }) async {
    final trimmedToken = accessToken.trim();
    final trimmedName = fullName.trim();
    
    if (trimmedToken.isEmpty) {
      throw ProfileApiException('Authentication required. Please log in again.');
    }
    
    if (trimmedName.isEmpty) {
      throw ProfileApiException('Profile name cannot be empty.');
    }

    try {
      final request = http.MultipartRequest('POST', _updateProfileUri)
        ..headers['Authorization'] = 'Bearer $trimmedToken'
        ..headers['Accept'] = 'application/json'
        ..fields['full_name'] = trimmedName;

      final streamed = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamed);

      final payload = _tryDecodePayload(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == 401) {
          return null; // Signal caller to refresh
        }
        throw ProfileApiException(
          _extractMessage(
            payload,
            fallback: 'Unable to update profile. Please try again later.',
          ),
        );
      }

      // Extract profile from data field
      final data = payload['data'];
      if (data is Map<String, dynamic>) {
        return UserProfile.fromJson(data);
      }

      // Fallback: try to parse the whole payload
      return UserProfile.fromJson(payload);
    } on TimeoutException {
      throw ProfileApiException(
        'Request timed out. Please check your connection.',
      );
    } on ProfileApiException {
      rethrow;
    } catch (e) {
      throw ProfileApiException(
        'Unable to update profile. Please try again later.',
      );
    }
  }

  /// Reads the saved refresh token, calls the refresh API, saves the new
  /// access token and returns it. Returns [null] if refresh fails.
  Future<String?> _tryRefreshAndSave() async {
    try {
      final saved = await AuthLocalStorage.getRefreshToken();
      if (saved == null || saved.trim().isEmpty) return null;
      final newAccess = await const AuthApiService().refreshToken(saved);
      await AuthLocalStorage.saveAccessToken(newAccess);
      debugPrint('Token refreshed successfully (profile).');
      return newAccess;
    } catch (e) {
      debugPrint('Token refresh failed (profile): $e');
      return null;
    }
  }

  Map<String, dynamic> _tryDecodePayload(String source) {
    if (source.trim().isEmpty) {
      return <String, dynamic>{};
    }
    try {
      final decoded = jsonDecode(source);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{};
    } on FormatException {
      return <String, dynamic>{};
    }
  }

  String _extractMessage(
    Map<String, dynamic> payload, {
    required String fallback,
  }) {
    final message = payload['message']?.toString();
    if (message != null && message.trim().isNotEmpty) {
      return message.trim();
    }
    final detail = payload['detail']?.toString();
    if (detail != null && detail.trim().isNotEmpty) {
      return detail.trim();
    }
    return fallback;
  }
}
