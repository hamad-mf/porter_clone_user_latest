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
  const MapPickerPage({
    super.key,
    required this.title,
    this.initialPosition,
  });

  final String title;
  final LatLng? initialPosition;

  static Future<PickedLocation?> pick(
    BuildContext context, {
    required String title,
    LatLng? initialPosition,
  }) {
    return Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => MapPickerPage(
          title: title,
          initialPosition: initialPosition,
        ),
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
  bool _isConfirming = false;
  String? _resolvedAddress;
  // Holds the in-flight reverse-geocode so _confirm() can await it.
  Future<void>? _pendingGeocode;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _checkLocationPermission();
    if (widget.initialPosition != null) {
      _reverseGeocode(widget.initialPosition!);
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

  String _labelFor(LatLng position) {
    final lat = position.latitude.toStringAsFixed(5);
    final lng = position.longitude.toStringAsFixed(5);
    return 'Lat $lat, Lng $lng';
  }

  void _reverseGeocode(LatLng position) {
    final future = () async {
      try {
        final address = await _placesApiService.reverseGeocode(position);
        if (!mounted) return;
        setState(() => _resolvedAddress = address);
      } catch (e) {
        // silently ignored
      }
    }();
    // Store so _confirm() can await it if the user taps before it finishes.
    _pendingGeocode = future;
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
      details = await _placesApiService.fetchPlaceDetails(
        suggestion.placeId,
      );
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
    _reverseGeocode(resolved.location);
    // Guard against the widget being disposed before the async gap resolves.
    if (!mounted) return;
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
          content: 'Location services are turned off. Please enable them to use your current location.',
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
          content: 'Location permission is permanently denied. Please enable it in app settings.',
          onSettings: () => Geolocator.openAppSettings(),
        );
      }
      return false;
    }

    final granted = permission == LocationPermission.always ||
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
    await _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(latLng, 15),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
        title: Text(title, style: const TextStyle(color: _appColor, fontWeight: FontWeight.w700)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm() async {
    // If reverse geocoding is still in flight, wait for it so we get the
    // proper address name instead of a raw lat/lng fallback.
    if (_pendingGeocode != null) {
      setState(() => _isConfirming = true);
      await _pendingGeocode;
      _pendingGeocode = null;
      if (!mounted) return;
      setState(() => _isConfirming = false);
    }

    final label = _searchController.text.trim().isNotEmpty
        ? _searchController.text.trim()
        : (_resolvedAddress?.isNotEmpty == true ? _resolvedAddress! : _labelFor(_selected));

    if (!mounted) return;
    Navigator.of(context).pop(
      PickedLocation(
        position: _selected,
        label: label,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selected,
              zoom: 12,
            ),
            onCameraIdle: () async {
              final center = await _controller?.getVisibleRegion();
              if (center == null || !mounted) return;
              final lat = (center.northeast.latitude + center.southwest.latitude) / 2;
              final lng = (center.northeast.longitude + center.southwest.longitude) / 2;
              final newPos = LatLng(lat, lng);
              _suppressSearch = true;
              _searchController.clear();
              _suppressSearch = false;
              setState(() {
                _selected = newPos;
                _resolvedAddress = null;
              });
              _reverseGeocode(newPos);
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
              child: Icon(Icons.place, color: Colors.redAccent, size: 40),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: Column(
              children: [
                Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(12),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search location',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : (_searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
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
                if (_suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
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
                      const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.place_outlined),
                          title: Text(
                            suggestion.description,
                            style: const TextStyle(fontSize: 13),
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
          Positioned(
            right: 16,
            bottom: 90,
            child: FloatingActionButton(
              heroTag: 'currentLocation',
              mini: true,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              onPressed: _goToCurrentLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 18,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Location name display
                if (_resolvedAddress != null && _resolvedAddress!.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFF111827),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _resolvedAddress!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF111827),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Use this location button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isConfirming ? null : _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D1117),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isConfirming
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Use this location',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}