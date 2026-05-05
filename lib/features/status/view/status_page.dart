import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:porter_clone_user/core/models/trip.dart';
import 'package:porter_clone_user/core/services/trips_api_service.dart';
import 'package:porter_clone_user/core/storage/auth_local_storage.dart';

class StatusPage extends StatefulWidget {
  const StatusPage({super.key});

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Trip> _ongoingTrips = [];
  List<Trip> _completedTrips = [];
  List<Trip> _pendingTrips = [];
  final TripsApiService _apiService = TripsApiService();

  @override
  void initState() {
    super.initState();
    _fetchTrips();
  }

  Future<void> _fetchTrips() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final accessToken = await AuthLocalStorage.getAccessToken();

      final tripsMap = await _apiService.getTrips(
        accessToken: accessToken,
      );

      setState(() {
        _ongoingTrips = tripsMap['ongoing'] ?? [];
        _completedTrips = tripsMap['completed'] ?? [];
        _pendingTrips = tripsMap['pending'] ?? [];
        _isLoading = false;
      });
    } on TripsApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshTrips() async {
    try {
      final accessToken = await AuthLocalStorage.getAccessToken();

      final tripsMap = await _apiService.getTrips(
        accessToken: accessToken,
      );

      setState(() {
        _ongoingTrips = tripsMap['ongoing'] ?? [];
        _completedTrips = tripsMap['completed'] ?? [];
        _pendingTrips = tripsMap['pending'] ?? [];
        _errorMessage = null;
      });
    } on TripsApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      final errorMsg = 'An unexpected error occurred: $e';
      setState(() {
        _errorMessage = errorMsg;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Widget _buildTabContent(List<Trip> trips, String status) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _ErrorState(
        errorMessage: _errorMessage!,
        onRetry: _fetchTrips,
      );
    }

    if (trips.isEmpty) {
      return _EmptyState(status: status);
    }

    return RefreshIndicator(
      onRefresh: _refreshTrips,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _TripCard(trip: trips[index]),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F2),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF2F2F2),
          elevation: 0,
          title: const Text(
            'Status',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: const Color(0xFF111827),
                  unselectedLabelColor: const Color(0xFF9CA3AF),
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: const [
                    Tab(text: 'Ongoing'),
                    Tab(text: 'Completed'),
                    Tab(text: 'Pending'),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildTabContent(_ongoingTrips, 'ongoing'),
            _buildTabContent(_completedTrips, 'completed'),
            _buildTabContent(_pendingTrips, 'pending'),
          ],
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});

  final Trip trip;

  String _extractCityName(String fullAddress) {
    return fullAddress.split(',').first.trim();
  }

  String _formatPickupTime(DateTime? pickupTime) {
    if (pickupTime == null) {
      return 'Time not set';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final pickupDate = DateTime(
      pickupTime.year,
      pickupTime.month,
      pickupTime.day,
    );

    final timeStr = DateFormat('h:mm a').format(pickupTime);

    if (pickupDate == today) {
      return 'Today $timeStr';
    } else if (pickupDate == tomorrow) {
      return 'Tomorrow $timeStr';
    } else {
      return DateFormat('MMM dd h:mm a').format(pickupTime);
    }
  }

  Color _getStatusBadgeColor() {
    switch (trip.tripStatus.toLowerCase()) {
      case 'ongoing':
        return const Color(0xFF3B82F6);
      case 'completed':
        return const Color(0xFF9CA3AF);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'accepted':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pickupCity = _extractCityName(trip.pickupLocation);
    final dropCity = _extractCityName(trip.dropLocation);
    final formattedTime = _formatPickupTime(trip.pickupTime);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Truck icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.local_shipping,
              color: Color(0xFF6B7280),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Trip details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route and status badge
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              pickupCity,
                              style: const TextStyle(
                                color: Color(0xFF111827),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_forward,
                            color: Color(0xFF6B7280),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              dropCity,
                              style: const TextStyle(
                                color: Color(0xFF111827),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusBadgeColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        trip.tripStatus,
                        style: TextStyle(
                          color: _getStatusBadgeColor(),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Vehicle size and time
                Text(
                  trip.vehicleSize,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedTime,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                // Location details
                Text(
                  'Pickup: ${trip.pickupLocation}',
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Drop: ${trip.dropLocation}',
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Chevron or checkmark
          Icon(
            trip.tripStatus.toLowerCase() == 'completed'
                ? Icons.check_circle
                : Icons.chevron_right,
            color: trip.tripStatus.toLowerCase() == 'completed'
                ? const Color(0xFF10B981)
                : const Color(0xFFD1D5DB),
            size: 24,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.local_shipping_outlined,
            color: Color(0xFFD1D5DB),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No $status trips',
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.errorMessage,
    required this.onRetry,
  });

  final String errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Color(0xFFEF4444),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
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
                onPressed: onRetry,
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
      ),
    );
  }
}
