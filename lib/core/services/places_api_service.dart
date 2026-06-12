import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:porter_clone_user/core/config/google_maps_config.dart';

class PlaceSuggestion {
  const PlaceSuggestion({required this.placeId, required this.description});

  final String placeId;
  final String description;
}

class PlaceDetails {
  const PlaceDetails({required this.location, required this.label});

  final LatLng location;
  final String label;
}

class PlacesApiService {
  const PlacesApiService();

  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/place';

  Future<List<PlaceSuggestion>> fetchSuggestions(
    String input, {
    LatLng? locationBias,
  }) async {
    debugPrint('📍 PLACES_API: Fetching suggestions for input: "$input"');
    
    final trimmedInput = input.trim();
    if (trimmedInput.isEmpty) {
      debugPrint('📍 PLACES_API: Input is empty, returning empty list');
      return const [];
    }

    final query = <String, String>{
      'input': trimmedInput,
      'key': kGoogleMapsApiKey,
      'language': 'en',
    };
    if (locationBias != null) {
      query['location'] = '${locationBias.latitude},${locationBias.longitude}';
      query['radius'] = '50000';
      debugPrint('📍 PLACES_API: Using location bias: ${locationBias.latitude}, ${locationBias.longitude}');
    }

    final uri = Uri.parse('$_baseUrl/autocomplete/json')
        .replace(queryParameters: query);
    
    debugPrint('📍 PLACES_API: Request URL: $uri');
    
    try {
      final response = await http.get(uri);
      debugPrint('📍 PLACES_API: Response status: ${response.statusCode}');
      debugPrint('📍 PLACES_API: Response body: ${response.body}');
      
      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('❌ PLACES_API: Request failed with status ${response.statusCode}');
        return const [];
      }

      final payload = jsonDecode(response.body);
      final status = payload['status']?.toString();
      debugPrint('📍 PLACES_API: API status: $status');
      
      if (status != 'OK') {
        debugPrint('❌ PLACES_API: API returned non-OK status: $status');
        if (payload['error_message'] != null) {
          debugPrint('❌ PLACES_API: Error message: ${payload['error_message']}');
        }
        return const [];
      }

      final predictions = payload['predictions'];
      if (predictions is! List) {
        debugPrint('❌ PLACES_API: Predictions is not a list');
        return const [];
      }

      debugPrint('📍 PLACES_API: Found ${predictions.length} suggestions');
      
      return predictions
          .map<PlaceSuggestion?>((item) {
            if (item is! Map<String, dynamic>) {
              return null;
            }
            final placeId = item['place_id']?.toString() ?? '';
            final description = item['description']?.toString() ?? '';
            if (placeId.isEmpty || description.isEmpty) {
              return null;
            }
            return PlaceSuggestion(
              placeId: placeId,
              description: description,
            );
          })
          .whereType<PlaceSuggestion>()
          .toList();
    } catch (e, stackTrace) {
      debugPrint('❌ PLACES_API: Exception in fetchSuggestions: $e');
      debugPrint('❌ PLACES_API: Stack trace: $stackTrace');
      return const [];
    }
  }

  Future<PlaceDetails?> fetchPlaceDetails(String placeId) async {
    debugPrint('📍 PLACES_API: Fetching place details for placeId: $placeId');
    
    final trimmed = placeId.trim();
    if (trimmed.isEmpty) {
      debugPrint('❌ PLACES_API: PlaceId is empty');
      return null;
    }

    final query = <String, String>{
      'place_id': trimmed,
      'fields': 'geometry,name,formatted_address',
      'key': kGoogleMapsApiKey,
      'language': 'en',
    };
    final uri = Uri.parse('$_baseUrl/details/json')
        .replace(queryParameters: query);
    
    debugPrint('📍 PLACES_API: Request URL: $uri');
    
    try {
      final response = await http.get(uri);
      debugPrint('📍 PLACES_API: Response status: ${response.statusCode}');
      debugPrint('📍 PLACES_API: Response body: ${response.body}');
      
      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('❌ PLACES_API: Request failed with status ${response.statusCode}');
        return null;
      }

      final payload = jsonDecode(response.body);
      final status = payload['status']?.toString();
      debugPrint('📍 PLACES_API: API status: $status');
      
      if (status != 'OK') {
        debugPrint('❌ PLACES_API: API returned non-OK status: $status');
        if (payload['error_message'] != null) {
          debugPrint('❌ PLACES_API: Error message: ${payload['error_message']}');
        }
        return null;
      }

      final result = payload['result'];
      if (result is! Map<String, dynamic>) {
        debugPrint('❌ PLACES_API: Result is not a map');
        return null;
      }
      
      final geometry = result['geometry'];
      final location = geometry is Map<String, dynamic>
          ? geometry['location']
          : null;
      final lat = location is Map<String, dynamic>
          ? location['lat']?.toDouble()
          : null;
      final lng = location is Map<String, dynamic>
          ? location['lng']?.toDouble()
          : null;
      
      if (lat == null || lng == null) {
        debugPrint('❌ PLACES_API: Could not extract lat/lng from result');
        return null;
      }

      final formatted = result['formatted_address']?.toString();
      final name = result['name']?.toString();
      final label = (formatted != null && formatted.trim().isNotEmpty)
          ? formatted.trim()
          : (name ?? '').trim();

      debugPrint('📍 PLACES_API: Place details - lat: $lat, lng: $lng, label: $label');

      return PlaceDetails(
        location: LatLng(lat, lng),
        label: label.isEmpty ? 'Lat $lat, Lng $lng' : label,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ PLACES_API: Exception in fetchPlaceDetails: $e');
      debugPrint('❌ PLACES_API: Stack trace: $stackTrace');
      return null;
    }
  }

  Future<String?> reverseGeocode(LatLng position) async {
    debugPrint('🌍 GEOCODING_API: Starting reverse geocoding for: ${position.latitude}, ${position.longitude}');
    
    final query = <String, String>{
      'latlng': '${position.latitude},${position.longitude}',
      'key': kGoogleGeocodingApiKey,
      'language': 'en',
    };
    final uri = Uri.parse('https://maps.googleapis.com/maps/api/geocode/json')
        .replace(queryParameters: query);
    
    debugPrint('🌍 GEOCODING_API: Request URL: $uri');
    
    try {
      final response = await http.get(uri);
      debugPrint('🌍 GEOCODING_API: Response status: ${response.statusCode}');
      debugPrint('🌍 GEOCODING_API: Response body: ${response.body}');
      
      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('❌ GEOCODING_API: Request failed with status ${response.statusCode}');
        return null;
      }
      
      final payload = jsonDecode(response.body);
      final status = payload['status']?.toString();
      debugPrint('🌍 GEOCODING_API: API status: $status');
      
      if (status != 'OK') {
        debugPrint('❌ GEOCODING_API: API returned non-OK status: $status');
        if (payload['error_message'] != null) {
          debugPrint('❌ GEOCODING_API: Error message: ${payload['error_message']}');
        }
        return null;
      }
      
      final results = payload['results'];
      if (results is! List || results.isEmpty) {
        debugPrint('❌ GEOCODING_API: No results found');
        return null;
      }
      
      debugPrint('🌍 GEOCODING_API: Found ${results.length} results');
      
      final address = results.first['formatted_address']?.toString();
      debugPrint('🌍 GEOCODING_API: Formatted address: $address');
      
      return (address != null && address.trim().isNotEmpty) ? address.trim() : null;
    } catch (e, stackTrace) {
      debugPrint('❌ GEOCODING_API: Exception in reverseGeocode: $e');
      debugPrint('❌ GEOCODING_API: Stack trace: $stackTrace');
      return null;
    }
  }
}
