# Implementation Plan: Status Screen Feature

## Overview

This implementation plan converts the Status Screen design into discrete coding tasks. The feature adds a tabbed interface to display user trips grouped by status (Ongoing, Completed, Pending), replacing the current blank placeholder in the Dashboard. The implementation follows the app's existing architecture with a feature-based structure, API service layer, and proper state management.

## Tasks

- [x] 1. Set up Trip data model
  - Create `lib/core/models/trip.dart` file
  - Implement Trip class with all required fields (id, pickupLocation, dropLocation, loadSize, loadType, vehicleSize, bodyType, tripStatus, amount, pickupTime, name, contactNumber, acceptedDrivers)
  - Implement `fromJson` factory constructor for JSON deserialization
  - Implement `toJson` method for JSON serialization
  - Handle null/missing acceptedDrivers field with empty list default
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 3.10, 3.11, 3.12, 3.13, 3.14, 3.15_

- [ ]* 1.1 Write property test for Trip model JSON round trip
  - **Property 1: Trip Model JSON Round Trip**
  - **Validates: Requirements 3.15, 5.1, 5.4**
  - Generate random Trip objects, serialize with toJson(), deserialize with fromJson(), assert all fields preserved

- [x] 2. Implement Trips API Service
  - Create `lib/core/services/trips_api_service.dart` file
  - Define TripsApiException class with message field
  - Implement getTrips method that accepts accessToken parameter
  - Make GET request to https://lorry.workwista.com/api/users/trips/by-status/
  - Include Authorization header with Bearer token
  - Set 20-second timeout for requests
  - Parse response JSON structure (message, data with pending/ongoing/completed objects)
  - Return Map<String, List<Trip>> with three status keys
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.10, 5.1, 5.2, 5.3, 5.4_

- [x] 2.1 Add error handling to Trips API Service
  - Throw TripsApiException with authentication message on 401 status
  - Throw TripsApiException with server error message on 500 status
  - Throw TripsApiException with timeout message on timeout
  - Throw TripsApiException with network error message on network failures
  - Throw TripsApiException with parse error message on invalid JSON
  - Return empty list when trips field is null or missing
  - _Requirements: 4.7, 4.8, 4.9, 5.5, 5.6_

- [ ]* 2.2 Write unit tests for Trips API Service
  - Test successful response parsing with all three status categories
  - Test 401 error throws authentication exception
  - Test 500 error throws server exception
  - Test timeout throws timeout exception
  - Test null/missing trips field returns empty list
  - Test invalid JSON throws parse exception

- [x] 3. Create StatusPage widget structure
  - Create `lib/features/status/view/status_page.dart` file
  - Implement StatusPage as StatefulWidget
  - Add AppBar with "Status" title
  - Use background color Color(0xFFF2F2F2)
  - Set up DefaultTabController with length 3
  - Create TabBar with three tabs: "Ongoing", "Completed", "Pending"
  - Style selected tab with white background and border outline
  - Style unselected tabs with gray background (Color(0xFFEEEEEE))
  - Add TabBarView with three corresponding views
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

- [x] 4. Implement trip fetching and state management
  - Add state variables: _isLoading, _errorMessage, _ongoingTrips, _completedTrips, _pendingTrips
  - Implement _fetchTrips method that retrieves access token from AuthLocalStorage
  - Call TripsApiService.getTrips with access token
  - Parse response and populate trip lists by status
  - Handle loading state with circular progress indicator
  - Handle error state with error message display
  - Call _fetchTrips in initState
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7_

- [ ]* 4.1 Write property test for status filtering correctness
  - **Property 2: Status Filtering Correctness**
  - **Validates: Requirements 6.5, 6.6, 6.7**
  - Generate random lists of trips with mixed statuses, filter by status, assert all returned trips have correct status

- [x] 5. Create TripCard widget
  - Implement _TripCard as StatelessWidget accepting Trip parameter
  - Display truck icon on left side (24px)
  - Extract city names from pickup and drop locations using _extractCityName helper
  - Display route as "PickupCity → DropCity" with arrow
  - Display status badge with appropriate color (green for accepted, blue for ongoing, orange for pending, gray for completed)
  - Display vehicle size below route
  - Display chevron right icon on right side (20px)
  - Display checkmark icon for completed trips
  - Format and display pickup time using _formatPickupTime helper
  - Display full pickup and drop location details
  - Use white background with 14px border radius
  - Apply consistent 16px padding
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 7.8, 7.9, 7.10, 7.11_

- [x] 5.1 Implement time formatting helper
  - Create _formatPickupTime method that accepts DateTime
  - Return "Today HH:MM AM/PM" when pickup is today
  - Return "Tomorrow HH:MM AM/PM" when pickup is tomorrow
  - Return "MMM DD HH:MM AM/PM" for other dates
  - Use 12-hour clock format with AM/PM
  - Use intl package DateFormat for formatting
  - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5_

