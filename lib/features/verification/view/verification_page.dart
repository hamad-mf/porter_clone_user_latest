import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:porter_clone_user/core/services/auth_api_service.dart';
import 'package:porter_clone_user/core/storage/auth_local_storage.dart';
import 'package:porter_clone_user/features/dashboard/view/dashboard_page.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({
    required this.phoneNumber,
    required this.verificationId,
    super.key,
  });

  final String phoneNumber;
  final String verificationId;

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  static const int _otpLength = 6;

  final List<TextEditingController> _otpControllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(
    _otpLength,
    (_) => FocusNode(),
  );
  final AuthApiService _authApiService = const AuthApiService();
  late String _verificationId;
  bool _isVerifying = false;
  bool _isResending = false;

  // Track which boxes have a value for styling
  final List<String> _otpValues = List.filled(_otpLength, '');

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    // Listen to each controller to update styling state
    for (int i = 0; i < _otpLength; i++) {
      _otpControllers[i].addListener(() {
        setState(() {
          _otpValues[i] = _otpControllers[i].text;
        });
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged(int index, String value) {
    if (value.length == 1) {
      // Move forward
      if (index < _otpLength - 1) {
        _otpFocusNodes[index + 1].requestFocus();
      } else {
        _otpFocusNodes[index].unfocus();
      }
    } else if (value.isEmpty && index > 0) {
      // Move back on delete
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  void _openDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const DashboardPage()),
    );
  }

  String _enteredOtp() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  String _maskedPhoneNumber() {
    final digits = widget.phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 4) {
      return widget.phoneNumber;
    }

    final firstTwo = digits.substring(0, 2);
    final lastTwo = digits.substring(digits.length - 2);
    final hiddenLength = digits.length - 4;
    return '+91 $firstTwo ${List.filled(hiddenLength, '*').join()}$lastTwo';
  }

  Future<void> _verifyOtp() async {
    if (_isVerifying) {
      return;
    }

    final otp = _enteredOtp();
    if (otp.length != _otpLength) {
      _showSnackBar('Please enter the full OTP.');
      return;
    }

    setState(() => _isVerifying = true);
    try {
      // Get FCM token
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
        debugPrint('FCM Token retrieved: $fcmToken');
      } catch (e) {
        // If FCM token retrieval fails, continue without it
        debugPrint('Failed to get FCM token: $e');
      }

      debugPrint('Verifying OTP with FCM token: ${fcmToken != null ? "Token present (${fcmToken.substring(0, 20)}...)" : "No token"}');
      final verifyOtpResult = await _authApiService.verifyOtp(
        phoneNumber: widget.phoneNumber,
        otp: otp,
        verificationId: _verificationId,
        fcmToken: fcmToken,
      );
      await AuthLocalStorage.saveTokens(
        accessToken: verifyOtpResult.accessToken,
        refreshToken: verifyOtpResult.refreshToken,
      );
      if (!mounted) {
        return;
      }
      _openDashboard();
    } on AuthApiException catch (error) {
      _showSnackBar(error.message);
    } on TimeoutException {
      _showSnackBar('Request timed out. Please try again.');
    } catch (_) {
      _showSnackBar('Unable to verify OTP. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Future<void> _resendOtp() async {
    if (_isResending) {
      return;
    }

    setState(() => _isResending = true);
    try {
      final sendOtpResult = await _authApiService.sendOtp(
        phoneNumber: widget.phoneNumber,
      );
      if (!mounted) {
        return;
      }
      _verificationId = sendOtpResult.verificationId;
      for (final controller in _otpControllers) {
        controller.clear();
      }
      _showSnackBar(sendOtpResult.message);
    } on AuthApiException catch (error) {
      _showSnackBar(error.message);
    } on TimeoutException {
      _showSnackBar('Request timed out. Please try again.');
    } catch (_) {
      _showSnackBar('Unable to resend OTP. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final double horizontalPadding = screenWidth * 0.06;
    final double availableWidth =
        screenWidth - (horizontalPadding * 2) - (5 * 10);
    final double otpBoxSize = (availableWidth / _otpLength).clamp(42.0, 56.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: screenHeight * 0.025),

                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(
                        Icons.chevron_left,
                        size: 28,
                        color: Color(0xFF111827),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.03),

                    // Title
                    Text(
                      'OTP Verification',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                        fontSize: 28,
                        height: 1.1,
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.012),

                    // Subtitle
                    Text(
                      'Enter the verification code we just sent to your number\n${_maskedPhoneNumber()}.',
                      style: textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.04),

                    // OTP Boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: List.generate(_otpLength * 2 - 1, (i) {
                        if (i.isOdd) return SizedBox(width: 10);
                        final index = i ~/ 2;
                        final isFilled = _otpValues[index].isNotEmpty;
                        return _OtpBox(
                          controller: _otpControllers[index],
                          focusNode: _otpFocusNodes[index],
                          size: otpBoxSize,
                          isFilled: isFilled,
                          onChanged: (value) => _onOtpChanged(index, value),
                          // Handle backspace on already-empty box
                          onKeyEvent: (event) {
                            if (event is KeyDownEvent &&
                                event.logicalKey ==
                                    LogicalKeyboardKey.backspace &&
                                _otpControllers[index].text.isEmpty &&
                                index > 0) {
                              _otpFocusNodes[index - 1].requestFocus();
                              // Clear previous box
                              _otpControllers[index - 1].clear();
                            }
                          },
                        );
                      }),
                    ),

                    SizedBox(height: screenHeight * 0.025),

                    // Resend row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Didn't receive code?  ",
                          style: textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF6B7280),
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                          ),
                        ),
                        GestureDetector(
                          onTap: _isResending ? null : _resendOtp,
                          child: _isResending
                              ? const SizedBox(
                                  width: 13,
                                  height: 13,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: Color(0xFF111827),
                                  ),
                                )
                              : Text(
                                  'Resend',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF111827),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    decoration: TextDecoration.underline,
                                    decorationColor: const Color(0xFF111827),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Verify button pinned at bottom
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                12,
                horizontalPadding,
                screenHeight * 0.025,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111827),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF111827),
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Verify',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.size,
    required this.isFilled,
    required this.onChanged,
    required this.onKeyEvent,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final double size;
  final bool isFilled;
  final ValueChanged<String> onChanged;
  final ValueChanged<KeyEvent> onKeyEvent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        // Filled box: white bg + dark border; Empty box: grey fill + no border
        color: isFilled ? Colors.white : const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(10),
        border: isFilled
            ? Border.all(color: const Color(0xFF111827), width: 1.5)
            : null,
      ),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: onKeyEvent,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          cursorColor: const Color(0xFF111827),
          style: TextStyle(
            color: const Color(0xFF111827),
            fontSize: size * 0.44,
            fontWeight: FontWeight.w600,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(1),
          ],
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            counterText: '',
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
