# Implementation Plan: Profile Completion Flow

## Overview

This implementation plan breaks down the Profile Completion Flow feature into discrete coding tasks. The feature enables users to complete their profile by providing their full name after OTP verification, with seamless integration into the existing authentication flow. The implementation follows a bottom-up approach: foundation (models and storage), API service, UI components, integration, and testing.

## Tasks

- [x] 1. Create UserProfile data model
  - [x] 1.1 Implement UserProfile class with nullable fullName field
    - Create `lib/core/models/user_profile.dart`
    - Add `fromJson` factory constructor for API response parsing
    - Add `toJson` method for serialization
    - Add `copyWith` method for immutable updates
    - _Requirements: 9.1, 9.2, 9.3, 9.4_

  - [ ]* 1.2 Write property test for UserProfile serialization
    - **Property 17: Profile Model Serialization Round Trip**
    - **Validates: Requirements 9.3**
    - Test that serializing to JSON and deserializing produces equivalent object
    - Test with various names including null, Unicode characters, special characters
    - _Requirements: 9.3_

- [x] 2. Create ProfileLocalStorage for caching
  - [x] 2.1 Implement ProfileLocalStorage class
    - Create `lib/core/storage/profile_local_storage.dart`
    - Add `saveProfile` method to store profile as JSON string
    - Add `getProfile` method to retrieve and deserialize profile
    - Add `clearProfile` method to remove cached data
    - Follow the pattern from `AuthLocalStorage`
    - _Requirements: 10.1, 10.2, 10.3, 10.4_

  - [ ]* 2.2 Write property test for profile caching
    - **Property 6: Profile Data Caching After Successful API Operations**
    - **Validates: Requirements 3.3, 5.3, 10.2, 10.3**
    - Test that saved profiles can be retrieved correctly
    - Test with various profile states (null name, valid name, empty string)
    - _Requirements: 10.1, 10.2, 10.3_

- [x] 3. Create ProfileApiService
  - [x] 3.1 Implement ProfileApiService class with viewProfile method
    - Create `lib/core/services/profile_api_service.dart`
    - Add `ProfileApiException` class for error handling
    - Implement `viewProfile` method with GET request to view profile endpoint
    - Include Bearer token in Authorization header
    - Parse response and return UserProfile instance
    - Handle timeout (20 seconds) and network errors
    - _Requirements: 8.1, 8.3, 8.4, 8.5_

  - [x] 3.2 Implement updateProfile method
    - Add `updateProfile` method with POST request using multipart/form-data
    - Include Bearer token in Authorization header
    - Send full_name field in request body
    - Parse response and extract profile from data field
    - Handle errors and extract message/detail fields
    - _Requirements: 8.1, 8.2, 8.4, 8.5_

  - [ ]* 3.3 Write property test for Bearer token authentication
    - **Property 4: Bearer Token Authentication on All Profile API Calls**
    - **Validates: Requirements 2.2, 3.2**
    - Test that all API calls include Authorization header with Bearer token
    - _Requirements: 2.2, 3.2_

  - [ ]* 3.4 Write property test for API exception handling
    - **Property 18: API Exception Handling**
    - **Validates: Requirements 8.4**
    - Test that 4xx/5xx responses throw ProfileApiException
    - Test error message extraction from response body
    - _Requirements: 8.4_

  - [ ]* 3.5 Write unit tests for ProfileApiService
    - Test successful viewProfile returns UserProfile
    - Test successful updateProfile returns updated UserProfile
    - Test 401 error throws exception with auth message
    - Test timeout throws exception with timeout message
    - Test malformed JSON throws exception
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [x] 4. Checkpoint - Ensure foundation tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Create ProfileCompletionPage UI
  - [x] 5.1 Create ProfileCompletionPage widget structure
    - Create `lib/features/profile_completion/view/profile_completion_page.dart`
    - Add StatefulWidget with form state management
    - Add TextEditingController for name input
    - Add loading state and error message state variables
    - _Requirements: 1.1, 1.2, 1.3, 1.4_

  - [x] 5.2 Implement ProfileCompletionPage UI layout
    - Add background color (0xFFF5F5F5) matching verification screen
    - Add back button in top-left
    - Add title "Complete Your Profile" (28px, weight 800, color 0xFF111827)
    - Add subtitle "Please enter your full name to continue" (13px, weight 400, color 0xFF9CA3AF)
    - Add text input field with white background and rounded corners
    - Add submit button "Continue" (color 0xFF111827, 54px height, 12px border radius)
    - _Requirements: 1.2, 1.3, 1.4, 1.5_

  - [x] 5.3 Implement form validation and submission logic
    - Validate that full name is not empty or whitespace-only
    - Call ProfileApiService.updateProfile on submit
    - Show loading indicator during API call
    - On success, call ProfileApiService.viewProfile
    - Cache result with ProfileLocalStorage.saveProfile
    - Navigate to DashboardPage with pushAndRemoveUntil
    - On error, display SnackBar with error message
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 3.1, 3.2, 3.3, 3.4_

  - [ ]* 5.4 Write property test for input validation
    - **Property 3: Input Validation Before API Submission**
    - **Validates: Requirements 2.5**
    - Test that empty and whitespace-only strings are rejected
    - Test various whitespace combinations (spaces, tabs, newlines)
    - _Requirements: 2.5_

  - [ ]* 5.5 Write property test for API call sequence
    - **Property 5: API Call Sequence After Profile Update**
    - **Validates: Requirements 2.3, 3.1**
    - Test that viewProfile is called after successful updateProfile
    - _Requirements: 2.3, 3.1_

  - [ ]* 5.6 Write property test for navigation after completion
    - **Property 7: Navigation After Successful Profile Completion**
    - **Validates: Requirements 3.4**
    - Test that navigation uses pushAndRemoveUntil to clear stack
    - _Requirements: 3.4_

  - [ ]* 5.7 Write property test for error display
    - **Property 8: Error Message Display on API Failure**
    - **Validates: Requirements 2.4**
    - Test that failed API calls display error message via SnackBar
    - _Requirements: 2.4_

  - [ ]* 5.8 Write property test for loading indicator
    - **Property 19: Loading Indicator Display During API Operations**
    - **Validates: Requirements 1.5**
    - Test that loading indicator is visible during API calls
    - Test that user input is disabled during loading
    - _Requirements: 1.5_

  - [ ]* 5.9 Write unit tests for ProfileCompletionPage widget
    - Test UI elements are displayed correctly
    - Test submit button disabled when input is empty
    - Test navigation on success
    - Test error display on failure
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.4_

