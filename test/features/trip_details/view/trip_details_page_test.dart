import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porter_clone_user/features/trip_details/view/trip_details_page.dart';

void main() {
  group('TripDetailsPage Widget Tests', () {
    testWidgets('displays loading indicator initially', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TripDetailsPage(
            tripId: 'test-trip-id',
          ),
        ),
      );

      // Verify loading indicator is shown initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('has proper app bar with back button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TripDetailsPage(
            tripId: 'test-trip-id',
          ),
        ),
      );

      // Verify app bar elements
      expect(find.text('Trip Details'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('app bar has correct styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TripDetailsPage(
            tripId: 'test-trip-id',
          ),
        ),
      );

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, const Color(0xFFFFFFFF));
      expect(appBar.elevation, 0);
    });

    testWidgets('back button pops the page', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TripDetailsPage(
                        tripId: 'test-trip-id',
                      ),
                    ),
                  );
                },
                child: const Text('Open Trip Details'),
              ),
            ),
          ),
        ),
      );

      // Navigate to TripDetailsPage
      await tester.tap(find.text('Open Trip Details'));
      await tester.pump();
      await tester.pump();

      // Verify we're on TripDetailsPage
      expect(find.text('Trip Details'), findsOneWidget);

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      await tester.pump();

      // Verify we're back to the original page
      expect(find.text('Open Trip Details'), findsOneWidget);
      expect(find.text('Trip Details'), findsNothing);
    });

    testWidgets('isFromDeepLink parameter is accepted', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TripDetailsPage(
            tripId: 'test-trip-id',
            isFromDeepLink: true,
          ),
        ),
      );

      // Verify the widget builds without error
      expect(find.byType(TripDetailsPage), findsOneWidget);
    });

    testWidgets('tripId parameter is required', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TripDetailsPage(
            tripId: 'my-trip-123',
          ),
        ),
      );

      // Verify the widget builds with the tripId
      expect(find.byType(TripDetailsPage), findsOneWidget);
    });

    testWidgets('scaffold has correct background color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TripDetailsPage(
            tripId: 'test-trip-id',
          ),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFFF2F2F2));
    });
  });
}
