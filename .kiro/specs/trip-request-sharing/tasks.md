# Implementation Plan: Trip Request Sharing

## Overview

This implementation plan breaks down the trip request sharing feature into discrete coding tasks. The feature enables users to share trip requests via deep links that open directly in the app, with proper authentication handling and navigation flows.

The implementation follows this sequence:
1. Set up core services and API integration
2. Implement deep link handling infrastructure
3. Add sharing functionality to the UI
4. Create trip details screen
5. Integrate with authentication and navigation flows

## Tasks

- [x] 1. Set up dependencies and Android configuration
  - Add `share_plus: ^7.2.1` and `app_links: ^3.5.0` to pubspec.yaml
  - Configure Android App Links in AndroidManifest.xml with intent filters for `lorry.workwista.com` and custom scheme `lorry://`
  - Add `android:autoVerify="true"` for HTTPS intent filter
  - _Requirements: 2.1, 2.2, 2.3, 2.4_

- [x] 2. Implement trip details API service
  - [x] 2.1 Create TripDetailsApiService class
    - Implement `getTripById()` method with GET request to `/api/trips/{tripId}/`
    - Handle 200 response by parsing Trip model
    - Handle 404 with TripNotFoundException
    - Handle other errors with TripDetailsApiException
    - Support optional accessToken parameter for authenticated requests
    - _Requirements: 6.2, 6.3_

  - [ ]* 2.2 Write property test for API service
    - **Property 3: URL Parsing Round-Trip**
    - **Validates: Requirements 3.1, 3.2, 3.3, 9.1, 9.2, 9.3, 9.4**

- [x] 3. Implement trip sharing service
  - [x] 3.1 Create TripSharingService class
    - Implement `shareTrip()` static method
    - Generate HTTPS URL in format `https://lorry.workwista.com/share/trip/{tripId}`
    - Format share text with pickup location, drop location, and vehicle size
    - Invoke `Share.share()` with generated URL and text
    - _Requirements: 1.1, 1.2, 1.3_

  - [ ]* 3.2 Write property test for share URL format
    - **Property 1: Share URL Format**
    - **Validates: Requirements 1.1**

  - [ ]* 3.3 Write property test for share text completeness
    - **Property 2: Share Text Completeness**
    - **Validates: Requirements 1.2**

- [x] 4. Implement deep link handler
  - [x] 4.1 Create DeepLinkHandler widget
    - Create StatefulWidget that wraps child widget
    - Initialize AppLinks instance in initState
    - Check for initial deep link using `getInitialLink()`
    - Set up stream listener for runtime deep links using `uriLinkStream`
    - Dispose stream subscription in dispose method
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 5.3, 5.4_

  - [x] 4.2 Implement URL parsing logic
    - Parse HTTPS URLs with pattern `https://lorry.workwista.com/share/trip/{tripId}`
    - Parse custom scheme URLs with pattern `lorry://trip/{tripId}`
    - Extract trip ID from URL path segments
    - Return null for invalid URL formats
    - Log errors for malformed URLs
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 9.1, 9.2, 9.3, 9.5_

  - [ ]* 4.3 Write property test for URL parsing round-trip
    - **Property 3: URL Parsing Round-Trip**
    - **Validates: Requirements 3.1, 3.2, 3.3, 9.1, 9.2, 9.3, 9.4**

  - [ ]* 4.4 Write property test for invalid URL handling
    - **Property 4: Invalid URL Handling**
    - **Validates: Requirements 3.4, 9.5**

  - [x] 4.5 Implement navigation logic for runtime deep links
    - Navigate to TripDetailsPage when deep link received while app is running
    - Push TripDetailsPage onto navigation stack with trip ID
    - Handle navigation context availability
    - _Requirements: 5.1, 5.2_

- [x] 5. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 6. Create trip details screen
  - [x] 6.1 Create TripDetailsPage widget
    - Create StatefulWidget with tripId and isFromDeepLink parameters
    - Implement loading state during data fetch
    - Fetch trip data using TripDetailsApiService in initState
    - Display all trip information (pickup, drop, load details, vehicle requirements, amount, pickup time)
    - Show error message if trip not found
    - Display accept button (functionality to be wired later)
    - _Requirements: 6.1, 6.2, 6.3, 6.4_

  - [ ]* 6.2 Write unit tests for TripDetailsPage
    - Test loading state display
    - Test successful trip data display
    - Test error state when trip not found
    - Test error state for network errors
    - _Requirements: 6.1, 6.2, 6.3_

- [x] 7. Update splash screen for deep link routing
  - [x] 7.1 Modify SplashScreen to accept deepLinkTripId parameter
    - Add optional `deepLinkTripId` parameter to SplashScreen constructor
    - Update routing logic to check for deepLinkTripId
    - If authenticated and deepLinkTripId present, navigate to TripDetailsPage
    - If unauthenticated and deepLinkTripId present, navigate to SignInPage (preserve trip ID)
    - Maintain existing routing logic when no deep link present
    - _Requirements: 4.1, 4.2, 4.3, 4.4_

  - [ ]* 7.2 Write unit tests for splash screen routing
    - Test routing with deep link + authenticated user
    - Test routing with deep link + unauthenticated user
    - Test routing without deep link
    - _Requirements: 4.1, 4.2, 4.3_

- [x] 8. Add share button to dashboard trip cards
  - [x] 8.1 Update dashboard trip card UI
    - Add share icon button to trip request card header
    - Wire share button to TripSharingService.shareTrip()
    - Pass trip ID, pickup location, drop location, and vehicle size from trip data
    - Handle share button tap event
    - _Requirements: 1.5, 1.6_

  - [ ]* 8.2 Write widget tests for share button
    - Test share button appears on trip cards
    - Test share button triggers TripSharingService
    - Test share button with various trip data
    - _Requirements: 1.5, 1.6_

- [x] 9. Integrate deep link handler with app root
  - [x] 9.1 Wrap app root with DeepLinkHandler
    - Update main.dart to wrap root widget with DeepLinkHandler
    - Pass initial deep link to SplashScreen if present
    - Ensure DeepLinkHandler initializes before app navigation
    - _Requirements: 8.1, 8.2_

  - [ ]* 9.2 Write integration tests for deep link flow
    - Test app launch with deep link navigates to trip details
    - Test runtime deep link navigates to trip details
    - Test deep link with authentication flow
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 5.1, 5.2_

- [x] 10. Implement authentication guard for trip acceptance
  - [x] 10.1 Add authentication check to trip acceptance flow
    - Check authentication status when user taps accept button
    - If unauthenticated, navigate to SignInPage with preserved trip ID
    - Store accept intent flag for post-login action
    - After successful login, return to TripDetailsPage
    - Automatically trigger accept action if accept intent flag is set
    - _Requirements: 7.1, 7.2, 7.3, 7.4_

  - [ ]* 10.2 Write integration tests for authentication guard
    - Test unauthenticated user redirected to login
    - Test trip ID preserved during login flow
    - Test accept action triggered after login
    - _Requirements: 7.1, 7.2, 7.3, 7.4_

- [x] 11. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Property tests validate universal correctness properties across all inputs
- Unit tests validate specific examples and edge cases
- Integration tests verify component interactions and end-to-end flows
- The implementation uses Dart/Flutter as specified in the design document
