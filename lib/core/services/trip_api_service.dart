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
      throw TripApiException(
        'Failed to post trip. (${response.statusCode})',
      );
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
