import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ProfileApiException implements Exception {
  ProfileApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class UserProfile {
  const UserProfile({
    required this.fullName,
    required this.phoneNumber,
  });

  final String fullName;
  final String phoneNumber;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      fullName: json['full_name']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
    );
  }
}

class UpdateProfileResult {
  const UpdateProfileResult({
    required this.message,
    required this.profile,
  });

  final String message;
  final UserProfile profile;
}

class ProfileApiService {
  const ProfileApiService({http.Client? client}) : _client = client;

  final http.Client? _client;

  http.Client get client => _client ?? http.Client();

  static final Uri _viewProfileUri = Uri.parse(
    'https://lorry.workwista.com/api/users/view/profile/',
  );
  static final Uri _updateProfileUri = Uri.parse(
    'https://lorry.workwista.com/api/users/profile/update/',
  );
  static const Duration _timeout = Duration(seconds: 20);

  Future<UserProfile> viewProfile({required String accessToken}) async {
    final trimmedToken = accessToken.trim();
    if (trimmedToken.isEmpty) {
      throw ProfileApiException('Access token is required.');
    }

    try {
      final response = await client
          .get(
            _viewProfileUri,
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $trimmedToken',
            },
          )
          .timeout(_timeout);

      final payload = _tryDecodePayload(response.body);

      if (response.statusCode == 401) {
        throw ProfileApiException('Unauthorized: Invalid or expired token.');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ProfileApiException(
          _extractMessage(
            payload,
            fallback: 'Failed to fetch profile. (${response.statusCode})',
          ),
        );
      }

      if (payload.isEmpty && response.body.trim().isNotEmpty) {
        throw ProfileApiException('Invalid response from server.');
      }

      return UserProfile.fromJson(payload);
    } on TimeoutException {
      throw ProfileApiException(
        'Request timeout. Please check your internet connection.',
      );
    } on http.ClientException catch (e) {
      throw ProfileApiException('Network error: ${e.message}');
    } catch (e) {
      if (e is ProfileApiException) {
        rethrow;
      }
      throw ProfileApiException('Unexpected error: $e');
    }
  }

  Future<UpdateProfileResult> updateProfile({
    required String accessToken,
    required String fullName,
  }) async {
    final trimmedToken = accessToken.trim();
    final trimmedName = fullName.trim();

    if (trimmedToken.isEmpty) {
      throw ProfileApiException('Access token is required.');
    }
    if (trimmedName.isEmpty) {
      throw ProfileApiException('Full name is required.');
    }

    try {
      final request = http.MultipartRequest('POST', _updateProfileUri);
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $trimmedToken',
      });
      request.fields['full_name'] = trimmedName;

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      final payload = _tryDecodePayload(response.body);

      if (response.statusCode == 401) {
        throw ProfileApiException('Unauthorized: Invalid or expired token.');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ProfileApiException(
          _extractMessage(
            payload,
            fallback: 'Failed to update profile. (${response.statusCode})',
          ),
        );
      }

      if (payload.isEmpty && response.body.trim().isNotEmpty) {
        throw ProfileApiException('Invalid response from server.');
      }

      final message = _extractMessage(
        payload,
        fallback: 'User profile updated successfully',
      );

      final data = payload['data'];
      final dataMap = data is Map<String, dynamic> ? data : payload;

      return UpdateProfileResult(
        message: message,
        profile: UserProfile.fromJson(dataMap),
      );
    } on TimeoutException {
      throw ProfileApiException(
        'Request timeout. Please check your internet connection.',
      );
    } on http.ClientException catch (e) {
      throw ProfileApiException('Network error: ${e.message}');
    } catch (e) {
      if (e is ProfileApiException) {
        rethrow;
      }
      throw ProfileApiException('Unexpected error: $e');
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
