import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:porter_clone_user/core/services/accepted_drivers_api_service.dart';

void main() {
  group('AcceptedDriversApiService', () {
    test('AcceptedDriversApiException has correct message', () {
      final exception = AcceptedDriversApiException('Test error');
      expect(exception.message, equals('Test error'));
      expect(exception.toString(), equals('Test error'));
    });

    group('Error Handling', () {
      test('throws authentication error on 401 status code', () async {
        // Arrange
        final mockClient = MockClient((request) async {
          return http.Response('Unauthorized', 401);
        });

        final service = AcceptedDriversApiService(client: mockClient);

        // Act & Assert
        expect(
          () async => await service.getAcceptedDrivers(accessToken: 'token'),
          throwsA(
            isA<AcceptedDriversApiException>().having(
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

        final service = AcceptedDriversApiService(client: mockClient);

        // Act & Assert
        expect(
          () async => await service.getAcceptedDrivers(accessToken: 'token'),
          throwsA(
            isA<AcceptedDriversApiException>().having(
              (e) => e.message,
              'message',
              contains('Server error'),
            ),
          ),
        );
      });

      test('throws generic error on other non-2xx status codes', () async {
        // Arrange
        final mockClient = MockClient((request) async {
          return http.Response('Bad Request', 400);
        });

        final service = AcceptedDriversApiService(client: mockClient);

        // Act & Assert
        expect(
          () async => await service.getAcceptedDrivers(accessToken: 'token'),
          throwsA(
            isA<AcceptedDriversApiException>().having(
              (e) => e.message,
              'message',
              contains('Failed to fetch accepted drivers'),
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

        final service = AcceptedDriversApiService(client: mockClient);

        // Act & Assert
        expect(
          () async => await service.getAcceptedDrivers(accessToken: 'token'),
          throwsA(
            isA<AcceptedDriversApiException>().having(
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

        final service = AcceptedDriversApiService(client: mockClient);

        // Act & Assert
        expect(
          () async => await service.getAcceptedDrivers(accessToken: 'token'),
          throwsA(
            isA<AcceptedDriversApiException>().having(
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

        final service = AcceptedDriversApiService(client: mockClient);

        // Act & Assert
        expect(
          () async => await service.getAcceptedDrivers(accessToken: 'token'),
          throwsA(
            isA<AcceptedDriversApiException>().having(
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

        final service = AcceptedDriversApiService(client: mockClient);

        // Act & Assert
        expect(
          () async => await service.getAcceptedDrivers(accessToken: 'token'),
          throwsA(
            isA<AcceptedDriversApiException>().having(
              (e) => e.message,
              'message',
              contains('Invalid response format: expected JSON object'),
            ),
          ),
        );
      });

      test('throws error when accepted_drivers is not an array', () async {
        // Arrange
        final mockClient = MockClient((request) async {
          return http.Response('{"accepted_drivers": "not an array"}', 200);
        });

        final service = AcceptedDriversApiService(client: mockClient);

        // Act & Assert
        expect(
          () async => await service.getAcceptedDrivers(accessToken: 'token'),
          throwsA(
            isA<AcceptedDriversApiException>().having(
              (e) => e.message,
              'message',
              contains('accepted_drivers must be an array'),
            ),
          ),
        );
      });
    });
  });
}
