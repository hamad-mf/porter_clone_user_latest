import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/trip.dart';
import '../services/auth_api_service.dart';
import '../storage/auth_local_storage.dart';

class TripNotFoundException implements Exception {
  TripNotFoundException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TripDetailsApiException implements Exception {
  TripDetailsApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TripDetailsApiService {
  const TripDetailsApiService({http.Client? client}) : _client = client;

  final http.Client? _client;

  static const Duration _timeout = Duration(seconds: 20);
  static const Map<String, String> _headers = <String, String>{
    'Accept': 'application/json',
  };

  Future<Trip> getTripById({
    required String tripId,
    String? accessToken,
  }) async {
    final result = await _doGetTripById(
      tripId: tripId,
      accessToken: accessToken,
    );

    // If we got a 401, try to refresh the token and retry once
    if (result == null) {
      debugPrint('GET trip details: 401 – attempting token refresh...');
      final refreshed = await _tryRefreshAndSave();
      if (refreshed == null) {
        throw TripDetailsApiException(
          'Session expired. Please log in again.',
        );
      }
      final retry = await _doGetTripById(
        tripId: tripId,
        accessToken: refreshed,
      );
      if (retry == null) {
        throw TripDetailsApiException(
          'Session expired. Please log in again.',
        );
      }
      return retry;
    }

    return result;
  }

  /// Returns trip on success, [null] specifically on 401.
  Future<Trip?> _doGetTripById({
    required String tripId,
    String? accessToken,
  }) async {
    final trimmedTripId = tripId.trim();
    if (trimmedTripId.isEmpty) {
      throw TripDetailsApiException('Trip ID is required.');
    }

    final url = Uri.parse(
      'https://lorry.workwista.com/api/users/trip/${Uri.encodeComponent(trimmedTripId)}/',
    );

    final headers = <String, String>{..._headers};
    final trimmedToken = accessToken?.trim() ?? '';
    if (trimmedToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $trimmedToken';
    }

    _logRequest(url, headers);

    try {
      final response = await _get(url, headers: headers).timeout(_timeout);

      debugPrint('GET $url status: ${response.statusCode}');
      debugPrint('GET $url response: ${response.body}');

      if (response.statusCode == 401) {
        return null; // Signal caller to refresh
      }

      if (response.statusCode == 404) {
        throw TripNotFoundException('Trip not found.');
      }

      if (response.statusCode == 500) {
        throw TripDetailsApiException('Server error. Please try again later.');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw TripDetailsApiException(
          'Failed to fetch trip details. (${response.statusCode})',
        );
      }

      return _parseTripResponse(response.body);
    } on TimeoutException {
      throw TripDetailsApiException(
        'Request timed out. Please check your internet connection.',
      );
    } on http.ClientException {
      throw TripDetailsApiException(
        'Network error. Please check your internet connection.',
      );
    } catch (e) {
      if (e is TripNotFoundException || e is TripDetailsApiException) {
        rethrow;
      }
      throw TripDetailsApiException('An unexpected error occurred: $e');
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
      debugPrint('Token refreshed successfully (trip details).');
      return newAccess;
    } catch (e) {
      debugPrint('Token refresh failed (trip details): $e');
      return null;
    }
  }

  Future<http.Response> _get(
    Uri url, {
    required Map<String, String> headers,
  }) {
    final client = _client;
    if (client != null) {
      return client.get(url, headers: headers);
    }
    return http.get(url, headers: headers);
  }

  void _logRequest(Uri url, Map<String, String> headers) {
    final safeHeaders = <String, String>{...headers};
    if (safeHeaders.containsKey('Authorization')) {
      safeHeaders['Authorization'] = 'Bearer ***';
    }
    debugPrint('GET $url headers: $safeHeaders');
  }

  Trip _parseTripResponse(String source) {
    if (source.trim().isEmpty) {
      throw TripDetailsApiException('Empty response from server');
    }

    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) {
        throw TripDetailsApiException(
          'Invalid response format: expected JSON object',
        );
      }

      final data = decoded['data'];
      if (data is! Map<String, dynamic>) {
        throw TripDetailsApiException(
          'Invalid response format: expected data object',
        );
      }

      return Trip.fromJson(data);
    } on FormatException catch (e) {
      throw TripDetailsApiException(
        'Failed to parse response: ${e.message}',
      );
    } catch (e) {
      if (e is TripDetailsApiException) {
        rethrow;
      }
      throw TripDetailsApiException('Failed to parse trip details: $e');
    }
  }
}
