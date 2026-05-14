import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../services/auth_api_service.dart';
import '../storage/auth_local_storage.dart';

class AcceptDriverApiException implements Exception {
  AcceptDriverApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AcceptDriverResult {
  const AcceptDriverResult({
    required this.message,
    required this.success,
  });

  final String message;
  final bool success;
}

class AcceptDriverApiService {
  const AcceptDriverApiService();

  static const Duration _timeout = Duration(seconds: 20);
  static const Map<String, String> _headers = <String, String>{
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<AcceptDriverResult> acceptDriver({
    required String tripId,
    required String acceptanceId,
    required String driverId,
    required String accessToken,
  }) async {
    final result = await _doAcceptDriver(
      tripId: tripId,
      acceptanceId: acceptanceId,
      driverId: driverId,
      accessToken: accessToken,
    );

    // If we got a 401, try to refresh the token and retry once
    if (result == null) {
      debugPrint('POST accept-driver: 401 – attempting token refresh...');
      final refreshed = await _tryRefreshAndSave();
      if (refreshed == null) {
        throw AcceptDriverApiException(
          'Session expired. Please log in again.',
        );
      }
      final retry = await _doAcceptDriver(
        tripId: tripId,
        acceptanceId: acceptanceId,
        driverId: driverId,
        accessToken: refreshed,
      );
      if (retry == null) {
        throw AcceptDriverApiException(
          'Session expired. Please log in again.',
        );
      }
      return retry;
    }

    return result;
  }

  /// Returns accept driver result on success, [null] specifically on 401.
  Future<AcceptDriverResult?> _doAcceptDriver({
    required String tripId,
    required String acceptanceId,
    required String driverId,
    required String accessToken,
  }) async {
    final trimmedTripId = tripId.trim();
    final trimmedAcceptanceId = acceptanceId.trim();
    final trimmedDriverId = driverId.trim();
    final trimmedAccessToken = accessToken.trim();

    if (trimmedTripId.isEmpty ||
        trimmedAcceptanceId.isEmpty ||
        trimmedDriverId.isEmpty ||
        trimmedAccessToken.isEmpty) {
      throw AcceptDriverApiException(
        'Trip ID, acceptance ID, driver ID, and access token are required.',
      );
    }

    final uri = Uri.parse(
      'https://lorry.workwista.com/api/users/trip/$trimmedTripId/accept-driver/',
    );

    final headers = <String, String>{
      ..._headers,
      'Authorization': 'Bearer $trimmedAccessToken',
    };

    final body = <String, String>{
      'acceptance_id': trimmedAcceptanceId,
      'driver_id': trimmedDriverId,
    };

    debugPrint('🚀 Accepting driver for trip: $trimmedTripId');
    debugPrint('📦 Request body: ${jsonEncode(body)}');

    final response = await http
        .post(
          uri,
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    debugPrint('✅ Accept driver response status: ${response.statusCode}');
    debugPrint('📄 Accept driver response body: ${response.body}');

    final payload = _tryDecodePayload(response.body);
    
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) {
        return null; // Signal caller to refresh
      }
      throw AcceptDriverApiException(
        _extractMessage(
          payload,
          fallback: 'Failed to accept driver. (${response.statusCode})',
        ),
      );
    }

    if (payload.isEmpty && response.body.trim().isNotEmpty) {
      throw AcceptDriverApiException('Invalid response from server.');
    }

    return AcceptDriverResult(
      message: _extractMessage(
        payload,
        fallback: 'Driver accepted successfully.',
      ),
      success: true,
    );
  }

  /// Reads the saved refresh token, calls the refresh API, saves the new
  /// access token and returns it. Returns [null] if refresh fails.
  Future<String?> _tryRefreshAndSave() async {
    try {
      final saved = await AuthLocalStorage.getRefreshToken();
      if (saved == null || saved.trim().isEmpty) return null;
      final newAccess = await const AuthApiService().refreshToken(saved);
      await AuthLocalStorage.saveAccessToken(newAccess);
      debugPrint('Token refreshed successfully (accept driver).');
      return newAccess;
    } catch (e) {
      debugPrint('Token refresh failed (accept driver): $e');
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
