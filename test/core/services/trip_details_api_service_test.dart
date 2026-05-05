import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:porter_clone_user/core/services/trip_details_api_service.dart';

String buildTripDetailsResponse({
  String tripId = 'trip123',
  String pickupLocation = 'Location A',
  String dropLocation = 'Location B',
  String loadSize = '5 Ton',
  String loadType = 'General',
  String? vehicleSize = '15 Ton',
  String bodyType = 'Open',
  String tripStatus = 'pending',
  String amount = '1000',
  String pickupTime = '2024-01-15T10:00:00Z',
  String name = 'John Doe',
  String contactNumber = '1234567890',
}) {
  return jsonEncode({
    'message': 'Trip details retrieved successfully',
    'data': {
      'id': tripId,
      'accepted_drivers': <dynamic>[],
      'pickup_location': pickupLocation,
      'drop_location': dropLocation,
      'load_size': loadSize,
      'load_type': loadType,
      'stops': null,
      'start_time': '16:47',
      'pickup_date': '17:47',
      'vehicle_size': vehicleSize,
      'body_type': bodyType,
      'trip_status': tripStatus,
      'has_driver_acceptances': true,
      'acceptance_status': 'pending',
      'amount': amount,
      'pickup_loc_lat': 11.05,
      'pickup_loc_lng': 76.07,
      'drop_loc_lat': 9.9312,
      'drop_loc_lng': 76.2673,
      'pickup_time': pickupTime,
      'name': name,
      'contact_number': contactNumber,
      'secondary_contact_number': '7736761067',
      'user': '88a3d4e6-bf27-4587-8ef5-271d1332cd74',
      'driver': null,
    },
  });
}

