import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porter_clone_user/features/dashboard/view/dashboard_page.dart';

void main() {
  group('DashboardPage Status Tab Tests', () {
    testWidgets('Bottom Navigation Bar has four items', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardPage(),
        ),
      );

      final bottomNavBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );

      expect(bottomNavBar.items.length, 4);
    });

    testWidgets('Status tab is at index 2 with correct icon and label',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardPage(),
        ),
      );

      final bottomNavBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );

      final statusItem = bottomNavBar.items[2];
      expect(statusItem.label, 'Status');
      expect((statusItem.icon as Icon).icon, Icons.assignment);
    });

    testWidgets('Status tab is positioned between My Trip and Profile',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardPage(),
        ),
      );

      final bottomNavBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );

      expect(bottomNavBar.items[1].label, 'My Trip');
      expect(bottomNavBar.items[2].label, 'Status');
      expect(bottomNavBar.items[3].label, 'Profile');
    });

    testWidgets('Existing tabs are preserved at correct positions',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardPage(),
        ),
      );

      final bottomNavBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );

      expect(bottomNavBar.items[0].label, 'Home');
      expect(bottomNavBar.items[1].label, 'My Trip');
      expect(bottomNavBar.items[3].label, 'Profile');
    });

    testWidgets('Navigation bar styling is preserved', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardPage(),
        ),
      );

      final bottomNavBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );

      expect(bottomNavBar.selectedItemColor, const Color(0xFF111827));
      expect(bottomNavBar.unselectedItemColor, const Color(0xFFC4C4C4));
      expect(bottomNavBar.elevation, 0);
    });

    testWidgets('Tapping Status tab updates selected index to 2',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardPage(),
        ),
      );
      await tester.pump();

      // Find the Status tab by its label
      final statusTab = find.text('Status');
      expect(statusTab, findsOneWidget);

      // Tap the Status tab
      await tester.tap(statusTab);
      await tester.pump();

      // Verify the Status tab is now selected
      final bottomNavBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNavBar.currentIndex, 2);
    });

    testWidgets('Status screen displays tap to view message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardPage(),
        ),
      );
      await tester.pump();

      // Tap the Status tab
      await tester.tap(find.text('Status'));
      await tester.pump();

      // Verify the status screen shows the tap to view message
      expect(find.text('View Status'), findsOneWidget);
      expect(find.text('Tap to view your trips'), findsOneWidget);
      expect(find.byIcon(Icons.assignment), findsWidgets);
    });

    testWidgets('Tapping Status screen navigates to StatusPage',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardPage(),
        ),
      );
      await tester.pump();

      // Tap the Status tab to show the status screen
      await tester.tap(find.text('Status'));
      await tester.pump();

      // Tap the status screen to navigate
      await tester.tap(find.text('View Status'));
      await tester.pump(); // Initial navigation
      await tester.pump(); // Allow StatusPage to build

      // Verify StatusPage is displayed by checking for its AppBar title
      // Note: There will be two "Status" texts - one in bottom nav, one in AppBar
      expect(find.text('Status'), findsWidgets);
      // Verify back button is present
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('StatusPage back button pops to Dashboard', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardPage(),
        ),
      );
      await tester.pump();

      // Navigate to Status tab
      await tester.tap(find.text('Status'));
      await tester.pump();

      // Tap to navigate to StatusPage
      await tester.tap(find.text('View Status'));
      await tester.pump();
      await tester.pump();

      // Verify we're on StatusPage
      expect(find.byType(BackButton), findsOneWidget);

      // Tap back button
      await tester.tap(find.byType(BackButton));
      await tester.pump();
      await tester.pump();

      // Verify we're back on Dashboard (status screen should be visible)
      expect(find.text('View Status'), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
    });
  });
}
