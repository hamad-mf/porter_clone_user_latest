import 'dart:async';

import 'package:flutter/material.dart';

import 'package:porter_clone_user/core/services/auth_api_service.dart';
import 'package:porter_clone_user/features/verification/view/verification_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({
    super.key,
    this.redirectTripId,
  });

  final String? redirectTripId;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _mobileController = TextEditingController();
  final String _selectedCountryCode = '+91';
  final AuthApiService _authApiService = const AuthApiService();
  bool _isSendingOtp = false;

  String _normalizedPhoneNumber() {
    return _mobileController.text.replaceAll(RegExp(r'[^0-9]'), '').trim();
  }

  Future<void> _sendOtp() async {
    if (_isSendingOtp) {
      return;
    }

    final phoneNumber = _normalizedPhoneNumber();
    if (phoneNumber.isEmpty) {
      _showSnackBar('Enter a valid phone number.');
      return;
    }

    setState(() => _isSendingOtp = true);
    try {
      final sendOtpResult = await _authApiService.sendOtp(
        phoneNumber: phoneNumber,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => VerificationPage(
            phoneNumber: sendOtpResult.phoneNumber,
            verificationId: sendOtpResult.verificationId,
            redirectTripId: widget.redirectTripId,
          ),
        ),
      );
    } on AuthApiException catch (error) {
      _showSnackBar(error.message);
    } on TimeoutException {
      _showSnackBar('Request timed out. Please try again.');
    } catch (_) {
      _showSnackBar('Unable to send OTP. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSendingOtp = false);
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
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  screenHeight -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: screenHeight * 0.04),

                  // Title
                  Center(
                    child: Text(
                      'Truck map',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                        fontSize: 26,
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.07),

                  // Welcome
                  Text(
                    'Welcome',
                    style: textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w700,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Please input your details',
                    style: textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // Phone Input Row — two SEPARATE boxes
                  Row(
                    children: [
                      // Country code box
                      GestureDetector(
                        onTap: () {
                          // Country picker logic
                        },
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _selectedCountryCode,
                                style: const TextStyle(
                                  color: Color(0xFF374151),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.arrow_drop_down,
                                size: 20,
                                color: Color(0xFF6B7280),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Mobile number input box
                      Expanded(
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.centerLeft,
                          child: TextField(
                            controller: _mobileController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(
                              color: Color(0xFF1F2937),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Mobile number...',
                              hintStyle: TextStyle(
                                color: Color(0xFFC3C6CB),
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: screenHeight * 0.04),

                  // Send OTP Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _sendOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111827),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Send OTP',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.04),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