void main() {
  group('TripDetailsApiService', () {
    test('TripNotFoundException has correct message', () {
      final exception = TripNotFoundException('Trip not found');
      expect(exception.message, equals('Trip not found'));
      expect(exception.toString(), equals('Trip not found'));
    });

    test('TripDetailsApiException has correct message', () {
      final exception = TripDetailsApiException('Test error');
      expect(exception.message, equals('Test error'));
      expect(exception.toString(), equals('Test error'));
    });

    group('Successful Response Parsing', () {
      test('returns Trip model on 200 response', () async {
        final mockClient = MockClient((request) async {
          return http.Response(buildTripDetailsResponse(), 200);
        });

        final service = TripDetailsApiService(client: mockClient);
        final result = await service.getTripById(tripId: 'trip123');

        expect(result.id, equals('trip123'));
        expect(result.pickupLocation, equals('Location A'));
        expect(result.dropLocation, equals('Location B'));
        expect(result.loadSize, equals('5 Ton'));
        expect(result.vehicleSize, equals('15 Ton'));
        expect(result.amount, equals('1000'));
      });

      test('maps nullable vehicle size to empty string', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            buildTripDetailsResponse(vehicleSize: null),
            200,
          );
        });

        final service = TripDetailsApiService(client: mockClient);
        final result = await service.getTripById(tripId: 'trip123');

        expect(result.vehicleSize, isEmpty);
      });

      test('includes Authorization header when accessToken provided', () async {
        String? authHeader;
        final mockClient = MockClient((request) async {
          authHeader = request.headers['Authorization'];
          return http.Response(buildTripDetailsResponse(), 200);
        });

        final service = TripDetailsApiService(client: mockClient);
        await service.getTripById(tripId: 'trip123', accessToken: 'test-token');

        expect(authHeader, equals('Bearer test-token'));
      });

      test('does not include Authorization header when accessToken is null', () async {
        String? authHeader;
        final mockClient = MockClient((request) async {
          authHeader = request.headers['Authorization'];
          return http.Response(buildTripDetailsResponse(), 200);
        });

        final service = TripDetailsApiService(client: mockClient);
        await service.getTripById(tripId: 'trip123');

        expect(authHeader, isNull);
      });

      test('makes GET request to correct endpoint', () async {
        Uri? requestUri;
        final mockClient = MockClient((request) async {
          requestUri = request.url;
          return http.Response(buildTripDetailsResponse(), 200);
        });

        final service = TripDetailsApiService(client: mockClient);
        await service.getTripById(tripId: 'trip123');

        expect(
          requestUri.toString(),
          equals('https://lorry.workwista.com/api/users/trip/trip123/'),
        );
      });
    });

    group('Error Handling', () {
      test('throws TripNotFoundException on 404 status code', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Not Found', 404);
        });

        final service = TripDetailsApiService(client: mockClient);

        expect(
          () async => service.getTripById(tripId: 'nonexistent'),
          throwsA(
            isA<TripNotFoundException>().having(
              (e) => e.message,
              'message',
              equals('Trip not found.'),
            ),
          ),
        );
      });

      test('throws TripDetailsApiException on 500 status code', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Internal Server Error', 500);
        });

        final service = TripDetailsApiService(client: mockClient);

        expect(
          () async => service.getTripById(tripId: 'trip123'),
          throwsA(
            isA<TripDetailsApiException>().having(
              (e) => e.message,
              'message',
              contains('Server error'),
            ),
          ),
        );
      });

      test('throws TripDetailsApiException on other error status codes', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Bad Request', 400);
        });

        final service = TripDetailsApiService(client: mockClient);

        expect(
          () async => service.getTripById(tripId: 'trip123'),
          throwsA(
            isA<TripDetailsApiException>().having(
              (e) => e.message,
              'message',
              contains('Failed to fetch trip details. (400)'),
            ),
          ),
        );
      });

      test('throws timeout error when request times out', () async {
        final mockClient = MockClient((request) async {
          await Future.delayed(const Duration(seconds: 25));
          return http.Response('', 200);
        });

        final service = TripDetailsApiService(client: mockClient);

        expect(
          () async => service.getTripById(tripId: 'trip123'),
          throwsA(
            isA<TripDetailsApiException>().having(
              (e) => e.message,
              'message',
              contains('Request timed out'),
            ),
          ),
        );
      });

      test('throws network error on ClientException', () async {
        final mockClient = MockClient((request) async {
          throw http.ClientException('Network error');
        });

        final service = TripDetailsApiService(client: mockClient);

        expect(
          () async => service.getTripById(tripId: 'trip123'),
          throwsA(
            isA<TripDetailsApiException>().having(
              (e) => e.message,
              'message',
              contains('Network error'),
            ),
          ),
        );
      });

      test('throws parsing error on invalid JSON', () async {
        final mockClient = MockClient((request) async {
          return http.Response('invalid json', 200);
        });

        final service = TripDetailsApiService(client: mockClient);

        expect(
          () async => service.getTripById(tripId: 'trip123'),
          throwsA(
            isA<TripDetailsApiException>().having(
              (e) => e.message,
              'message',
              contains('Failed to parse response'),
            ),
          ),
        );
      });

      test('throws error when response is empty', () async {
        final mockClient = MockClient((request) async {
          return http.Response('', 200);
        });

        final service = TripDetailsApiService(client: mockClient);

        expect(
          () async => service.getTripById(tripId: 'trip123'),
          throwsA(
            isA<TripDetailsApiException>().having(
              (e) => e.message,
              'message',
              contains('Empty response from server'),
            ),
          ),
        );
      });

      test('throws error when response is not a JSON object', () async {
        final mockClient = MockClient((request) async {
          return http.Response('[]', 200);
        });

        final service = TripDetailsApiService(client: mockClient);

        expect(
          () async => service.getTripById(tripId: 'trip123'),
          throwsA(
            isA<TripDetailsApiException>().having(
              (e) => e.message,
              'message',
              contains('Invalid response format: expected JSON object'),
            ),
          ),
        );
      });

      test('throws error when response data is not a JSON object', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'message': 'Trip details retrieved successfully',
              'data': <dynamic>[],
            }),
            200,
          );
        });

        final service = TripDetailsApiService(client: mockClient);

        expect(
          () async => service.getTripById(tripId: 'trip123'),
          throwsA(
            isA<TripDetailsApiException>().having(
              (e) => e.message,
              'message',
              contains('Invalid response format: expected data object'),
            ),
          ),
        );
      });

      test('throws error when tripId is empty', () async {
        final mockClient = MockClient((request) async {
          return http.Response('{}', 200);
        });

        final service = TripDetailsApiService(client: mockClient);

        expect(
          () async => service.getTripById(tripId: ''),
          throwsA(
            isA<TripDetailsApiException>().having(
              (e) => e.message,
              'message',
              equals('Trip ID is required.'),
            ),
          ),
        );
      });

      test('throws error when tripId is whitespace only', () async {
        final mockClient = MockClient((request) async {
          return http.Response('{}', 200);
        });

        final service = TripDetailsApiService(client: mockClient);

        expect(
          () async => service.getTripById(tripId: '   '),
          throwsA(
            isA<TripDetailsApiException>().having(
              (e) => e.message,
              'message',
              equals('Trip ID is required.'),
            ),
          ),
        );
      });
    });

    group('Edge Cases', () {
      test('handles trip ID with special characters', () async {
        Uri? requestUri;
        final mockClient = MockClient((request) async {
          requestUri = request.url;
          return http.Response(
            buildTripDetailsResponse(tripId: 'trip-123_abc'),
            200,
          );
        });

        final service = TripDetailsApiService(client: mockClient);
        final result = await service.getTripById(tripId: 'trip-123_abc');

        expect(result.id, equals('trip-123_abc'));
        expect(
          requestUri.toString(),
          equals('https://lorry.workwista.com/api/users/trip/trip-123_abc/'),
        );
      });

      test('trims whitespace from tripId', () async {
        Uri? requestUri;
        final mockClient = MockClient((request) async {
          requestUri = request.url;
          return http.Response(buildTripDetailsResponse(), 200);
        });

        final service = TripDetailsApiService(client: mockClient);
        await service.getTripById(tripId: '  trip123  ');

        expect(
          requestUri.toString(),
          equals('https://lorry.workwista.com/api/users/trip/trip123/'),
        );
      });

      test('trims whitespace from accessToken', () async {
        String? authHeader;
        final mockClient = MockClient((request) async {
          authHeader = request.headers['Authorization'];
          return http.Response(buildTripDetailsResponse(), 200);
        });

        final service = TripDetailsApiService(client: mockClient);
        await service.getTripById(
          tripId: 'trip123',
          accessToken: '  test-token  ',
        );

        expect(authHeader, equals('Bearer test-token'));
      });

      test('does not include Authorization header when accessToken is empty', () async {
        String? authHeader;
        final mockClient = MockClient((request) async {
          authHeader = request.headers['Authorization'];
          return http.Response(buildTripDetailsResponse(), 200);
        });

        final service = TripDetailsApiService(client: mockClient);
        await service.getTripById(tripId: 'trip123', accessToken: '');

        expect(authHeader, isNull);
      });
    });
  });
}
