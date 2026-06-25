import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:porter_clone_user/core/services/places_api_service.dart';

class PickedLocation {
  const PickedLocation({required this.position, required this.label});

  final LatLng position;
  final String label;
}

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key, required this.title, this.initialPosition});

  final String title;
  final LatLng? initialPosition;

  static Future<PickedLocation?> pick(
    BuildContext context, {
    required String title,
    LatLng? initialPosition,
  }) {
    return Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) =>
            MapPickerPage(title: title, initialPosition: initialPosition),
      ),
    );
  }

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  static const LatLng _fallbackPosition = LatLng(12.9716, 77.5946);

  late LatLng _selected = widget.initialPosition ?? _fallbackPosition;
  GoogleMapController? _controller;
  final TextEditingController _searchController = TextEditingController();
  final PlacesApiService _placesApiService = const PlacesApiService();
  final FocusNode _searchFocus = FocusNode();
  List<PlaceSuggestion> _suggestions = [];
  Timer? _debounce;
  bool _suppressSearch = false;
  bool _isSearching = false;
  bool _isFetchingDetails = false;
  bool _hasLocationPermission = false;
  String? _resolvedAddress;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _checkLocationPermission();

    // Initialize with proper location
    if (widget.initialPosition != null) {
      _reverseGeocode(widget.initialPosition!);
    } else {
      // If no initial position, get current location or use fallback
      _initializeLocation();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller?.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // String _labelFor(LatLng position) {
  //   final lat = position.latitude.toStringAsFixed(5);
  //   final lng = position.longitude.toStringAsFixed(5);
  //   return 'Lat $lat, Lng $lng';
  // }
  String _labelFor(LatLng position) {
    if (_resolvedAddress != null && _resolvedAddress!.trim().isNotEmpty) {
      return _resolvedAddress!;
    }
    return 'Loading location...';
  }

  Future<void> _reverseGeocode(LatLng position) async {
    try {
      final details = await _placesApiService.reverseGeocode(position);

      if (!mounted) return;

      String address = details ?? '';

      // Remove Plus Code
      final parts = address.split(',');

      if (parts.isNotEmpty &&
          RegExp(r'^[A-Z0-9]+\+[A-Z0-9]+$').hasMatch(parts.first.trim())) {
        parts.removeAt(0);
      }

      setState(() {
        _resolvedAddress = parts.join(',').trim();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _resolvedAddress = 'Unknown location');
    }
  }

  Future<void> _initializeLocation() async {
    debugPrint('🗺️ MAP_PICKER: Initializing location...');
    // Try to get current location, otherwise use fallback and reverse geocode it
    try {
      debugPrint('🗺️ MAP_PICKER: Checking location permissions...');
      final hasPermission = await _ensureLocationPermission();
      debugPrint('🗺️ MAP_PICKER: Location permission granted: $hasPermission');

      if (hasPermission) {
        debugPrint('🗺️ MAP_PICKER: Getting current position...');
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        final latLng = LatLng(position.latitude, position.longitude);
        debugPrint(
          '🗺️ MAP_PICKER: Current position: ${latLng.latitude}, ${latLng.longitude}',
        );

        if (mounted) {
          setState(() => _selected = latLng);
        }
        await _reverseGeocode(latLng);
        return;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ MAP_PICKER: Error getting current location: $e');
      debugPrint('❌ MAP_PICKER: Stack trace: $stackTrace');
    }

    // Fallback: reverse geocode the default position
    debugPrint(
      '🗺️ MAP_PICKER: Using fallback position: ${_fallbackPosition.latitude}, ${_fallbackPosition.longitude}',
    );
    await _reverseGeocode(_fallbackPosition);
  }

  void _onSearchChanged() {
    if (_suppressSearch) {
      return;
    }
    final input = _searchController.text.trim();
    _debounce?.cancel();
    if (input.isEmpty) {
      if (_suggestions.isNotEmpty) {
        setState(() => _suggestions = []);
      }
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _fetchSuggestions(input);
    });
  }

  Future<void> _fetchSuggestions(String input) async {
    setState(() => _isSearching = true);
    try {
      final results = await _placesApiService.fetchSuggestions(
        input,
        locationBias: _selected,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _suggestions = results;
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isSearching = false);
    }
  }

  Future<void> _selectSuggestion(PlaceSuggestion suggestion) async {
    FocusScope.of(context).unfocus();
    setState(() => _isFetchingDetails = true);
    PlaceDetails? details;
    try {
      details = await _placesApiService.fetchPlaceDetails(suggestion.placeId);
    } catch (_) {
      details = null;
    }
    if (!mounted) {
      return;
    }
    if (details == null) {
      setState(() => _isFetchingDetails = false);
      _showMessage('Unable to fetch place details.');
      return;
    }
    final PlaceDetails resolved = details;
    _suppressSearch = true;
    _searchController.text = resolved.label;
    _suppressSearch = false;
    setState(() {
      _selected = resolved.location;
      _suggestions = [];
      _isFetchingDetails = false;
    });
    await _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(resolved.location, 14),
    );
  }

  Future<void> _checkLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    if (!mounted) {
      return;
    }
    setState(
      () => _hasLocationPermission =
          permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse,
    );
  }

  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        _showLocationDialog(
          title: 'Location Disabled',
          content:
              'Location services are turned off. Please enable them to use your current location.',
          onSettings: () => Geolocator.openLocationSettings(),
        );
      }
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        _showLocationDialog(
          title: 'Permission Required',
          content:
              'Location permission is permanently denied. Please enable it in app settings.',
          onSettings: () => Geolocator.openAppSettings(),
        );
      }
      return false;
    }

    final granted =
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
    if (mounted) {
      setState(() => _hasLocationPermission = granted);
    }
    return granted;
  }

  Future<void> _goToCurrentLocation() async {
    final granted = await _ensureLocationPermission();
    if (!granted) {
      return;
    }
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    if (!mounted) {
      return;
    }
    final latLng = LatLng(position.latitude, position.longitude);
    _suppressSearch = true;
    _searchController.clear();
    _suppressSearch = false;
    setState(() {
      _selected = latLng;
      _suggestions = [];
      _resolvedAddress = null;
    });
    _reverseGeocode(latLng);
    await _controller?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  static const Color _appColor = Color(0xFF111827);

  void _showLocationDialog({
    required String title,
    required String content,
    required VoidCallback onSettings,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(color: _appColor, fontWeight: FontWeight.w700),
        ),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(foregroundColor: _appColor),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              onSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _appColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // Future<void> _confirm() async {
  //   setState(() => _isFetchingDetails = true);

  //   try {
  //     // ensure latest address is fetched
  //     final address = await _placesApiService.reverseGeocode(_selected);

  //     if (!mounted) return;

  //     final String label = (address != null && address.trim().isNotEmpty)
  //         ? address.trim()
  //         : (_resolvedAddress?.trim().isNotEmpty == true
  //             ? _resolvedAddress!.trim()
  //             : 'Selected location');

  //     Navigator.of(context).pop(
  //       PickedLocation(
  //         position: _selected,
  //         label: label,
  //       ),
  //     );
  //   } catch (e) {
  //     if (!mounted) return;

  //     Navigator.of(context).pop(
  //       PickedLocation(
  //         position: _selected,
  //         label: _resolvedAddress?.trim().isNotEmpty == true
  //             ? _resolvedAddress!.trim()
  //             : 'Selected location',
  //       ),
  //     );
  //   } finally {
  //     if (mounted) {
  //       setState(() => _isFetchingDetails = false);
  //     }
  //   }
  // }

  void _confirm() {
    final label = _searchController.text.trim().isNotEmpty
        ? _searchController.text.trim()
        : (_resolvedAddress?.isNotEmpty == true
              ? _resolvedAddress!
              : _labelFor(_selected));
    Navigator.of(
      context,
    ).pop(PickedLocation(position: _selected, label: label));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _selected, zoom: 12),
            onCameraIdle: () async {
              final center = await _controller?.getVisibleRegion();
              if (center == null || !mounted) return;
              final lat =
                  (center.northeast.latitude + center.southwest.latitude) / 2;
              final lng =
                  (center.northeast.longitude + center.southwest.longitude) / 2;
              final newPos = LatLng(lat, lng);
              _suppressSearch = true;
              _searchController.clear();
              _suppressSearch = false;
              setState(() {
                _selected = newPos;
                _resolvedAddress = null;
              });

              await _reverseGeocode(newPos);
            },
            onMapCreated: (controller) => _controller = controller,
            myLocationEnabled: _hasLocationPermission,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // Fixed center pin
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 36),
              child: Icon(Icons.place, color: Color(0xFFDE4B65), size: 48),
            ),
          ),

          // Top Bar with Back button and Title
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                color: Colors.white,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.black,
                        size: 24,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Search Bar
          Positioned(
            left: 16,
            right: 16,
            top: 72,
            child: SafeArea(
              child: Column(
                children: [
                  Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        textInputAction: TextInputAction.search,
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Search location',
                          hintStyle: const TextStyle(
                            color: Color(0xFFAAAAAA),
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF666666),
                            size: 24,
                          ),
                          suffixIcon: _isSearching
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : (_searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 22),
                                        onPressed: () {
                                          _suppressSearch = true;
                                          _searchController.clear();
                                          _suppressSearch = false;
                                          setState(() => _suggestions = []);
                                        },
                                      )
                                    : null),
                        ),
                      ),
                    ),
                  ),
                  if (_suggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      constraints: const BoxConstraints(maxHeight: 280),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const ClampingScrollPhysics(),
                        itemCount: _suggestions.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, thickness: 0.5),
                        itemBuilder: (context, index) {
                          final suggestion = _suggestions[index];
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            leading: const Icon(
                              Icons.place_outlined,
                              color: Color(0xFF666666),
                              size: 22,
                            ),
                            title: Text(
                              suggestion.description,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF222222),
                              ),
                            ),
                            onTap: _isFetchingDetails
                                ? null
                                : () => _selectSuggestion(suggestion),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Current Location Button
          Positioned(
            right: 16,
            bottom: 200,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.my_location,
                  color: Color(0xFF111827),
                  size: 24,
                ),
                onPressed: _goToCurrentLocation,
              ),
            ),
          ),

          // Bottom Address Card and Button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Address Display
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.place,
                                color: Color(0xFF111827),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _resolvedAddress == null
                                  ? const Row(
                                      children: [
                                        SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          'Loading location...',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w400,
                                            color: Color(0xFF666666),
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      _resolvedAddress!,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF222222),
                                        height: 1.4,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),

                      // Use this location button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isFetchingDetails ? null : _confirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D1117),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            disabledBackgroundColor: const Color(0xFF666666),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isFetchingDetails
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Use this location',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