- [x] 6. Modify VerificationPage for profile check
  - [x] 6.1 Update VerificationPage navigation logic
    - Modify `lib/features/verification/view/verification_page.dart`
    - Replace direct dashboard navigation with profile check
    - After token storage, call ProfileApiService.viewProfile
    - Cache profile with ProfileLocalStorage.saveProfile
    - If fullName is null or empty, navigate to ProfileCompletionPage
    - If fullName exists, navigate to DashboardPage
    - On API failure, gracefully navigate to DashboardPage
    - _Requirements: 1.1, 3.5, 5.5, 7.1, 7.2, 7.3, 7.4, 7.5_

  - [ ]* 6.2 Write property test for profile completion navigation
    - **Property 1: Profile Completion Navigation for Incomplete Profiles**
    - **Validates: Requirements 1.1, 7.1, 7.3, 7.4**
    - Test navigation to ProfileCompletionPage when fullName is null or empty
    - _Requirements: 1.1, 7.1, 7.3, 7.4_

  - [ ]* 6.3 Write property test for profile completion skip
    - **Property 2: Profile Completion Skip for Complete Profiles**
    - **Validates: Requirements 7.2, 7.5**
    - Test navigation directly to DashboardPage when fullName exists
    - _Requirements: 7.2, 7.5_

  - [ ]* 6.4 Write property test for graceful degradation
    - **Property 14: Graceful Degradation on View Profile Failure**
    - **Validates: Requirements 3.5, 5.5**
    - Test that failed viewProfile calls don't block navigation to dashboard
    - _Requirements: 3.5, 5.5_

- [x] 7. Checkpoint - Ensure profile completion flow works
  - Ensure all tests pass, ask the user if questions arise.

- [x] 8. Modify DashboardPage to display dynamic name
  - [x] 8.1 Update _WelcomeHeader widget in DashboardPage
    - Modify `lib/features/dashboard/view/dashboard_page.dart`
    - Convert _WelcomeHeader to StatefulWidget
    - Add state variable for display name (default "User")
    - In initState, call ProfileLocalStorage.getProfile
    - Update display name if profile exists and fullName is not null/empty
    - Display "Welcome Back" followed by the full name
    - Maintain tap navigation to ProfilePage
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

  - [ ]* 8.2 Write property test for dynamic name display
    - **Property 9: Dynamic Name Display in Home Screen**
    - **Validates: Requirements 4.1, 4.2**
    - Test that cached profile with fullName displays in app bar
    - Test default "User" displays when profile is null or empty
    - _Requirements: 4.1, 4.2_

  - [ ]* 8.3 Write unit tests for _WelcomeHeader widget
    - Test default name displays when no profile cached
    - Test dynamic name displays when profile cached
    - Test navigation to ProfilePage on tap
    - _Requirements: 4.1, 4.2, 4.5_

