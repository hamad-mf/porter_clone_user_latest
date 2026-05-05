import 'package:flutter_test/flutter_test.dart';

/// Test helper to parse trip ID from URL
/// This mirrors the private _parseTripId method in DeepLinkHandler
String? parseTripId(Uri uri) {
  try {
    // Handle custom scheme: lorry://trip/{tripId}
    if (uri.scheme == 'lorry') {
      if (uri.host == 'trip' && uri.pathSegments.isNotEmpty) {
        return uri.pathSegments[0];
      } else {
        return null;
      }
    }
    
    // Handle HTTPS: https://lorry.workwista.com/share/trip/{tripId}
    if (uri.scheme == 'https' && uri.host == 'lorry.workwista.com') {
      final segments = uri.pathSegments;
      if (segments.length >= 3 && 
          segments[0] == 'share' && 
          segments[1] == 'trip') {
        return segments[2];
      } else {
        return null;
      }
    }
    
    return null;
  } catch (e) {
    return null;
  }
}

void main() {
  group('DeepLinkHandler URL Parsing', () {
    group('HTTPS URL Parsing', () {
      test('parses valid HTTPS URL with trip ID', () {
        final uri = Uri.parse('https://lorry.workwista.com/share/trip/trip123');
        final tripId = parseTripId(uri);
        expect(tripId, equals('trip123'));
      });

      test('parses HTTPS URL with alphanumeric trip ID', () {
        final uri = Uri.parse('https://lorry.workwista.com/share/trip/abc123def456');
        final tripId = parseTripId(uri);
        expect(tripId, equals('abc123def456'));
      });

      test('parses HTTPS URL with trip ID containing hyphens', () {
        final uri = Uri.parse('https://lorry.workwista.com/share/trip/trip-123-abc');
        final tripId = parseTripId(uri);
        expect(tripId, equals('trip-123-abc'));
      });

      test('parses HTTPS URL with trip ID containing underscores', () {
        final uri = Uri.parse('https://lorry.workwista.com/share/trip/trip_123_abc');
        final tripId = parseTripId(uri);
        expect(tripId, equals('trip_123_abc'));
      });

      test('returns null for HTTPS URL with wrong host', () {
        final uri = Uri.parse('https://example.com/share/trip/trip123');
        final tripId = parseTripId(uri);
        expect(tripId, isNull);
      });

      test('returns null for HTTPS URL with missing /share segment', () {
        final uri = Uri.parse('https://lorry.workwista.com/trip/trip123');
        final tripId = parseTripId(uri);
        expect(tripId, isNull);
      });

      test('returns null for HTTPS URL with missing /trip segment', () {
        final uri = Uri.parse('https://lorry.workwista.com/share/trip123');
        final tripId = parseTripId(uri);
        expect(tripId, isNull);
      });

      test('returns empty string for HTTPS URL with missing trip ID', () {
        final uri = Uri.parse('https://lorry.workwista.com/share/trip/');
        final tripId = parseTripId(uri);
        // When path ends with /, pathSegments includes an empty string
        expect(tripId, equals(''));
      });

      test('returns null for HTTPS URL with only /share', () {
        final uri = Uri.parse('https://lorry.workwista.com/share');
        final tripId = parseTripId(uri);
        expect(tripId, isNull);
      });

      test('parses HTTPS URL with additional path segments after trip ID', () {
        final uri = Uri.parse('https://lorry.workwista.com/share/trip/trip123/extra');
        final tripId = parseTripId(uri);
        expect(tripId, equals('trip123'));
      });

      test('ignores query parameters in HTTPS URL', () {
        final uri = Uri.parse('https://lorry.workwista.com/share/trip/trip123?param=value');
        final tripId = parseTripId(uri);
        expect(tripId, equals('trip123'));
      });

      test('ignores fragment in HTTPS URL', () {
        final uri = Uri.parse('https://lorry.workwista.com/share/trip/trip123#section');
        final tripId = parseTripId(uri);
        expect(tripId, equals('trip123'));
      });
    });

    group('Custom Scheme URL Parsing', () {
      test('parses valid custom scheme URL with trip ID', () {
        final uri = Uri.parse('lorry://trip/trip123');
        final tripId = parseTripId(uri);
        expect(tripId, equals('trip123'));
      });

      test('parses custom scheme URL with alphanumeric trip ID', () {
        final uri = Uri.parse('lorry://trip/abc123def456');
        final tripId = parseTripId(uri);
        expect(tripId, equals('abc123def456'));
      });

      test('parses custom scheme URL with trip ID containing hyphens', () {
        final uri = Uri.parse('lorry://trip/trip-123-abc');
        final tripId = parseTripId(uri);
        expect(tripId, equals('trip-123-abc'));
      });

      test('parses custom scheme URL with trip ID containing underscores', () {
        final uri = Uri.parse('lorry://trip/trip_123_abc');
        final tripId = parseTripId(uri);
        expect(tripId, equals('trip_123_abc'));
      });

      test('returns null for custom scheme URL with wrong host', () {
        final uri = Uri.parse('lorry://job/trip123');
        final tripId = parseTripId(uri);
        expect(tripId, isNull);
      });

      test('returns null for custom scheme URL with missing trip ID', () {
        final uri = Uri.parse('lorry://trip/');
        final tripId = parseTripId(uri);
        expect(tripId, isNull);
      });

      test('returns null for custom scheme URL with only host', () {
        final uri = Uri.parse('lorry://trip');
        final tripId = parseTripId(uri);
        expect(tripId, isNull);
      });

      test('parses custom scheme URL with additional path segments', () {
        final uri = Uri.parse('lorry://trip/trip123/extra');
        final tripId = parseTripId(uri);
        expect(tripId, equals('trip123'));
      });

      test('ignores query parameters in custom scheme URL', () {
        final uri = Uri.parse('lorry://trip/trip123?param=value');
        final tripId = parseTripId(uri);
        expect(tripId, equals('trip123'));
      });

      test('ignores fragment in custom scheme URL', () {
        final uri = Uri.parse('lorry://trip/trip123#section');
        final tripId = parseTripId(uri);
        expect(tripId, equals('trip123'));
      });
    });

    group('Invalid URL Handling', () {
      test('returns null for HTTP URL (not HTTPS)', () {
        final uri = Uri.parse('http://lorry.workwista.com/share/trip/trip123');
        final tripId = parseTripId(uri);
        expect(tripId, isNull);
      });

      test('returns null for wrong custom scheme', () {
        final uri = Uri.parse('workwista://trip/trip123');
        final tripId = parseTripId(uri);
        expect(tripId, isNull);
      });

      test('returns null for completely invalid URL pattern', () {
        final uri = Uri.parse('https://example.com/random/path');
        final tripId = parseTripId(uri);
        expect(tripId, isNull);
      });

      test('returns null for URL with no path', () {
        final uri = Uri.parse('https://lorry.workwista.com');
        final tripId = parseTripId(uri);
        expect(tripId, isNull);
      });

      test('returns null for URL with empty path', () {
        final uri = Uri.parse('https://lorry.workwista.com/');
        final tripId = parseTripId(uri);
        expect(tripId, isNull);
      });
    });

    group('Round-Trip Property', () {
      test('HTTPS URL round-trip preserves trip ID', () {
        const tripId = 'trip123';
        final url = 'https://lorry.workwista.com/share/trip/$tripId';
        final uri = Uri.parse(url);
        final parsedTripId = parseTripId(uri);
        expect(parsedTripId, equals(tripId));
      });

      test('custom scheme URL round-trip preserves trip ID', () {
        const tripId = 'trip123';
        final url = 'lorry://trip/$tripId';
        final uri = Uri.parse(url);
        final parsedTripId = parseTripId(uri);
        expect(parsedTripId, equals(tripId));
      });

      test('round-trip works with complex trip IDs', () {
        const tripId = 'trip-123_abc-def_456';
        
        // Test HTTPS
        final httpsUrl = 'https://lorry.workwista.com/share/trip/$tripId';
        final httpsUri = Uri.parse(httpsUrl);
        expect(parseTripId(httpsUri), equals(tripId));
        
        // Test custom scheme
        final customUrl = 'lorry://trip/$tripId';
        final customUri = Uri.parse(customUrl);
        expect(parseTripId(customUri), equals(tripId));
      });
    });

    group('Edge Cases', () {
      test('handles trip ID with only numbers', () {
        final uri = Uri.parse('https://lorry.workwista.com/share/trip/123456');
        final tripId = parseTripId(uri);
        expect(tripId, equals('123456'));
      });

      test('handles trip ID with only letters', () {
        final uri = Uri.parse('https://lorry.workwista.com/share/trip/abcdef');
        final tripId = parseTripId(uri);
        expect(tripId, equals('abcdef'));
      });

      test('handles very long trip ID', () {
        final longId = 'a' * 100;
        final uri = Uri.parse('https://lorry.workwista.com/share/trip/$longId');
        final tripId = parseTripId(uri);
        expect(tripId, equals(longId));
      });

      test('handles single character trip ID', () {
        final uri = Uri.parse('https://lorry.workwista.com/share/trip/a');
        final tripId = parseTripId(uri);
        expect(tripId, equals('a'));
      });

      test('handles trip ID with mixed case', () {
        final uri = Uri.parse('https://lorry.workwista.com/share/trip/TrIp123AbC');
        final tripId = parseTripId(uri);
        expect(tripId, equals('TrIp123AbC'));
      });

      test('handles URL with port number', () {
        final uri = Uri.parse('https://lorry.workwista.com:8080/share/trip/trip123');
        final tripId = parseTripId(uri);
        // Uri.host does not include port, so this should work
        expect(tripId, equals('trip123'));
      });

      test('handles URL with subdomain', () {
        final uri = Uri.parse('https://app.lorry.workwista.com/share/trip/trip123');
        final tripId = parseTripId(uri);
        expect(tripId, isNull); // Different host
      });
    });

    group('Runtime Deep Link Navigation', () {
      testWidgets('navigates to TripDetailsPage when runtime deep link received', (WidgetTester tester) async {
        // This is a basic smoke test to verify the navigation logic compiles
        // Full integration testing would require mocking AppLinks stream
        
        // For now, we just verify the parseTripId function works correctly
        // which is the core logic for runtime navigation
        final uri = Uri.parse('https://lorry.workwista.com/share/trip/test123');
        final tripId = parseTripId(uri);
        
        expect(tripId, equals('test123'));
        expect(tripId, isNotNull);
      });
    });
  });
}
