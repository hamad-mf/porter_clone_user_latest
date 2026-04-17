import 'package:flutter/material.dart';
import 'package:porter_clone_user/core/storage/auth_local_storage.dart';
import 'package:porter_clone_user/features/sign_in/view/sign_in_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<void> _logout(BuildContext context) async {
    await AuthLocalStorage.clearTokens();
    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInPage()),
      (route) => false,
    );
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
                  // Edit icon (square with pencil)
                  IconButton(
                    icon: const Icon(Icons.edit_square),
                    onPressed: () {},
                    color: const Color(0xFF333333),
                    iconSize: 22,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                  const SizedBox(width: 2),
                  // Logout icon (circular arrow)
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
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Personal info fields ──────────────────────────────────
                      _buildFieldRow(label: 'Name', value: 'Arun Prakash'),
                      _buildFieldRow(
                        label: 'Mobile number',
                        value: '+91 98765 43210',
                      ),

                      const SizedBox(height: 20),

                      // ── My Driver Details section header ──────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 8,
                        ),
                        child: const Text(
                          'My Driver Details',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111111),
                          ),
                        ),
                      ),

                      _buildFieldRow(label: 'Name', value: 'Vipin'),
                      _buildFieldRow(label: 'Number', value: '+91 98765 43210'),

                      const SizedBox(height: 20),

                      // ── Aadhar section ────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: const Text(
                          'Aadhaar',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111111),
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: Row(
                          children: const [
                            Expanded(
                              child: _AadhaarCardWidget(label: 'Side 1'),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _AadhaarCardWidget(label: 'Side 2'),
                            ),
                          ],
                        ),
                      ),

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

  Widget _buildFieldRow({required String label, required String value}) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF4F4F4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
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

          // Read-only TextField
          SizedBox(
            height: 48,
            child: TextField(
              controller: TextEditingController(text: value),
              readOnly: true,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF999999),
              ),
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Aadhar Card Widget
// ─────────────────────────────────────────────────────────────────────────────
class _AadhaarCardWidget extends StatelessWidget {
  final String label;

  const _AadhaarCardWidget({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 90,
            width: double.infinity,
            color: const Color(0xFFE5E7EB),
            child: Image.asset(
              'assets/aadhaar_sample.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFEEEEEE),
                  child: const Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: Color(0xFFBBBBBB),
                      size: 30,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Color(0xFF888888),
          ),
        ),
      ],
    );
  }
}
