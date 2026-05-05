import 'package:flutter/material.dart';
import 'package:porter_clone_user/core/models/user_profile.dart';
import 'package:porter_clone_user/core/services/profile_api_service.dart';
import 'package:porter_clone_user/core/storage/auth_local_storage.dart';
import 'package:porter_clone_user/core/storage/profile_local_storage.dart';
import 'package:porter_clone_user/features/sign_in/view/sign_in_page.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserProfile? _profile;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  final TextEditingController _nameController = TextEditingController();
  final ProfileApiService _profileApiService = const ProfileApiService();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final accessToken = await AuthLocalStorage.getAccessToken();
      if (accessToken == null || accessToken.trim().isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final profile = await _profileApiService.viewProfile(
        accessToken: accessToken,
      );

      setState(() {
        _profile = profile;
        _nameController.text = profile.fullName ?? '';
        _isLoading = false;
      });
    } on ProfileApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;

    final fullName = _nameController.text.trim();
    if (fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final accessToken = await AuthLocalStorage.getAccessToken();
      if (accessToken == null || accessToken.trim().isEmpty) {
        throw ProfileApiException(
          'Authentication required. Please log in again.',
        );
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

      if (!mounted) return;

      setState(() {
        _profile = profile;
        _isEditing = false;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } on ProfileApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
      setState(() => _isSaving = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to update profile. Please try again.'),
        ),
      );
      setState(() => _isSaving = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    await AuthLocalStorage.clearTokens();
    await ProfileLocalStorage.clearProfile();
    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInPage()),
      (route) => false,
    );
  }

  Future<void> _launchPhoneDialer() async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: '+919562617519',
    );

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone calling is not available on this device.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open phone dialer. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf4f4f4),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(31, 20, 8, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF111111),
                      ),
                    ),
                  ),
                  if (_isEditing)
                    IconButton(
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF333333),
                              ),
                            )
                          : const Icon(Icons.check),
                      onPressed: _isSaving ? null : _saveProfile,
                      color: const Color(0xFF333333),
                      iconSize: 22,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.edit_square),
                      onPressed: () {
                        setState(() {
                          _isEditing = true;
                          _nameController.text = _profile?.fullName ?? '';
                        });
                      },
                      color: const Color(0xFF333333),
                      iconSize: 22,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  const SizedBox(width: 2),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded),
                    onPressed: () => _logout(context),
                    color: const Color(0xFF333333),
                    iconSize: 22,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldRow(
                              label: 'Name',
                              value: _profile?.fullName ?? 'Not set',
                              isEditable: _isEditing,
                              controller: _nameController,
                            ),
                            _buildFieldRow(
                              label: 'Mobile number',
                              value: _profile?.mobileNumber ?? 'Not set',
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _buildContactSection(),
            ),  
          ],
        ),
      ),
    );
  }

  Widget _buildFieldRow({
    required String label,
    required String value,
    bool isEditable = false,
    TextEditingController? controller,
  }) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF4F4F4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 16, 6),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w300,
                color: Color(0xFF1B1B1B),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: TextField(
              controller: controller ?? TextEditingController(text: value),
              readOnly: !isEditable,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isEditable
                    ? const Color(0xFF111827)
                    : const Color(0xFF999999),
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: isEditable
                    ? OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF111827)),
                        borderRadius: BorderRadius.zero,
                      )
                    : InputBorder.none,
                enabledBorder: isEditable
                    ? OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.zero,
                      )
                    : InputBorder.none,
                focusedBorder: isEditable
                    ? OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF111827)),
                        borderRadius: BorderRadius.zero,
                      )
                    : InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildContactSection() {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: const Color(0xFFFFFFFF),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Us',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w300,
            color: Color(0xFF1B1B1B),
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: _launchPhoneDialer,
          borderRadius: BorderRadius.circular(8),
          splashColor: const Color(0xFFE5E7EB),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child:Row(
  children: [
    const Text(
      '+91 95626 17519',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Color(0xFF111827),
      ),
    ),
    const Spacer(),
    const Icon(Icons.call, size: 20, color: Color(0xFF111827)),
  ],
),
          ),
        ),
      ],
    ),
  );
}
}