- [ ]* 5.2 Write property test for time formatting
  - **Property 5: Time Formatting Uses 12-Hour Clock**
  - **Validates: Requirements 12.4, 12.5**
  - Generate random DateTime values, format for display, assert result contains "AM" or "PM"

- [x] 5.3 Implement city name extraction helper
  - Create _extractCityName method that accepts full address string
  - Split address by comma and return first segment
  - Trim whitespace from extracted city name
  - _Requirements: 13.1, 13.2, 13.3, 13.4_

- [ ]* 5.4 Write property test for city name extraction
  - **Property 4: City Name Extraction Preserves First Segment**
  - **Validates: Requirements 13.1, 13.2, 13.3**
  - Generate random addresses with commas, extract city name, assert result equals trimmed first segment

- [ ]* 5.5 Write property test for trip card content
  - **Property 3: Trip Card Contains Required Information**
  - **Validates: Requirements 7.3, 7.4, 7.5, 7.9**
  - Generate random Trip objects, render as TripCard, assert widget tree contains route, vehicle size, status badge, pickup time

- [ ]* 5.6 Write unit tests for TripCard widget
  - Test truck icon is displayed
  - Test route displays in "CityA → CityB" format
  - Test status badge is displayed with correct color
  - Test vehicle size is displayed
  - Test chevron right icon is displayed
  - Test checkmark icon is displayed for completed trips only
  - Test pickup time is formatted correctly for today/tomorrow/other dates
  - Test white background with rounded corners
  - Test location details are displayed

- [x] 6. Implement empty state widget
  - Create _EmptyState as StatelessWidget accepting status parameter
  - Display gray truck icon (64px)
  - Display "No [status] trips" message
  - Use gray color scheme (Color(0xFF6B7280))
  - Center content in tab view
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [x] 7. Implement error state widget
  - Create _ErrorState as StatelessWidget accepting errorMessage and onRetry parameters
  - Display red error icon (48px)
  - Display error message text
  - Display "Retry" button that calls onRetry callback
  - Preserve tab navigation in error state
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6_

- [x] 8. Implement pull-to-refresh functionality
  - Wrap each TabBarView child with RefreshIndicator
  - Implement _refreshTrips method that fetches trips from API
  - Display loading indicator during refresh
  - Update trip lists on successful refresh
  - Show SnackBar with error message on refresh failure
  - Preserve current tab selection during refresh
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6_

- [ ]* 8.1 Write unit tests for StatusPage widget
  - Test AppBar displays "Status" title
  - Test background color is Color(0xFFF2F2F2)
  - Test TabBar displays three tabs in correct order
  - Test selected tab has white background
  - Test unselected tabs have gray background
  - Test loading indicator displays during initial fetch
  - Test trip cards display after successful fetch
  - Test error state displays with retry button on failure
  - Test empty state displays when tab has no trips
  - Test retry button triggers new fetch
  - Test pull-to-refresh triggers new fetch
  - Test pull-to-refresh preserves tab selection
  - Test error during refresh shows SnackBar

- [x] 9. Update Dashboard navigation
  - Modify `lib/features/dashboard/view/dashboard_page.dart`
  - Update _StatusScreen widget to navigate to StatusPage on tap
  - Use Navigator.push to push StatusPage onto navigation stack
  - Ensure StatusPage displays back button in AppBar
  - Verify back button pops to Dashboard
  - _Requirements: 11.1, 11.2, 11.3, 11.4_

- [ ]* 9.1 Write navigation tests
  - Test _StatusScreen navigates to StatusPage
  - Test StatusPage displays back button
  - Test back button pops to Dashboard

- [x] 10. Apply consistent styling
  - Verify Status_Page uses app color scheme (0xFF111827 for dark, 0xFFF2F2F2 for background)
  - Verify Trip_Card styling matches Dashboard_Page cards
  - Verify fonts match existing app typography
  - Verify spacing and padding consistent with Dashboard_Page
  - Verify loading and error states match Dashboard_Page patterns
  - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5_

- [x] 11. Add intl package dependency
  - Add `intl: ^0.18.0` to pubspec.yaml dependencies
  - Run `flutter pub get` to install package
  - Import intl package in status_page.dart for DateFormat

- [x] 12. Final checkpoint - Ensure all tests pass
  - Run all unit tests and verify they pass
  - Run all property tests and verify they pass
  - Test navigation flow from Dashboard to Status screen
  - Test all three tabs display correct trips
  - Test pull-to-refresh on all tabs
  - Test error handling and retry functionality
  - Test empty states for tabs with no trips
  - Verify time formatting displays correctly
  - Verify city name extraction works correctly
  - Ask the user if questions arise

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Property tests validate universal correctness properties across all inputs
- Unit tests validate specific examples, edge cases, and UI configurations
- The implementation follows the app's existing patterns from Dashboard and AcceptedDriversApiService
- All API calls include proper error handling with user-friendly messages
- The feature is isolated in the `features/status/` directory for maintainability
