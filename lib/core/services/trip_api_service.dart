import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class TripApiException implements Exception {
  TripApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TripApiService {
  const TripApiService();

  static final Uri _postTripUri = Uri.parse(
    'https://lorry.workwista.com/api/users/post/trip/',
  );
  static const Duration _timeout = Duration(seconds: 20);
  static const Map<String, String> _headers = <String, String>{
    'Accept': 'application/json',
    'Content-Type': 'application/x-www-form-urlencoded',
  };

  Future<Map<String, dynamic>> getTripChoices() async {
    final url = Uri.parse(
      'https://lorry.workwista.com/api/users/trip/get/choices/',
    );

    final response = await http.get(
      url,
      headers: const {
        'Accept': 'application/json',
      },
    ).timeout(_timeout);

    if (response.statusCode != 200) {
      throw TripApiException('Failed to load trip choices');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw TripApiException('Invalid API format');
  }

  Future<Map<String, dynamic>> postTrip({
    required Map<String, String> payload,
    String? accessToken,
    List<String>? stopsPending,
  }) async {
    final headers = <String, String>{..._headers};
    final trimmedToken = accessToken?.trim() ?? '';
    if (trimmedToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $trimmedToken';
    }

    _logRequest(headers, payload, stopsPending);

    final response = await http
        .post(_postTripUri, headers: headers, body: payload)
        .timeout(_timeout);

    debugPrint(
      'POST $_postTripUri status: ${response.statusCode}',
    );
    debugPrint('POST $_postTripUri response: ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw TripApiException(_buildRequestError(response));
    }

    return _tryDecodePayload(response.body);
  }

  void _logRequest(
    Map<String, String> headers,
    Map<String, String> payload,
    List<String>? stopsPending,
  ) {
    final safeHeaders = <String, String>{...headers};
    if (safeHeaders.containsKey('Authorization')) {
      safeHeaders['Authorization'] = 'Bearer ***';
    }
    debugPrint('POST $_postTripUri headers: $safeHeaders');
    debugPrint('POST $_postTripUri body: ${jsonEncode(payload)}');
    if (stopsPending != null && stopsPending.isNotEmpty) {
      debugPrint(
        'POST $_postTripUri stops pending: ${jsonEncode(stopsPending)}',
      );
    }
  }

  String _buildRequestError(http.Response response) {
    final decoded = _tryDecodePayload(response.body);
    final message =
        _extractMessage(decoded['error']) ??
        _extractMessage(decoded['errors']) ??
        _extractMessage(decoded['detail']) ??
        _extractMessage(decoded['message']);

    if (message != null && message.trim().isNotEmpty) {
      return message;
    }

    return 'Failed to post trip. (${response.statusCode})';
  }

  String? _extractMessage(dynamic source, [String? field]) {
    if (source is String) {
      final text = source.trim();
      if (text.isEmpty) {
        return null;
      }
      return field == null ? text : '$field: $text';
    }

    if (source is List) {
      final parts = source
          .map((entry) => _extractMessage(entry, field))
          .whereType<String>()
          .toList();
      if (parts.isEmpty) {
        return null;
      }
      return parts.join('\n');
    }

    if (source is Map) {
      final parts = <String>[];
      source.forEach((key, value) {
        final message = _extractMessage(value, key.toString());
        if (message != null) {
          parts.add(message);
        }
      });
      if (parts.isEmpty) {
        return null;
      }
      return parts.join('\n');
    }

    return null;
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
}