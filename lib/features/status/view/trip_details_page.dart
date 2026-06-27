import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:porter_clone_user/core/models/trip.dart';
import 'package:porter_clone_user/core/services/trip_driver_location_api_service.dart';
import 'package:porter_clone_user/core/storage/auth_local_storage.dart';

class TripDetailsPage extends StatefulWidget {
  const TripDetailsPage({super.key, required this.trip});

  final Trip trip;

  @override
  State<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  final TripDriverLocationApiService _locationApiService =
      const TripDriverLocationApiService();

  GoogleMapController? _mapController;
  TripDriverLocation? _location;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDriverLocation();
  }

  Future<void> _fetchDriverLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final accessToken = await AuthLocalStorage.getAccessToken();
      final location = await _locationApiService.getDriverLocation(
        tripId: widget.trip.id,
        accessToken: accessToken,
      );

      if (!mounted) {
        return;
      }

      final latLng = LatLng(location.latitude, location.longitude);
      setState(() {
        _location = location;
        _isLoading = false;
      });

      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(latLng, 15),
      );
    } on TripDriverLocationApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Failed to fetch driver location: $error';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = _location;
    final latLng = location == null
        ? const LatLng(20.5937, 78.9629)
        : LatLng(location.latitude, location.longitude);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F2),
        elevation: 0,
        foregroundColor: const Color(0xFF111827),
        title: const Text(
          'Trip Details',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        actions: [
          _AlertDriverButton(tripId: widget.trip.id),
          IconButton(
            tooltip: 'Refresh location',
            onPressed: _isLoading ? null : _fetchDriverLocation,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDriverLocation,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _TripSummary(trip: widget.trip),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 320,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: latLng,
                        zoom: location == null ? 4 : 15,
                      ),
                      markers: location == null
                          ? const <Marker>{}
                          : {
                              Marker(
                                markerId: const MarkerId('driver-location'),
                                position: latLng,
                                infoWindow: InfoWindow(
                                  title: location.driverName.isEmpty
                                      ? 'Driver'
                                      : location.driverName,
                                ),
                              ),
                            },
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      onMapCreated: (controller) {
                        _mapController = controller;
                        final currentLocation = _location;
                        if (currentLocation != null) {
                          controller.animateCamera(
                            CameraUpdate.newLatLngZoom(
                              LatLng(
                                currentLocation.latitude,
                                currentLocation.longitude,
                              ),
                              15,
                            ),
                          );
                        }
                      },
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: _ZoomControls(
                        onZoomIn: () async {
                          final controller = _mapController;
                          if (controller != null) {
                            await controller.animateCamera(
                              CameraUpdate.zoomIn(),
                            );
                          }
                        },
                        onZoomOut: () async {
                          final controller = _mapController;
                          if (controller != null) {
                            await controller.animateCamera(
                              CameraUpdate.zoomOut(),
                            );
                          }
                        },
                      ),
                    ),
                    if (_isLoading)
                      Container(
                        color: Colors.white.withValues(alpha: 0.72),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    if (!_isLoading && _errorMessage != null)
                      Container(
                        color: Colors.white.withValues(alpha: 0.9),
                        padding: const EdgeInsets.all(20),
                        child: _DriverLocationError(
                          message: _errorMessage!,
                          onRetry: _fetchDriverLocation,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _DriverInfoCard(
              location: location,
              isLoading: _isLoading,
              onRefresh: _fetchDriverLocation,
            ),
          ],
        ),
      ),
    );
  }
}

class _TripSummary extends StatelessWidget {
  const _TripSummary({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trip.tripStatus,
            style: const TextStyle(
              color: Color(0xFF2563EB),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            trip.pickupLocation,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          const Icon(
            Icons.arrow_downward_rounded,
            size: 14,
            color: Color(0xFF6B7280),
          ),
          const SizedBox(height: 2),
          Text(
            trip.dropLocation,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _DriverInfoCard extends StatelessWidget {
  const _DriverInfoCard({
    required this.location,
    required this.isLoading,
    required this.onRefresh,
  });

  final TripDriverLocation? location;
  final bool isLoading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final driverName = location?.driverName.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Driver',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            driverName == null || driverName.isEmpty
                ? 'Driver not available'
                : driverName,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (location != null) ...[
            const SizedBox(height: 8),
            Text(
              '${location!.latitude}, ${location!.longitude}',
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111827),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(isLoading ? 'Refreshing...' : 'Refresh Location'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverLocationError extends StatelessWidget {
  const _DriverLocationError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.location_off_outlined,
          color: Color(0xFFEF4444),
          size: 44,
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 14,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
        ),
      ],
    );
  }
}

class _ZoomControls extends StatelessWidget {
  const _ZoomControls({
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onZoomIn,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.add_rounded,
                  color: Color(0xFF111827),
                  size: 24,
                ),
              ),
            ),
          ),
          Container(
            width: 44,
            height: 1,
            color: const Color(0xFFE5E7EB),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onZoomOut,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(8),
              ),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.remove_rounded,
                  color: Color(0xFF111827),
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertDriverButton extends StatefulWidget {
  const _AlertDriverButton({required this.tripId});

  final String tripId;

  @override
  State<_AlertDriverButton> createState() => _AlertDriverButtonState();
}

class _AlertDriverButtonState extends State<_AlertDriverButton> {
  Timer? _timer;
  int _secondsRemaining = 0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    final expirationMs = prefs.getInt('alert_driver_cooldown_${widget.tripId}');
    if (expirationMs != null) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final remaining = (expirationMs - nowMs) ~/ 1000;
      if (remaining > 0) {
        setState(() {
          _secondsRemaining = remaining;
          _isInitialized = true;
        });
        _startTimer();
      } else {
        setState(() {
          _secondsRemaining = 0;
          _isInitialized = true;
        });
      }
    } else {
      setState(() {
        _secondsRemaining = 0;
        _isInitialized = true;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
        });
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  Future<void> _onPressed() async {
    const cooldownDuration = Duration(minutes: 5);
    final expiration = DateTime.now().add(cooldownDuration);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('alert_driver_cooldown_${widget.tripId}', expiration.millisecondsSinceEpoch);

    setState(() {
      _secondsRemaining = cooldownDuration.inSeconds;
    });
    _startTimer();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Driver alerted successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const SizedBox.shrink();
    }

    final isCooldownActive = _secondsRemaining > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextButton(
        onPressed: isCooldownActive ? null : _onPressed,
        style: TextButton.styleFrom(
          backgroundColor: isCooldownActive
              ? Colors.grey.shade200
              : const Color(0xFFEF4444).withValues(alpha: 0.1),
          foregroundColor: isCooldownActive
              ? Colors.grey.shade500
              : const Color(0xFFEF4444),
          disabledForegroundColor: Colors.grey.shade500,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isCooldownActive
                  ? Colors.grey.shade300
                  : const Color(0xFFEF4444).withValues(alpha: 0.3),
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCooldownActive ? Icons.hourglass_empty_rounded : Icons.notifications_active_rounded,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              isCooldownActive
                  ? 'Alerted (${_formatDuration(_secondsRemaining)})'
                  : 'Alert Driver',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
