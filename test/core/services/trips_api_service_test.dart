import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:porter_clone_user/core/services/trips_api_service.dart';

void main() {
  group('TripsApiService', () {
    test('TripsApiException has correct message', () {
      final exception = TripsApiException('Test error');
      expect(exception.message, equals('Test error'));
      expect(exception.toString(), equals('Test error'));
    });

    group('Successful Response Parsing', () {
      test('returns correct map structure with three status keys', () async {
        // Arrange
        final mockClient = MockClient((request) async {
          return http.Response(
            '''
            {
              "message": "Trips retrieved successfully",
              "data": {
                "pending": {
                  "count": 1,
                  "trips": [
                    {
                      "id": "1",
                      "pickup_location": "Location A",
                      "drop_location": "Location B",
                      "load_size": "5 Ton",
                      "load_type": "General",
                      "vehicle_size": "15 Ton",
                      "body_type": "Open",
                      "trip_status": "pending",
                      "amount": "1000",
                      "pickup_time": "2024-01-15T10:00:00Z",
                      "name": "John Doe",
                      "contact_number": "1234567890",
                      "accepted_drivers": []
                    }
                  ]
                },
                "ongoing": {
                  "count": 0,
                  "trips": []
                },
                "completed": {
                  "count": 0,
                  "trips": []
                }
              }
            }
            ''',
            200,
          );
        });

        final service = TripsApiService(client: mockClient);

        // Act
        final result = await service.getTrips(accessToken: 'token');

        // Assert
        expect(result.keys, containsAll(['pending', 'ongoing', 'completed']));
        expect(result['pending']!.length, equals(1));
        expect(result['ongoing']!.length, equals(0));
        expect(result['completed']!.length, equals(0));
        expect(result['pending']![0].id, equals('1'));
      });

      test('returns empty list when trips field is null', () async {
        // Arrange
        final mockClient = MockClient((request) async {
          return http.Response(
            '''
            {
              "message": "Trips retrieved successfully",
              "data": {
                "pending": {
                  "count": 0,
                  "trips": null
                },
                "ongoing": {
                  "count": 0,
                  "trips": null
                },
                "completed": {
                  "count": 0,
                  "trips": null
                }
              }
            }
            ''',
            200,
          );
        });

        final service = TripsApiService(client: mockClient);

        // Act
        final result = await service.getTrips(accessToken: 'token');

        // Assert
        expect(result['pending'], isEmpty);
        expect(result['ongoing'], isEmpty);
        expect(result['completed'], isEmpty);
      });

      test('returns empty list when trips field is missing', () async {
        // Arrange
        final mockClient = MockClient((request) async {
          return http.Response(
            '''
            {
              "message": "Trips retrieved successfully",
              "data": {
                "pending": {
                  "count": 0
                },
                "ongoing": {
                  "count": 0
                },
                "completed": {
                  "count": 0
                }
              }
            }
            ''',
            200,
          );
        });

        final service = TripsApiService(client: mockClient);

        // Act
        final result = await service.getTrips(accessToken: 'token');

        // Assert
        expect(result['pending'], isEmpty);
        expect(result['ongoing'], isEmpty);
        expect(result['completed'], isEmpty);
      });

      test('returns empty lists when status object is null', () async {
        // Arrange
        final mockClient = MockClient((request) async {
          return http.Response(
            '''
            {
              "message": "Trips retrieved successfully",
              "data": {
                "pending": null,
                "ongoing": null,
                "completed": null
              }
            }
            ''',
            200,
          );
        });

        final service = TripsApiService(client: mockClient);

        // Act
        final result = await service.getTrips(accessToken: 'token');

        // Assert
        expect(result['pending'], isEmpty);
        expect(result['ongoing'], isEmpty);
        expect(result['completed'], isEmpty);
      });

      test('returns empty lists when data field is null', () async {
        // Arrange
        final mockClient = MockClient((request) async {
          return http.Response(
            '''
            {
              "message": "Trips retrieved successfully",
              "data": null
            }
            ''',
            200,
          );
        });

        final service = TripsApiService(client: mockClient);

        // Act
        final result = await service.getTrips(accessToken: 'token');

        // Assert
        expect(result['pending'], isEmpty);
        expect(result['ongoing'], isEmpty);
        expect(result['completed'], isEmpty);
      });
    });

    group('Error Handling', () {
      test('throws authentication error on 401 status code', () async {
        // Arrange
        final mockClient = MockClient((request) async {
          return http.Response('Unauthorized', 401);
        });

        final service = TripsApiService(client: mockClient);

        // Act & Assert
        expect(
          () async => await service.getTrips(accessToken: 'token'),
          throwsA(
            isA<TripsApiException>().having(
              (e) => e.message,
              'message',
              contains('Authentication failed'),
            ),
          ),
        );
      });

      test('throws server error on 500 status code', () async {
        // Arrange
        final mockClient = MockClient((request) async {
          return http.Response('Internal Server Error', 500);
        });

        final service = TripsApiService(client: mockClient);

        // Act & Assert
        expect(
          () async => await service.getTrips(accessToken: 'token'),
          throwsA(
            isA<TripsApiException>().having(
              (e) => e.message,
              'message',
              contains('Server error'),
            ),
          ),
        );
      });

      test('throws timeout error when request times out', () async {
        // Arrange
        final mockClient = MockClient((request) async {
          await Future.delayed(const Duration(seconds: 25));
          return http.Response('', 200);
        });

        final service = TripsApiService(client: mockClient);

        // Act & Assert
        expect(
          () async => await service.getTrips(accessToken: 'token'),
          throwsA(
            isA<TripsApiException>().having(
              (e) => e.message,
              'message',
              contains('Request timed out'),
            ),
          ),
        );
      });

      test('throws network error on ClientException', () async {
        // Arrange
        final mockClient = MockClient((request) async {
          throw http.ClientException('Network error');
        });

        final service = TripsApiService(client: mockClient);

        // Act & Assert
        expect(
          () async => await service.getTrips(accessToken: 'token'),
          throwsA(
            isA<TripsApiException>().having(
              (e) => e.message,
              'message',
              contains('Network error'),
            ),
          ),
        );
      });

      test('throws parsing error on invalid JSON', () async {
        // Arrange
        final mockClient = MockClient((request) async {
          return http.Response('invalid json', 200);
        });

        final service = TripsApiService(client: mockClient);

        // Act & Assert
        expect(
          () async => await service.getTrips(accessToken: 'token'),
          throwsA(
            isA<TripsApiException>().having(
              (e) => e.message,
              'message',
              contains('Failed to parse response'),
            ),
          ),
        );
      });

      test('throws error when response is not a JSON object', () async {
        // Arrange
        final mockClient = MockClient((request) async {
          return http.Response('[]', 200);
        });

        final service = TripsApiService(client: mockClient);

        // Act & Assert
        expect(
          () async => await service.getTrips(accessToken: 'token'),
          throwsA(
            isA<TripsApiException>().having(
              (e) => e.message,
              'message',
              contains('Invalid response format: expected JSON object'),
            ),
          ),
        );
      });
    });

    group('Request Configuration', () {
      test('includes Authorization header with Bearer token', () async {
        // Arrange
        String? authHeader;
        final mockClient = MockClient((request) async {
          authHeader = request.headers['Authorization'];
          return http.Response(
            '''
            {
              "message": "Success",
              "data": {
                "pending": {"count": 0, "trips": []},
                "ongoing": {"count": 0, "trips": []},
                "completed": {"count": 0, "trips": []}
              }
            }
            ''',
            200,
          );
        });

        final service = TripsApiService(client: mockClient);

        // Act
        await service.getTrips(accessToken: 'test-token');

        // Assert
        expect(authHeader, equals('Bearer test-token'));
      });

      test('makes GET request to correct endpoint', () async {
        // Arrange
        Uri? requestUri;
        final mockClient = MockClient((request) async {
          requestUri = request.url;
          return http.Response(
            '''
            {
              "message": "Success",
              "data": {
                "pending": {"count": 0, "trips": []},
                "ongoing": {"count": 0, "trips": []},
                "completed": {"count": 0, "trips": []}
              }
            }
            ''',
            200,
          );
        });

        final service = TripsApiService(client: mockClient);

        // Act
        await service.getTrips(accessToken: 'token');

        // Assert
        expect(
          requestUri.toString(),
          equals('https://lorry.workwista.com/api/users/trips/by-status/'),
        );
      });
    });
  });
}
