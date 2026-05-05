import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/trip.dart';
import '../services/auth_api_service.dart';
import '../storage/auth_local_storage.dart';

class TripsApiException implements Exception {
  TripsApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TripsApiService {
  TripsApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static final Uri _getTripsUri = Uri.parse(
    'https://lorry.workwista.com/api/users/trips/by-status/',
  );
  static const Duration _timeout = Duration(seconds: 20);
  static const Map<String, String> _headers = <String, String>{
    'Accept': 'application/json',
  };

  Future<Map<String, List<Trip>>> getTrips({
    required String? accessToken,
  }) async {
    final result = await _doGetTrips(accessToken: accessToken);

    // If we got a 401, try to refresh the token and retry once
    if (result == null) {
      debugPrint('GET $_getTripsUri: 401 – attempting token refresh...');
      final refreshed = await _tryRefreshAndSave();
      if (refreshed == null) {
        throw TripsApiException('Session expired. Please log in again.');
      }
      final retry = await _doGetTrips(accessToken: refreshed);
      if (retry == null) {
        throw TripsApiException('Session expired. Please log in again.');
      }
      return retry;
    }

    return result;
  }

  /// Returns parsed trips on success, [null] specifically on 401.
  Future<Map<String, List<Trip>>?> _doGetTrips({
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
          .get(_getTripsUri, headers: headers)
          .timeout(_timeout);

      debugPrint('GET $_getTripsUri status: ${response.statusCode}');
      debugPrint('GET $_getTripsUri response: ${response.body}');

      if (response.statusCode == 401) {
        return null; // Signal caller to refresh
      }

      if (response.statusCode == 500) {
        throw TripsApiException('Server error. Please try again later.');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw TripsApiException(
          'Failed to fetch trips. (${response.statusCode})',
        );
      }

      return _parseTripsResponse(response.body);
    } on TimeoutException {
      throw TripsApiException(
        'Request timed out. Please check your internet connection.',
      );
    } on http.ClientException {
      throw TripsApiException(
        'Network error. Please check your internet connection.',
      );
    } catch (e) {
      if (e is TripsApiException) rethrow;
      throw TripsApiException('An unexpected error occurred: $e');
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
      debugPrint('Token refreshed successfully (trips).');
      return newAccess;
    } catch (e) {
      debugPrint('Token refresh failed (trips): $e');
      return null;
    }
  }

  void _logRequest(Map<String, String> headers) {
    final safeHeaders = <String, String>{...headers};
    if (safeHeaders.containsKey('Authorization')) {
      safeHeaders['Authorization'] = 'Bearer ***';
    }
    debugPrint('GET $_getTripsUri headers: $safeHeaders');
  }

  Map<String, List<Trip>> _parseTripsResponse(String source) {
    if (source.trim().isEmpty) {
      return {
        'pending': <Trip>[],
        'ongoing': <Trip>[],
        'completed': <Trip>[],
      };
    }

    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) {
        throw TripsApiException(
          'Invalid response format: expected JSON object',
        );
      }

      final data = decoded['data'];
      if (data == null || data is! Map<String, dynamic>) {
        return {
          'pending': <Trip>[],
          'ongoing': <Trip>[],
          'completed': <Trip>[],
        };
      }

      return {
        'pending': _parseStatusTrips(data['pending']),
        'ongoing': _parseStatusTrips(data['ongoing']),
        'completed': _parseStatusTrips(data['completed']),
      };
    } on FormatException catch (e) {
      throw TripsApiException(
        'Failed to parse response: ${e.message}',
      );
    } catch (e) {
      if (e is TripsApiException) {
        rethrow;
      }
      throw TripsApiException(
        'Failed to parse trips: $e',
      );
    }
  }

  List<Trip> _parseStatusTrips(dynamic statusData) {
    if (statusData == null) return <Trip>[];

    final trips = statusData['trips'];
    if (trips == null || trips is! List) return <Trip>[];

    return trips
        .map((json) => Trip.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
