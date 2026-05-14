import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/accepted_driver.dart';
import '../services/auth_api_service.dart';
import '../storage/auth_local_storage.dart';

class AcceptedDriversApiException implements Exception {
  AcceptedDriversApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AcceptedDriversApiService {
  AcceptedDriversApiService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static final Uri _getAcceptedDriversUri = Uri.parse(
    'https://lorry.workwista.com/api/users/trips/all/accepted-drivers/',
  );
  static const Duration _timeout = Duration(seconds: 20);
  static const Map<String, String> _headers = <String, String>{
    'Accept': 'application/json',
  };

  Future<List<AcceptedDriver>> getAcceptedDrivers({
    required String? accessToken,
  }) async {
    final result = await _doGetAcceptedDrivers(accessToken: accessToken);

    // If we got a 401, try to refresh the token and retry once
    if (result == null) {
      debugPrint('GET $_getAcceptedDriversUri: 401 – attempting token refresh...');
      final refreshed = await _tryRefreshAndSave();
      if (refreshed == null) {
        throw AcceptedDriversApiException(
          'Authentication failed. Please log in again.',
        );
      }
      final retry = await _doGetAcceptedDrivers(accessToken: refreshed);
      if (retry == null) {
        throw AcceptedDriversApiException(
          'Authentication failed. Please log in again.',
        );
      }
      return retry;
    }

    return result;
  }

  /// Returns parsed accepted drivers on success, [null] specifically on 401.
  Future<List<AcceptedDriver>?> _doGetAcceptedDrivers({
    required String? accessToken,
  }) async {
    final headers = <String, String>{..._headers};
    final trimmedToken = accessToken?.trim() ?? '';
    if (trimmedToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $trimmedToken';
    }

    _logRequest(headers);

    try {
      final response = await _client
          .get(_getAcceptedDriversUri, headers: headers)
          .timeout(_timeout);

      debugPrint(
        'GET $_getAcceptedDriversUri status: ${response.statusCode}',
      );
      debugPrint('GET $_getAcceptedDriversUri response: ${response.body}');

      // Handle specific HTTP status codes
      if (response.statusCode == 401) {
        return null; // Signal caller to refresh
      }

      if (response.statusCode == 500) {
        throw AcceptedDriversApiException(
          'Server error. Please try again later.',
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AcceptedDriversApiException(
          'Failed to fetch accepted drivers. (${response.statusCode})',
        );
      }

      return _parseAcceptedDrivers(response.body);
    } on TimeoutException {
      throw AcceptedDriversApiException(
        'Request timed out. Please check your internet connection.',
      );
    } on http.ClientException {
      throw AcceptedDriversApiException(
        'Network error. Please check your internet connection.',
      );
    } catch (e) {
      if (e is AcceptedDriversApiException) {
        rethrow;
      }
      throw AcceptedDriversApiException(
        'An unexpected error occurred: $e',
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
      debugPrint('Token refreshed successfully (accepted drivers).');
      return newAccess;
    } catch (e) {
      debugPrint('Token refresh failed (accepted drivers): $e');
      return null;
    }
  }

  void _logRequest(Map<String, String> headers) {
    final safeHeaders = <String, String>{...headers};
    if (safeHeaders.containsKey('Authorization')) {
      safeHeaders['Authorization'] = 'Bearer ***';
    }
    debugPrint('GET $_getAcceptedDriversUri headers: $safeHeaders');
  }

  List<AcceptedDriver> _parseAcceptedDrivers(String source) {
    if (source.trim().isEmpty) {
      return <AcceptedDriver>[];
    }

    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) {
        throw AcceptedDriversApiException(
          'Invalid response format: expected JSON object',
        );
      }

      final acceptedDriversJson = decoded['accepted_drivers'];
      if (acceptedDriversJson == null) {
        return <AcceptedDriver>[];
      }

      if (acceptedDriversJson is! List) {
        throw AcceptedDriversApiException(
          'Invalid response format: accepted_drivers must be an array',
        );
      }

      return acceptedDriversJson
          .map((json) => AcceptedDriver.fromJson(json as Map<String, dynamic>))
          .toList();
    } on FormatException catch (e) {
      throw AcceptedDriversApiException(
        'Failed to parse response: ${e.message}',
      );
    } catch (e) {
      if (e is AcceptedDriversApiException) {
        rethrow;
      }
      throw AcceptedDriversApiException(
        'Failed to parse accepted drivers: $e',
      );
    }
  }
}
