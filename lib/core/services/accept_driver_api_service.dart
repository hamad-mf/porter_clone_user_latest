import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

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
    required String accessToken,
  }) async {
    final trimmedTripId = tripId.trim();
    final trimmedAcceptanceId = acceptanceId.trim();
    final trimmedAccessToken = accessToken.trim();

    if (trimmedTripId.isEmpty ||
        trimmedAcceptanceId.isEmpty ||
        trimmedAccessToken.isEmpty) {
      throw AcceptDriverApiException(
        'Trip ID, acceptance ID, and access token are required.',
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
    };

    print('🚀 Accepting driver for trip: $trimmedTripId');
    print('📦 Request body: ${jsonEncode(body)}');

    final response = await http
        .post(
          uri,
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    print('✅ Accept driver response status: ${response.statusCode}');
    print('📄 Accept driver response body: ${response.body}');

    final payload = _tryDecodePayload(response.body);
    
    if (response.statusCode < 200 || response.statusCode >= 300) {
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
