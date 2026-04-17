import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porter_clone_user/features/dashboard/view/dashboard_page.dart';

void main() {
  group('DashboardPage Property Tests', () {
    // Feature: status-screen, Property 1: For any valid tab index (0, 1, 2, or 3),
    // calling _onNavTap(index) should update _selectedIndex to that index value
    testWidgets(
        'Property: Navigation handler accepts all valid indices (0-3)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardPage(),
        ),
      );
      await tester.pump();

      // Test all valid indices
      final validIndices = [0, 1, 2, 3];

      for (final index in validIndices) {
        // Find the tab at the given index
        final bottomNavBar = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );

        // Get the label for the tab at this index
        final tabLabel = bottomNavBar.items[index].label!;

        // Tap the tab
        await tester.tap(find.text(tabLabel));
        await tester.pump();

        // Verify the selected index is updated
        final updatedBottomNavBar = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(
          updatedBottomNavBar.currentIndex,
          index,
          reason: 'Tapping tab at index $index should set currentIndex to $index',
        );
      }
    });

    testWidgets(
        'Property: Navigation handler maintains state across multiple taps',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardPage(),
        ),
      );
      await tester.pump();

      // Test sequence of navigation actions
      final navigationSequence = [0, 2, 1, 3, 2, 0, 3, 1];

      for (final index in navigationSequence) {
        final bottomNavBar = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        final tabLabel = bottomNavBar.items[index].label!;

        await tester.tap(find.text(tabLabel));
        await tester.pump();

        final updatedBottomNavBar = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(
          updatedBottomNavBar.currentIndex,
          index,
          reason: 'Navigation state should be maintained after multiple taps',
        );
      }
    });

    testWidgets(
        'Property: Each valid index corresponds to correct tab content',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardPage(),
        ),
      );
      await tester.pump();

      // Map of index to expected tab label
      final indexToLabel = {
        0: 'Home',
        1: 'My Trip',
        2: 'Status',
        3: 'Profile',
      };

      for (final entry in indexToLabel.entries) {
        final index = entry.key;
        final expectedLabel = entry.value;

        // Tap the tab
        await tester.tap(find.text(expectedLabel));
        await tester.pump();

        // Verify the correct index is selected
        final bottomNavBar = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(
          bottomNavBar.currentIndex,
          index,
          reason: 'Tab "$expectedLabel" should correspond to index $index',
        );
      }
    });
  });
}
