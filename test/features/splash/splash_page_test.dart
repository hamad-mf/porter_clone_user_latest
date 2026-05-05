import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porter_clone_user/features/splash/view/splash_page.dart';
import 'package:porter_clone_user/features/trip_details/view/trip_details_page.dart';
import 'package:porter_clone_user/features/sign_in/view/sign_in_page.dart';
import 'package:porter_clone_user/features/dashboard/view/dashboard_page.dart';

void main() {
  group('SplashPage Deep Link Routing Tests', () {
    testWidgets('accepts deepLinkTripId parameter', (WidgetTester tester) async {
      // Arrange
      const testTripId = 'test-trip-123';
      
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashPage(deepLinkTripId: testTripId),
        ),
      );
      
      // Assert - verify the widget builds without error
      expect(find.byType(SplashPage), findsOneWidget);
    });

    testWidgets('accepts null deepLinkTripId parameter', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashPage(deepLinkTripId: null),
        ),
      );
      
      // Assert - verify the widget builds without error
      expect(find.byType(SplashPage), findsOneWidget);
    });

    testWidgets('can be constructed without deepLinkTripId parameter', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashPage(),
        ),
      );
      
      // Assert - verify the widget builds without error
      expect(find.byType(SplashPage), findsOneWidget);
    });

    testWidgets('displays logo image', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashPage(),
        ),
      );
      
      // Assert
      expect(find.byType(Image), findsOneWidget);
    });
  });

  group('SplashPage Constructor Tests', () {
    test('deepLinkTripId parameter is optional', () {
      // Verify that SplashPage can be constructed with and without deepLinkTripId
      const splashWithTripId = SplashPage(deepLinkTripId: 'test-trip-123');
      const splashWithoutTripId = SplashPage();
      const splashWithNullTripId = SplashPage(deepLinkTripId: null);
      
      expect(splashWithTripId.deepLinkTripId, equals('test-trip-123'));
      expect(splashWithoutTripId.deepLinkTripId, isNull);
      expect(splashWithNullTripId.deepLinkTripId, isNull);
    });
  });
}
