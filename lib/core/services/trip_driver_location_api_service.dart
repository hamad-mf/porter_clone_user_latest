import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class TripDriverLocationApiException implements Exception {
  TripDriverLocationApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TripDriverLocation {
  const TripDriverLocation({
    required this.tripId,
    required this.driverId,
    required this.driverName,
    required this.latitude,
    required this.longitude,
  });

  final String tripId;
  final String driverId;
  final String driverName;
  final double latitude;
  final double longitude;

  factory TripDriverLocation.fromJson(Map<String, dynamic> json) {
    return TripDriverLocation(
      tripId: json['trip_id']?.toString() ?? '',
      driverId: json['driver_id']?.toString() ?? '',
      driverName: json['driver_name']?.toString() ?? '',
      latitude: _doubleValue(json['latitude']),
      longitude: _doubleValue(json['longitude']),
    );
  }

  static double _doubleValue(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class TripDriverLocationApiService {
  const TripDriverLocationApiService({http.Client? client}) : _client = client;

  final http.Client? _client;

  http.Client get client => _client ?? http.Client();

  static const String _baseUrl = 'https://lorry.workwista.com/api/users';
  static const Duration _timeout = Duration(seconds: 20);

  Future<void> requestDriverLocation({
    required String tripId,
    required String? accessToken,
  }) async {
    final trimmedTripId = tripId.trim();
    final trimmedToken = accessToken?.trim() ?? '';

    if (trimmedTripId.isEmpty) {
      throw TripDriverLocationApiException('Trip id is required.');
    }
    if (trimmedToken.isEmpty) {
      throw TripDriverLocationApiException('Please log in again.');
    }

    final uri = Uri.parse('$_baseUrl/trip/$trimmedTripId/request-driver-location/');

    try {
      final response = await client
          .post(
            uri,
            headers: <String, String>{
              'Accept': 'application/json',
              'Authorization': 'Bearer $trimmedToken',
            },
          )
          .timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final payload = _tryDecodePayload(response.body);
        throw TripDriverLocationApiException(
          _extractMessage(
            payload,
            fallback: 'Failed to alert driver. (${response.statusCode})',
          ),
        );
      }
    } on TimeoutException {
      throw TripDriverLocationApiException(
        'Request timed out. Please check your internet connection.',
      );
    } on http.ClientException catch (error) {
      throw TripDriverLocationApiException('Network error: ${error.message}');
    }
  }

  Future<TripDriverLocation> getDriverLocation({
    required String tripId,
    required String? accessToken,
  }) async {
    final trimmedTripId = tripId.trim();
    final trimmedToken = accessToken?.trim() ?? '';

    if (trimmedTripId.isEmpty) {
      throw TripDriverLocationApiException('Trip id is required.');
    }
    if (trimmedToken.isEmpty) {
      throw TripDriverLocationApiException('Please log in again.');
    }

    final uri = Uri.parse('$_baseUrl/trip/$trimmedTripId/driver-location/');

    try {
      final response = await client
          .get(
            uri,
            headers: <String, String>{
              'Accept': 'application/json',
              'Authorization': 'Bearer $trimmedToken',
            },
          )
          .timeout(_timeout);

      final payload = _tryDecodePayload(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw TripDriverLocationApiException(
          _extractMessage(
            payload,
            fallback: 'Failed to fetch driver location. (${response.statusCode})',
          ),
        );
      }

      return TripDriverLocation.fromJson(payload);
    } on TimeoutException {
      throw TripDriverLocationApiException(
        'Request timed out. Please check your internet connection.',
      );
    } on FormatException {
      throw TripDriverLocationApiException('Invalid response from server.');
    } on http.ClientException catch (error) {
      throw TripDriverLocationApiException('Network error: ${error.message}');
    }
  }

  Map<String, dynamic> _tryDecodePayload(String source) {
    if (source.trim().isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(source);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return <String, dynamic>{};
  }

  String _extractMessage(
    Map<String, dynamic> payload, {
    required String fallback,
  }) {
    final error = payload['error']?.toString().trim();
    if (error != null && error.isNotEmpty) {
      return error;
    }

    final message = payload['message']?.toString().trim();
    if (message != null && message.isNotEmpty) {
      return message;
    }

    final detail = payload['detail']?.toString().trim();
    if (detail != null && detail.isNotEmpty) {
      return detail;
    }

    return fallback;
  }
}
