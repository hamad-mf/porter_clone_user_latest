import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class AuthApiException implements Exception {
  AuthApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SendOtpResult {
  const SendOtpResult({
    required this.message,
    required this.phoneNumber,
    required this.verificationId,
  });

  final String message;
  final String phoneNumber;
  final String verificationId;
}

class VerifyOtpResult {
  const VerifyOtpResult({
    required this.message,
    required this.phoneNumber,
    required this.accessToken,
    required this.refreshToken,
  });

  final String message;
  final String phoneNumber;
  final String accessToken;
  final String refreshToken;
}

class AuthApiService {
  const AuthApiService();

  static final Uri _sendOtpUri = Uri.parse(
    'https://lorry.workwista.com/api/users/sendotp/',
  );
  static final Uri _verifyOtpUri = Uri.parse(
    'https://lorry.workwista.com/api/users/verifyotp/',
  );
  static const Duration _timeout = Duration(seconds: 20);
  static const Map<String, String> _headers = <String, String>{
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<SendOtpResult> sendOtp({required String phoneNumber}) async {
    final trimmedPhone = phoneNumber.trim();
    if (trimmedPhone.isEmpty) {
      throw AuthApiException('Phone number is required.');
    }

    final response = await http
        .post(
          _sendOtpUri,
          headers: _headers,
          body: jsonEncode(<String, String>{'phone_number': trimmedPhone}),
        )
        .timeout(_timeout);

    final payload = _tryDecodePayload(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(
        _extractMessage(
          payload,
          fallback: 'Failed to send OTP. (${response.statusCode})',
        ),
      );
    }
    if (payload.isEmpty && response.body.trim().isNotEmpty) {
      throw AuthApiException('Invalid response from server.');
    }
    final responseCode = int.tryParse(
      payload['responseCode']?.toString() ?? '',
    );
    if (responseCode != null && responseCode != 200) {
      throw AuthApiException(
        _extractMessage(payload, fallback: 'Failed to send OTP.'),
      );
    }

    // Extract data object (same pattern as verifyOtp)
    final data = payload['data'];
    final dataMap = data is Map<String, dynamic> ? data : <String, dynamic>{};
    
    final verificationIdValue = dataMap['verificationId'];
    final verificationId = verificationIdValue?.toString() ?? '';
    if (verificationId.isEmpty) {
      throw AuthApiException('Invalid response: verificationId is missing.');
    }

    final mobileNumber = dataMap['mobileNumber']?.toString();
    return SendOtpResult(
      message: _extractMessage(payload, fallback: 'OTP sent successfully.'),
      phoneNumber: (mobileNumber == null || mobileNumber.trim().isEmpty)
          ? trimmedPhone
          : mobileNumber.trim(),
      verificationId: verificationId,
    );
  }

  Future<VerifyOtpResult> verifyOtp({
    required String phoneNumber,
    required String otp,
    required String verificationId,
    String? fcmToken,
  }) async {
    final trimmedPhone = phoneNumber.trim();
    final trimmedOtp = otp.trim();
    final trimmedVerificationId = verificationId.trim();
    if (trimmedPhone.isEmpty ||
        trimmedOtp.isEmpty ||
        trimmedVerificationId.isEmpty) {
      throw AuthApiException(
        'Phone number, OTP and verificationId are required.',
      );
    }

    final body = <String, String>{
      'phone_number': trimmedPhone,
      'otp': trimmedOtp,
      'verificationId': trimmedVerificationId,
    };
    
    // Add FCM token if provided
    if (fcmToken != null && fcmToken.trim().isNotEmpty) {
      body['fcm_token'] = fcmToken.trim();
      print('✓ FCM token added to verify OTP request');
    } else {
      print('⚠ No FCM token provided for verify OTP request');
    }

    final response = await http
        .post(
          _verifyOtpUri,
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    final payload = _tryDecodePayload(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(
        _extractMessage(
          payload,
          fallback: 'Failed to verify OTP. (${response.statusCode})',
        ),
      );
    }
    if (payload.isEmpty && response.body.trim().isNotEmpty) {
      throw AuthApiException('Invalid response from server.');
    }
    final responseCode = int.tryParse(
      payload['responseCode']?.toString() ?? '',
    );
    if (responseCode != null && responseCode != 200) {
      throw AuthApiException(
        _extractMessage(payload, fallback: 'Failed to verify OTP.'),
      );
    }

    final data = payload['data'];
    final dataMap = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final accessToken = dataMap['access']?.toString() ?? '';
    final refreshToken = dataMap['refresh']?.toString() ?? '';
    if (accessToken.isEmpty || refreshToken.isEmpty) {
      throw AuthApiException('Invalid response: tokens are missing.');
    }

    final responsePhone = payload['phone_number']?.toString();
    return VerifyOtpResult(
      message: _extractMessage(payload, fallback: 'OTP verified successfully.'),
      phoneNumber: (responsePhone == null || responsePhone.trim().isEmpty)
          ? trimmedPhone
          : responsePhone.trim(),
      accessToken: accessToken,
      refreshToken: refreshToken,
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
