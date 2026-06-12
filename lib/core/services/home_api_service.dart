import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class HomeApiException implements Exception {
  HomeApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class HomeBanner {
  const HomeBanner({required this.imageUrl});

  final String imageUrl;
}

class HomeApiService {
  const HomeApiService({http.Client? client}) : _client = client;

  final http.Client? _client;

  http.Client get client => _client ?? http.Client();

  static const String _baseUrl = 'https://lorry.workwista.com';
  static final Uri _bannerUri = Uri.parse('$_baseUrl/api/users/banner/');
  static const Duration _timeout = Duration(seconds: 20);

  Future<List<HomeBanner>> getBanners() async {
    try {
      final response = await client
          .get(
            _bannerUri,
            headers: const <String, String>{
              'Accept': 'application/json',
            },
          )
          .timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HomeApiException(
          'Failed to load banner. (${response.statusCode})',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw HomeApiException('Invalid banner response from server.');
      }

      return decoded
          .map<HomeBanner?>((entry) {
            if (entry is! Map) {
              return null;
            }

            final imagePath = entry['banner_image']?.toString().trim() ?? '';
            if (imagePath.isEmpty) {
              return null;
            }

            return HomeBanner(imageUrl: _absoluteUrl(imagePath));
          })
          .whereType<HomeBanner>()
          .toList();
    } on TimeoutException {
      throw HomeApiException(
        'Request timeout. Please check your internet connection.',
      );
    } on FormatException {
      throw HomeApiException('Invalid banner response from server.');
    } on http.ClientException catch (e) {
      throw HomeApiException('Network error: ${e.message}');
    }
  }

  static String _absoluteUrl(String source) {
    final uri = Uri.tryParse(source);
    if (uri != null && uri.hasScheme) {
      return source;
    }

    return Uri.parse(_baseUrl).resolve(source).toString();
  }
}
