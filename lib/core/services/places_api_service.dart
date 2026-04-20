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
    };
    if (locationBias != null) {
      query['location'] = '${locationBias.latitude},${locationBias.longitude}';
      query['radius'] = '50000';
    }

    final uri = Uri.parse('$_baseUrl/autocomplete/json')
        .replace(queryParameters: query);
          print("🌍 URL: $uri"); // 👈 PRINT URL
    final response = await http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
          print("❌ HTTP ERROR: ${response.statusCode}");

      return const [];
    }

    final payload = jsonDecode(response.body);
    final status = payload['status']?.toString();
    if (status != 'OK') {
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
    final response = await http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final payload = jsonDecode(response.body);
    final status = payload['status']?.toString();
    if (status != 'OK') {
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
      'key': kGoogleMapsApiKey,
      'language': 'en',
    };
    final uri = Uri.parse('https://maps.googleapis.com/maps/api/geocode/json')
        .replace(queryParameters: query);
    final response = await http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }
    final payload = jsonDecode(response.body);
    final status = payload['status']?.toString();
    if (status != 'OK') {
      return null;
    }
    final results = payload['results'];
    if (results is! List || results.isEmpty) {
      return null;
    }
    final address = results.first['formatted_address']?.toString();
    return (address != null && address.trim().isNotEmpty) ? address.trim() : null;
  }
}