- [x] 9. Modify ProfilePage to integrate APIs
  - [x] 9.1 Update ProfilePage to load profile from API
    - Modify `lib/features/profile/view/profile_page.dart`
    - Add state variables: _profile, _isLoading, _isEditing, _nameController
    - In initState, call ProfileApiService.viewProfile
    - Display loading indicator while fetching
    - Replace hardcoded "Arun Prakash" with dynamic profile.fullName
    - Handle API errors with error message display
    - _Requirements: 6.1, 6.3, 6.5_

  - [x] 9.2 Add profile edit functionality to ProfilePage
    - Add edit button to enable editing mode
    - Show text field with current name when editing
    - On save, call ProfileApiService.updateProfile
    - On success, call ProfileApiService.viewProfile to refresh
    - Update cached profile with ProfileLocalStorage.saveProfile
    - Display success/error messages appropriately
    - _Requirements: 6.2, 6.4, 6.5_

  - [ ]* 9.3 Write property test for profile screen data loading
    - **Property 10: Profile Screen Data Loading**
    - **Validates: Requirements 6.1**
    - Test that ProfilePage calls viewProfile on open
    - _Requirements: 6.1_

  - [ ]* 9.4 Write property test for profile screen data update
    - **Property 11: Profile Screen Data Update**
    - **Validates: Requirements 6.2**
    - Test that profile edits call updateProfile with new name
    - _Requirements: 6.2_

  - [ ]* 9.5 Write property test for cross-screen data propagation
    - **Property 12: Cross-Screen Data Propagation**
    - **Validates: Requirements 6.4**
    - Test that updated profile reflects in DashboardPage without restart
    - _Requirements: 6.4_

  - [ ]* 9.6 Write unit tests for ProfilePage
    - Test profile loading on init
    - Test edit mode toggle
    - Test profile update success
    - Test error handling
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 10. Add profile fetch on app initialization
  - [x] 10.1 Update app startup to preload profile
    - Modify `lib/main.dart` or splash screen
    - Check if Bearer token exists in AuthLocalStorage
    - If token exists, call ProfileApiService.viewProfile
    - Cache result with ProfileLocalStorage.saveProfile
    - Continue to dashboard regardless of API success/failure
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

  - [ ]* 10.2 Write property test for profile fetch on initialization
    - **Property 13: Profile Fetch on App Initialization**
    - **Validates: Requirements 5.1**
    - Test that app calls viewProfile when token exists
    - _Requirements: 5.1_

  - [ ]* 10.3 Write property test for cached data fallback
    - **Property 15: Cached Data Fallback on API Failure**
    - **Validates: Requirements 10.5**
    - Test that cached profile is used when API fails
    - _Requirements: 10.5_

- [x] 11. Implement logout profile clearing
  - [x] 11.1 Update logout functionality to clear profile
    - Find logout implementation in the app
    - Add ProfileLocalStorage.clearProfile() call alongside AuthLocalStorage.clearTokens()
    - Ensure profile data is cleared when user logs out
    - _Requirements: 10.4_

  - [ ]* 11.2 Write property test for profile clearing on logout
    - **Property 16: Profile Data Cleared on Logout**
    - **Validates: Requirements 10.4**
    - Test that logout clears all cached profile data
    - _Requirements: 10.4_

- [x] 12. Final checkpoint - Integration testing
  - Ensure all tests pass, ask the user if questions arise.

- [x] 13. Wire all components together and verify end-to-end flow
  - [x] 13.1 Test complete new user flow
    - Sign in with new phone number
    - Verify profile completion screen appears
    - Enter name and submit
    - Verify dashboard shows correct name
    - _Requirements: All_

  - [x] 13.2 Test returning user flow
    - Sign in with existing account
    - Verify profile completion screen is skipped
    - Verify dashboard shows cached name immediately
    - _Requirements: 7.2, 7.5, 4.1, 4.2_

  - [x] 13.3 Test profile edit flow
    - Navigate to profile screen
    - Edit name and save
    - Return to dashboard
    - Verify updated name appears
    - _Requirements: 6.2, 6.4_

  - [x] 13.4 Verify graceful degradation
    - Test with network disabled
    - Verify cached data displays
    - Verify error messages are user-friendly
    - Verify app doesn't crash on API failures
    - _Requirements: 3.5, 5.5, 10.5_

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation at key milestones
- Property tests validate universal correctness properties (20 properties total)
- Unit tests validate specific examples and edge cases
- The implementation follows a bottom-up approach: foundation → services → UI → integration
- All new code should follow existing patterns from AuthApiService and AuthLocalStorage
- Graceful degradation is a key principle: never block user access to the app
