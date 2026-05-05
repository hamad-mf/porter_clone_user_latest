import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:porter_clone_user/core/models/accepted_driver.dart';
import 'package:porter_clone_user/core/services/accept_driver_api_service.dart';
import 'package:porter_clone_user/core/services/accepted_drivers_api_service.dart';
import 'package:porter_clone_user/core/services/trip_sharing_service.dart';
import 'package:porter_clone_user/core/storage/auth_local_storage.dart';
import 'package:porter_clone_user/core/storage/profile_local_storage.dart';
import 'package:porter_clone_user/features/new_trip/view/add_trip_page.dart';
import 'package:porter_clone_user/features/profile/view/profile_page.dart';
import 'package:porter_clone_user/features/sign_in/view/sign_in_page.dart';
import 'package:porter_clone_user/features/status/view/status_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  late final List<Widget> _tabs = [
    const _DashboardHomeTab(),
    _AddTripScreen(onTripAdded: () => _onNavTap(0)),
    const _StatusScreen(),
    const _ProfileScreen(),
  ];

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: _tabs),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onNavTap,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedItemColor: const Color(0xFF111827),
            unselectedItemColor: const Color(0xFFC4C4C4),
            selectedLabelStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_filled),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.add_circle),
                label: 'Add Trip',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment),
                label: 'Status',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHomeTab extends StatefulWidget {
  const _DashboardHomeTab();

  @override
  State<_DashboardHomeTab> createState() => _DashboardHomeTabState();
}

class _DashboardHomeTabState extends State<_DashboardHomeTab> {
  bool _isLoading = true;
  String? _errorMessage;
  List<AcceptedDriver> _drivers = [];
  final AcceptedDriversApiService _apiService = AcceptedDriversApiService();

  @override
  void initState() {
    super.initState();
    _fetchAcceptedDrivers();
  }

  Future<void> _fetchAcceptedDrivers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Retrieve access token from AuthLocalStorage
      final accessToken = await AuthLocalStorage.getAccessToken();

      // Call AcceptedDriversApiService.getAcceptedDrivers()
      final drivers = await _apiService.getAcceptedDrivers(
        accessToken: accessToken,
      );

