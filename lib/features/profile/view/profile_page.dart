import 'package:flutter/material.dart';
import 'package:porter_clone_user/core/services/profile_api_service.dart';
import 'package:porter_clone_user/core/storage/auth_local_storage.dart';
import 'package:porter_clone_user/features/sign_in/view/sign_in_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileApiService _profileApiService = const ProfileApiService();
  final TextEditingController _nameController = TextEditingController();
  
  bool _isLoading = true;
  bool _isEditMode = false;
  bool _isSaving = false;
  String _phoneNumber = '';
  String? _errorMessage;

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
      _errorMessage = null;
    });

    try {
      final accessToken = await AuthLocalStorage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw ProfileApiException('No access token found');
      }

      final profile = await _profileApiService.viewProfile(
        accessToken: accessToken,
      );

      if (!mounted) return;

      setState(() {
        _nameController.text = profile.fullName;
        _phoneNumber = profile.phoneNumber;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });

      // If unauthorized, logout
      if (e.toString().contains('Unauthorized') || 
          e.toString().contains('No access token')) {
        _logout(context);
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final accessToken = await AuthLocalStorage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw ProfileApiException('No access token found');
      }

      final result = await _profileApiService.updateProfile(
        accessToken: accessToken,
        fullName: _nameController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _nameController.text = result.profile.fullName;
        _phoneNumber = result.profile.phoneNumber;
        _isEditMode = false;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );

      // If unauthorized, logout
      if (e.toString().contains('Unauthorized')) {
        _logout(context);
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    await AuthLocalStorage.clearTokens();
    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInPage()),
      (route) => false,
    );
  }

  void _toggleEditMode() {
    setState(() {
      if (_isEditMode) {
        // Cancel edit - reload original data
        _loadProfile();
      }
      _isEditMode = !_isEditMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf4f4f4),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── HEADER ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(31, 20, 8, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(
                    child: Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF111111),
                      ),
                    ),
                  ),
                  // Edit/Save icon
                  if (!_isLoading)
                    IconButton(
                      icon: Icon(
                        _isEditMode ? Icons.check : Icons.edit_outlined,
                      ),
                      onPressed: _isSaving
                          ? null
                          : (_isEditMode ? _updateProfile : _toggleEditMode),
                      color: const Color(0xFF333333),
                      iconSize: 22,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  const SizedBox(width: 2),
                  // Logout icon
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

            // ─── SCROLLABLE CONTENT ─────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Failed to load profile',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadProfile,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                // Name field (editable)
                                _buildFieldRow(
                                  label: 'Name',
                                  controller: _nameController,
                                  readOnly: !_isEditMode,
                                ),
                                const SizedBox(height: 12),
                                // Mobile number field (read-only)
                                _buildFieldRow(
                                  label: 'Mobile number',
                                  value: _phoneNumber,
                                  readOnly: true,
                                ),
                                const SizedBox(height: 380),
                                // Contact Us section
                                _buildContactUsSection(),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldRow({
    required String label,
    TextEditingController? controller,
    String? value,
    required bool readOnly,
  }) {
    final effectiveController = controller ?? TextEditingController(text: value);
    
    return Container(
      width: double.infinity,
      color: const Color(0xFFF4F4F4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 16, 6),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF1B1B1B),
              ),
            ),
          ),

          // TextField
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              border: readOnly || !_isEditMode
                  ? null
                  : Border.all(color: const Color(0xFF333333), width: 1),
            ),
            child: TextField(
              controller: effectiveController,
              readOnly: readOnly,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: readOnly ? const Color(0xFF999999) : const Color(0xFF111111),
              ),
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactUsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Us',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '+91 95626 17519',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF111111),
                  ),
                ),
              ),
              Icon(
                Icons.phone,
                color: const Color(0xFF111111),
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
