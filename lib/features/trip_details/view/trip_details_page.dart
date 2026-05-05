import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/trip.dart';
import '../../../core/services/trip_details_api_service.dart';
import '../../../core/storage/auth_local_storage.dart';

class TripDetailsPage extends StatefulWidget {
  final String tripId;
  final bool isFromDeepLink;

  const TripDetailsPage({
    super.key,
    required this.tripId,
    this.isFromDeepLink = false,
  });

  @override
  State<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  final TripDetailsApiService _apiService = const TripDetailsApiService();
  bool _isLoading = true;
  String? _errorMessage;
  Trip? _trip;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthAndFetchTrip();
  }

  Future<void> _checkAuthAndFetchTrip() async {
    // Check authentication status
    final accessToken = await AuthLocalStorage.getAccessToken();
    setState(() {
      _isLoggedIn = accessToken != null && accessToken.isNotEmpty;
    });

    _fetchTripDetails();
  }

  Future<void> _fetchTripDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final accessToken = await AuthLocalStorage.getAccessToken();
      final trip = await _apiService.getTripById(
        tripId: widget.tripId,
        accessToken: accessToken,
      );

      setState(() {
        _trip = trip;
        _isLoading = false;
      });
    } on TripNotFoundException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } on TripDetailsApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _handleBackNavigation() {
    if (widget.isFromDeepLink && _isLoggedIn) {
      // Navigate to home/dashboard
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
        centerTitle: true,
        leading: widget.isFromDeepLink && !_isLoggedIn
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _handleBackNavigation,
              ),
        automaticallyImplyLeading: !(widget.isFromDeepLink && !_isLoggedIn),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_trip == null) {
      return const Center(
        child: Text('No trip data available'),
      );
    }

    return _buildTripDetails();
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _fetchTripDetails,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/',
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Go Home'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripDetails() {
    final trip = _trip!;
    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            title: 'Trip Information',
            children: [
              _buildInfoRow(
                icon: Icons.location_on,
                label: 'Pickup Location',
                value: trip.pickupLocation,
              ),
              const Divider(),
              _buildInfoRow(
                icon: Icons.location_on_outlined,
                label: 'Drop Location',
                value: trip.dropLocation,
              ),
              const Divider(),
              _buildInfoRow(
                icon: Icons.access_time,
                label: 'Pickup Time',
                value: trip.pickupTime != null 
                    ? dateFormat.format(trip.pickupTime!)
                    : 'Not set',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Load Details',
            children: [
              _buildInfoRow(
                icon: Icons.inventory_2,
                label: 'Load Size',
                value: trip.loadSize,
              ),
              const Divider(),
              _buildInfoRow(
                icon: Icons.category,
                label: 'Load Type',
                value: trip.loadType,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Vehicle Requirements',
            children: [
              _buildInfoRow(
                icon: Icons.local_shipping,
                label: 'Vehicle Size',
                value: trip.vehicleSize,
              ),
              const Divider(),
              _buildInfoRow(
                icon: Icons.directions_car,
                label: 'Body Type',
                value: trip.bodyType,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Payment & Contact',
            children: [
              _buildInfoRow(
                icon: Icons.currency_rupee,
                label: 'Amount',
                value: '₹${trip.amount}',
              ),
              const Divider(),
              _buildInfoRow(
                icon: Icons.person,
                label: 'Contact Name',
                value: trip.name,
              ),
              const Divider(),
              _buildInfoRow(
                icon: Icons.phone,
                label: 'Contact Number',
                value: trip.contactNumber,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Status',
            children: [
              _buildInfoRow(
                icon: Icons.info_outline,
                label: 'Trip Status',
                value: trip.tripStatus,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleAcceptTrip,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Accept Trip',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleAcceptTrip() {
    if (!_isLoggedIn) {
      // Navigate to login with trip ID preserved
      Navigator.of(context).pushNamed(
        '/sign-in',
        arguments: {
          'redirectTripId': widget.tripId,
          'shouldAccept': true,
        },
      );
    } else {
      // TODO: Implement accept trip logic
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Accept trip functionality to be implemented'),
        ),
      );
    }
  }
}
