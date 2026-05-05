import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/services/profile_api_service.dart';
import '../../../core/storage/auth_local_storage.dart';
import '../../../core/storage/profile_local_storage.dart';
import '../../dashboard/view/dashboard_page.dart';

class ProfileCompletionPage extends StatefulWidget {
  const ProfileCompletionPage({super.key});

  @override
  State<ProfileCompletionPage> createState() => _ProfileCompletionPageState();
}

class _ProfileCompletionPageState extends State<ProfileCompletionPage> {
  final TextEditingController _nameController = TextEditingController();
  final ProfileApiService _profileApiService = const ProfileApiService();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    if (_isSubmitting) {
      return;
    }

    final fullName = _nameController.text.trim();
    if (fullName.isEmpty) {
      _showSnackBar('Please enter your full name.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final accessToken = await AuthLocalStorage.getAccessToken();
      if (accessToken == null || accessToken.trim().isEmpty) {
        _showSnackBar('Authentication required. Please log in again.');
        return;
      }

      // Update profile
      await _profileApiService.updateProfile(
        accessToken: accessToken,
        fullName: fullName,
      );

      // Fetch updated profile
      final profile = await _profileApiService.viewProfile(
        accessToken: accessToken,
      );

      // Cache profile
      await ProfileLocalStorage.saveProfile(profile);

      if (!mounted) {
        return;
      }

      // Navigate to dashboard
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const DashboardPage()),
        (route) => false,
      );
    } on ProfileApiException catch (error) {
      _showSnackBar(error.message);
    } on TimeoutException {
      _showSnackBar('Request timed out. Please try again.');
    } catch (_) {
      _showSnackBar('Unable to update profile. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double horizontalPadding = screenWidth * 0.06;

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
                      'Complete Your Profile',
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
                      'Please enter your full name to continue',
                      style: textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.04),

                    // Name input field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _nameController,
                        keyboardType: TextInputType.name,
                        textCapitalization: TextCapitalization.words,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter your full name',
                          hintStyle: TextStyle(
                            color: const Color(0xFF9CA3AF).withOpacity(0.6),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Continue button pinned at bottom
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
                  onPressed: _isSubmitting ? null : _submitProfile,
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
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Continue',
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
