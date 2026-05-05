import 'dart:convert';

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
    final trimmedInput = input.trim();
    if (trimmedInput.isEmpty) {
      return const [];
    }

    final query = <String, String>{
      'input': trimmedInput,
      'key': kGoogleMapsApiKey,
      'language': 'en',
      'components': 'country:in', // Restrict to India like workwista
    };
    if (locationBias != null) {
      query['location'] = '${locationBias.latitude},${locationBias.longitude}';
      query['radius'] = '50000';
    }

    final uri = Uri.parse('$_baseUrl/autocomplete/json')
        .replace(queryParameters: query);
    print("🌍 Autocomplete URL: $uri");
    
    final response = await http.get(uri);
    print("📥 Autocomplete status: ${response.statusCode}");
    
    if (response.statusCode < 200 || response.statusCode >= 300) {
      print("❌ HTTP ERROR: ${response.statusCode}");
      return const [];
    }

    final payload = jsonDecode(response.body);
    final status = payload['status']?.toString();
    print("📊 API Response Status: $status");
    
    if (status != 'OK') {
      print("❌ Places API Error: $status");
      print("📝 Error message: ${payload['error_message']}");
      print("📄 Full response: ${jsonEncode(payload)}");
      
      // Show user-friendly error
      if (status == 'REQUEST_DENIED') {
        print("🚫 API KEY ISSUE: The API key is invalid, restricted, or billing is not enabled");
      } else if (status == 'OVER_QUERY_LIMIT') {
        print("⚠️ QUOTA EXCEEDED: You've hit the API usage limit");
      } else if (status == 'ZERO_RESULTS') {
        print("ℹ️ No results found for this search");
      }
      
      return const [];
    }

    final predictions = payload['predictions'];
    if (predictions is! List) {
      return const [];
    }

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
  }

  Future<PlaceDetails?> fetchPlaceDetails(String placeId) async {
    final trimmed = placeId.trim();
    if (trimmed.isEmpty) {
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
    print("🔍 Place Details URL: $uri");
    
    final response = await http.get(uri);
    print("📥 Place Details status: ${response.statusCode}");
    
    if (response.statusCode < 200 || response.statusCode >= 300) {
      print("❌ Place Details HTTP ERROR: ${response.statusCode}");
      return null;
    }

    final payload = jsonDecode(response.body);
    final status = payload['status']?.toString();
    if (status != 'OK') {
      print("❌ Place Details API Error: $status");
      print("📝 Error message: ${payload['error_message']}");
      return null;
    }

    final result = payload['result'];
    if (result is! Map<String, dynamic>) {
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
      return null;
    }

    final formatted = result['formatted_address']?.toString();
    final name = result['name']?.toString();
    final label = (formatted != null && formatted.trim().isNotEmpty)
        ? formatted.trim()
        : (name ?? '').trim();

    return PlaceDetails(
      location: LatLng(lat, lng),
      label: label.isEmpty ? 'Lat $lat, Lng $lng' : label,
    );
  }

  Future<String?> reverseGeocode(LatLng position) async {
    final query = <String, String>{
      'latlng': '${position.latitude},${position.longitude}',
      'key': kGoogleGeocodingApiKey, // uses the Geocoding-API-enabled key
      'language': 'en',
    };
    final uri = Uri.parse('https://maps.googleapis.com/maps/api/geocode/json')
        .replace(queryParameters: query);
    print("📍 Reverse Geocode URL: $uri");
    
    final response = await http.get(uri);
    print("📥 Reverse Geocode status: ${response.statusCode}");
    
    if (response.statusCode < 200 || response.statusCode >= 300) {
      print("❌ Reverse Geocode HTTP ERROR: ${response.statusCode}");
      return null;
    }
    final payload = jsonDecode(response.body);
    final status = payload['status']?.toString();
    if (status != 'OK') {
      print("❌ Geocoding API Error: $status");
      print("📝 Error message: ${payload['error_message']}");
      return null;
    }
    final results = payload['results'];
    if (results is! List || results.isEmpty) {
      print("⚠️ Geocoding returned no results");
      return null;
    }
    
    // Try to find a result with a proper place name (not just a Plus Code)
    String? bestAddress;
    for (final result in results) {
      if (result is! Map<String, dynamic>) continue;
      
      final address = result['formatted_address']?.toString();
      if (address == null || address.trim().isEmpty) continue;
      
      // Skip Plus Codes (they contain + symbol)
      if (address.contains('+')) continue;
      
      // Prefer results with types like 'premise', 'establishment', 'point_of_interest'
      final types = result['types'];
      if (types is List) {
        if (types.contains('premise') || 
            types.contains('establishment') || 
            types.contains('point_of_interest') ||
            types.contains('street_address')) {
          bestAddress = address.trim();
          print("✅ Found specific place: $bestAddress");
          break;
        }
      }
      
      // Otherwise, use the first non-Plus Code address
      if (bestAddress == null) {
        bestAddress = address.trim();
      }
    }
    
    // Fallback to first result if no better option found
    if (bestAddress == null) {
      final address = results.first['formatted_address']?.toString();
      bestAddress = (address != null && address.trim().isNotEmpty) ? address.trim() : null;
    }
    
    print("✅ Reverse Geocode Success: $bestAddress");
    return bestAddress;
  }
}