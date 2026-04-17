# Implementation Plan: Accepted Drivers Display

## Overview

This implementation integrates the accepted drivers API into the Flutter dashboard home screen. The work follows the existing architectural patterns: API services for network communication, model classes for data representation, and StatefulWidget for UI state management. The feature will replace the current static "Current Requests" section with real data from the backend.

## Tasks

- [ ] 1. Create data models for API response
  - [x] 1.1 Create TripAcceptance model class
    - Create `lib/core/models/trip_acceptance.dart`
    - Implement `TripAcceptance` class with all required fields (acceptanceId, tripId, tripStatus, pickupLocation, dropLocation, acceptedAt)
    - Implement `fromJson` factory constructor with proper JSON field mapping (snake_case to camelCase)
    - Parse `accepted_at` as ISO 8601 DateTime
    - _Requirements: 2.3, 2.5_
  
  - [x] 1.2 Create AcceptedDriver model class
    - Create `lib/core/models/accepted_driver.dart`
    - Implement `AcceptedDriver` class with all required fields (driverId, userId, fullName, phoneNumber, isVerified, acceptances)
    - Implement `fromJson` factory constructor with proper JSON field mapping
    - Handle empty acceptances array gracefully
    - _Requirements: 2.2, 2.3_

- [ ] 2. Implement API service for fetching accepted drivers
  - [x] 2.1 Create AcceptedDriversApiService class
    - Create `lib/core/services/accepted_drivers_api_service.dart`
    - Implement `getAcceptedDrivers` method that accepts accessToken parameter
    - Configure HTTP GET request to `https://lorry.workwista.com/api/users/trips/all/accepted-drivers/`
    - Add Authorization header with Bearer token format
    - Set 20-second timeout
    - Parse JSON response and extract "accepted_drivers" array
    - Convert JSON array to `List<AcceptedDriver>`
    - _Requirements: 1.1, 1.2, 1.3, 8.1, 8.2_
  
  - [x] 2.2 Implement error handling in API service
    - Create `AcceptedDriversApiException` class
    - Handle HTTP status codes (401, 500, network errors)
    - Throw appropriate exceptions with descriptive messages
    - Handle JSON parsing errors gracefully
    - _Requirements: 1.4, 1.5, 8.3, 8.4_

- [ ] 3. Checkpoint - Verify models and API service
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 4. Implement UI state management in DashboardHomeTab
  - [x] 4.1 Convert _DashboardHomeTab to StatefulWidget
    - Convert existing `_DashboardHomeTab` from StatelessWidget to StatefulWidget
    - Add state variables: `_isLoading`, `_errorMessage`, `_drivers`
    - Initialize state in `initState()` method
    - _Requirements: 1.1, 4.1_
  
  - [x] 4.2 Implement data fetching logic
    - Create `_fetchAcceptedDrivers()` method
    - Retrieve access token from `AuthLocalStorage`
    - Call `AcceptedDriversApiService.getAcceptedDrivers()`
    - Update state with fetched drivers or error message
    - Handle loading state transitions
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 8.1_
  
  - [x] 4.3 Implement pull-to-refresh functionality
    - Create `_refreshDrivers()` method
    - Wrap driver cards section with `RefreshIndicator`
    - Handle refresh state and update UI accordingly
    - Preserve existing data on refresh failure
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [ ] 5. Create driver card UI component
  - [x] 5.1 Create _AcceptedDriverCard widget
    - Create `_AcceptedDriverCard` StatelessWidget
    - Accept `AcceptedDriver` as constructor parameter
    - Display driver name (bold, 22px, Color(0xFF111827))
    - Display phone number (13px, Color(0xFF888888))
    - Add verification badge when `isVerified` is true
    - Use white background with 14px border radius
    - Apply 16px padding
    - _Requirements: 3.2, 3.3, 3.4_
  
  - [x] 5.2 Display trip acceptances in driver card
    - Iterate through driver's acceptances list
    - Display pickup → drop location with arrow icon
    - Display trip status badge
    - Format `acceptedAt` timestamp as relative time ("2 hours ago", "Yesterday", etc.)
    - Add dividers between multiple trip acceptances
    - Display acceptances in chronological order
    - _Requirements: 3.5, 3.6, 3.7, 9.1, 9.2, 9.3, 9.4_

- [ ] 6. Integrate accepted drivers section into dashboard
  - [x] 6.1 Update _DashboardHomeTab build method
    - Replace "Current Requests" section with "Accepted Drivers" section
    - Position section below "Create Trip" card
    - Add section header "Accepted Drivers"
    - Maintain consistent spacing (20px between sections)
    - _Requirements: 10.1, 10.3, 10.4_
  
  - [x] 6.2 Implement loading state UI
    - Display `CircularProgressIndicator` centered when `_isLoading` is true
    - Show loading indicator during initial fetch
    - Prevent interaction during loading
    - Hide loading indicator when data arrives or error occurs
    - _Requirements: 4.1, 4.2, 4.3, 4.4_
  
  - [x] 6.3 Implement empty state UI
    - Check if drivers list is empty after successful fetch
    - Display "No accepted drivers yet" message
    - Add icon (e.g., `Icons.local_shipping_outlined`) in empty state
    - Maintain layout structure in empty state
    - _Requirements: 5.1, 5.2, 5.3, 5.4_
  
  - [x] 6.4 Implement error state UI
    - Display error message when `_errorMessage` is not null
    - Show different messages for network vs API errors
    - Show authentication error for 401 responses
    - Add "Retry" button that calls `_fetchAcceptedDrivers()`
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_
  
  - [x] 6.5 Render driver cards list
    - Map `_drivers` list to `_AcceptedDriverCard` widgets
    - Add 12px spacing between cards
    - Ensure cards match existing design language
    - Use existing color scheme from dashboard
    - _Requirements: 3.1, 10.2, 10.4, 10.5_

- [ ] 7. Final checkpoint - Integration testing
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- All tasks build on existing Flutter patterns in the codebase
- API service follows the structure of `TripApiService` and `AuthApiService`
- UI components match the existing dashboard design language
- State management uses StatefulWidget pattern consistent with the codebase
- Each task references specific requirements for traceability
