import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/trip.dart';

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

      // Handle specific HTTP status codes
      if (response.statusCode == 401) {
        throw TripsApiException(
          'Authentication failed. Please log in again.',
        );
      }

      if (response.statusCode == 500) {
        throw TripsApiException(
          'Server error. Please try again later.',
        );
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
      if (e is TripsApiException) {
        rethrow;
      }
      throw TripsApiException(
        'An unexpected error occurred: $e',
      );
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