      // Update state with fetched drivers
      setState(() {
        _drivers = drivers;
        _isLoading = false;
      });
    } on AcceptedDriversApiException catch (e) {
      // Handle API exceptions with error message
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      // Handle unexpected errors
      setState(() {
        _errorMessage = 'An unexpected error occurred: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshDrivers() async {
    try {
      // Retrieve access token from AuthLocalStorage
      final accessToken = await AuthLocalStorage.getAccessToken();

      // Call AcceptedDriversApiService.getAcceptedDrivers()
      final drivers = await _apiService.getAcceptedDrivers(
        accessToken: accessToken,
      );

      // Update state with fetched drivers
      setState(() {
        _drivers = drivers;
        _errorMessage = null;
      });
    } on AcceptedDriversApiException catch (e) {
      // Handle API exceptions - preserve existing data, show error
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      // Handle unexpected errors - preserve existing data, show error
      setState(() {
        _errorMessage = 'An unexpected error occurred: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.05;

    return RefreshIndicator(
      onRefresh: _refreshDrivers,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          16,
          horizontalPadding,
          16,
        ),
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(child: _WelcomeHeader()),
              // Notification icon with red badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.notifications,
                      color: Color(0xFF111827),
                      size: 22,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              // GPS icon in rounded box
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.gps_fixed,
                  color: Color(0xFF111827),
                  size: 20,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Create Trip card with truck image background
          _CreateTripCard(),

          const SizedBox(height: 20),

          // Current Requests header
          const Text(
            'Current Requests',
            style: TextStyle(
              color: Color(0xFF1F1F1F),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 12),

          // Display accepted drivers based on state
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFEF4444),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _fetchAcceptedDrivers,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111827),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Retry',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (_drivers.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    color: Color(0xFFD1D5DB),
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No current requests',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._drivers.map(
              (driver) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AcceptedDriverCard(
                  driver: driver,
                  onAcceptSuccess: _fetchAcceptedDrivers,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WelcomeHeader extends StatefulWidget {
  const _WelcomeHeader();

  @override
  State<_WelcomeHeader> createState() => _WelcomeHeaderState();
}

class _WelcomeHeaderState extends State<_WelcomeHeader> {
  String _displayName = 'User';

  @override
  void initState() {
    super.initState();
    _loadProfileName();
  }

  Future<void> _loadProfileName() async {
    final profile = await ProfileLocalStorage.getProfile();
    if (profile?.fullName != null && profile!.fullName!.trim().isNotEmpty) {
      setState(() {
        _displayName = profile.fullName!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ProfilePage(),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome Back',
            style: TextStyle(
              color: Color(0xFF888888),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _displayName,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateTripCard extends StatefulWidget {
  const _CreateTripCard({super.key});

  @override
  State<_CreateTripCard> createState() => _CreateTripCardState();
}

class _CreateTripCardState extends State<_CreateTripCard> {
  String? _bannerImageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBannerImage();
  }

  Future<void> _fetchBannerImage() async {
    try {
      print('🔵 Fetching banner from API...');
      final response = await http.get(
        Uri.parse('https://lorry.workwista.com/api/users/banner/'),
      );

      print('🔵 Banner API status: ${response.statusCode}');
      print('🔵 Banner API response: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        
        // API returns an array, get the first item
        String? bannerPath;
        if (decoded is List && decoded.isNotEmpty) {
          bannerPath = decoded[0]['banner_image'] as String?;
        } else if (decoded is Map) {
          bannerPath = decoded['banner_image'] as String?;
        }
        
        print('🔵 Banner path from API: $bannerPath');
        
        // Convert relative path to full URL
        String? fullUrl;
        if (bannerPath != null && bannerPath.isNotEmpty) {
          if (bannerPath.startsWith('http')) {
            fullUrl = bannerPath;
          } else {
            // Remove leading slash if present
            final cleanPath = bannerPath.startsWith('/') ? bannerPath.substring(1) : bannerPath;
            fullUrl = 'https://lorry.workwista.com/$cleanPath';
          }
        }
        
        print('🔵 Full banner URL: $fullUrl');
        
        setState(() {
          _bannerImageUrl = fullUrl;
          _isLoading = false;
        });
      } else {
        print('❌ Banner API failed with status: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Banner API error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openAddTrip(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AddTripPage()));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Card height proportional to width
    final cardHeight = screenWidth * 0.48;

    return GestureDetector(
      onTap: () => _openAddTrip(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: double.infinity,
          height: cardHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Banner image from API or fallback
              if (_isLoading)
                Container(
                  color: const Color(0xFF2D3748),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white38,
                    ),
                  ),
                )
              else if (_bannerImageUrl != null && _bannerImageUrl!.isNotEmpty)
                Image.network(
                  _bannerImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/truck_banner.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF2D3748),
                      child: const Center(
                        child: Icon(
                          Icons.local_shipping,
                          size: 60,
                          color: Colors.white38,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Image.asset(
                  'assets/images/truck_banner.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF2D3748),
                    child: const Center(
                      child: Icon(
                        Icons.local_shipping,
                        size: 60,
                        color: Colors.white38,
                      ),
                    ),
                  ),
                ),

              // Dark gradient overlay (top only for header bar)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xDD111827), Color(0x00111827)],
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_shipping_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Create Trip',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyTripScreen extends StatelessWidget {
  const _MyTripScreen();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand();
  }
}

class _AddTripScreen extends StatelessWidget {
  const _AddTripScreen({this.onTripAdded});

  final VoidCallback? onTripAdded;

  @override
  Widget build(BuildContext context) {
    return AddTripPage(onSuccess: onTripAdded);
  }
}

class _StatusScreen extends StatelessWidget {
  const _StatusScreen();

  @override
  Widget build(BuildContext context) {
    return const StatusPage();
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthLocalStorage.clearTokens();
    await ProfileLocalStorage.clearProfile();
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const SignInPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7),
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCard(
              children: [
                _buildLabeledField(label: 'Name', hint: 'Arun Prakash'),
                const Divider(height: 1, indent: 16),
                _buildLabeledField(
                  label: 'Mobile number',
                  hint: '+91 98765 43210',
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'My Driver Details',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            _buildCard(
              children: [
                _buildLabeledField(label: 'Name', hint: 'Vipin'),
                const Divider(height: 1, indent: 16),
                _buildLabeledField(label: 'Number', hint: '+91 98765 43210'),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Aadhar',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            _buildCard(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(child: _buildAadharSlot(label: 'Side 1')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildAadharSlot(label: 'Side 2')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildLabeledField({required String label, required String hint}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            hint,
            style: const TextStyle(fontSize: 16, color: Color(0xFFBBBBBB)),
          ),
        ],
      ),
    );
  }

  Widget _buildAadharSlot({required String label}) {
    return Column(
      children: [
        Container(
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(Icons.credit_card, color: Colors.grey, size: 32),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }
}

class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen();

  @override
  Widget build(BuildContext context) => const ProfilePage();
}

class _AcceptedDriverCard extends StatefulWidget {
  const _AcceptedDriverCard({
    required this.driver,
    required this.onAcceptSuccess,
  });

  final AcceptedDriver driver;
  final VoidCallback onAcceptSuccess;

  @override
  State<_AcceptedDriverCard> createState() => _AcceptedDriverCardState();
}

class _AcceptedDriverCardState extends State<_AcceptedDriverCard> {
  bool _isAccepting = false;
  final AcceptDriverApiService _acceptApiService =
      const AcceptDriverApiService();

  String _extractCityName(String location) {
    // Extract city name from full address (e.g., "Azhicode, Kerala, India" -> "Azhicode")
    return location.split(',').first.trim();
  }

  Future<void> _showAcceptConfirmationDialog(BuildContext context) async {
    if (widget.driver.acceptances.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xffffffff),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text(
            'Accept ${widget.driver.fullName}?',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Accept',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await _handleAcceptDriver(context);
    }
  }

  Future<void> _handleAcceptDriver(BuildContext context) async {
    if (_isAccepting || widget.driver.acceptances.isEmpty) {
      return;
    }

    setState(() => _isAccepting = true);

    try {
      final acceptance = widget.driver.acceptances.first;
      final accessToken = await AuthLocalStorage.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        throw AcceptDriverApiException(
          'Access token not found. Please login again.',
        );
      }

      await _acceptApiService.acceptDriver(
        tripId: acceptance.tripId,
        acceptanceId: acceptance.acceptanceId,
        accessToken: accessToken,
      );

      if (!context.mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.driver.fullName} accepted successfully!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      // Refresh the list
      widget.onAcceptSuccess();
    } on AcceptDriverApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept driver: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isAccepting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the first acceptance for display
    if (widget.driver.acceptances.isEmpty) {
      return const SizedBox.shrink();
    }

    final acceptance = widget.driver.acceptances.first;
    final pickupCity = _extractCityName(acceptance.pickupLocation);
    final dropCity = _extractCityName(acceptance.dropLocation);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Driver name
          Text(
            widget.driver.fullName,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 10),

          // Route row (Pickup → Drop)
          Row(
            children: [
              Text(
                pickupCity,
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward,
                color: Color(0xFF374151),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                dropCity,
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 12),

          // Bottom row: distance + vehicle size + Accept button
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (acceptance.distanceToPickup != null && acceptance.distanceToPickup!.isNotEmpty)
                      Text(
                        '${acceptance.distanceToPickup} km away',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (acceptance.distanceToPickup != null && acceptance.distanceToPickup!.isNotEmpty)
                      const SizedBox(height: 4),
                    if (acceptance.vehicleSize != null && acceptance.vehicleSize!.isNotEmpty)
                      Text(
                        '${acceptance.vehicleSize} ft Truck',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: 105,
                height: 36,
                child: ElevatedButton(
                  onPressed: _isAccepting
                      ? null
                      : () => _showAcceptConfirmationDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111827),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFD1D5DB),
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isAccepting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Accept',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
