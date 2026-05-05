import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/trip.dart';

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
