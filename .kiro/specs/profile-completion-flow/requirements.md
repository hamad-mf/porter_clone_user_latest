# Requirements Document

## Introduction

The Profile Completion Flow feature enables users to complete their profile by providing their full name after successful OTP verification. This feature ensures that user profile data is collected immediately after authentication and is available throughout the app, particularly in the home screen app bar. The feature integrates with existing profile management APIs and follows the app's established design patterns.

## Glossary

- **Profile_Completion_Screen**: The UI screen displayed after OTP verification where users enter their full name
- **Update_Profile_API**: The backend API endpoint (POST https://lorry.workwista.com/api/users/profile/update/) that accepts form-data with full_name field
- **View_Profile_API**: The backend API endpoint (GET https://lorry.workwista.com/api/users/view/profile/) that retrieves user profile data with Bearer Token authentication
- **Home_Screen**: The dashboard page displaying the welcome header with user's name
- **Profile_Screen**: The existing profile management screen in the app
- **OTP_Verification_Screen**: The existing screen where users verify their phone number with OTP
- **App_Bar**: The header section of the Home_Screen displaying welcome message and user name
- **Bearer_Token**: The access token stored after successful OTP verification used for API authentication
- **Full_Name**: The user's complete name stored in the profile

## Requirements

### Requirement 1: Display Profile Completion Screen After OTP Verification

**User Story:** As a user, I want to see a profile completion screen after successful OTP verification, so that I can provide my name before accessing the app.

#### Acceptance Criteria

1. WHEN OTP verification succeeds, THE Profile_Completion_Screen SHALL be displayed before navigating to the Home_Screen
2. THE Profile_Completion_Screen SHALL follow the same design style as the OTP_Verification_Screen (background color 0xFFF5F5F5, consistent typography, button styling)
3. THE Profile_Completion_Screen SHALL display a text input field for Full_Name entry
4. THE Profile_Completion_Screen SHALL display a submit button to save the Full_Name
5. THE Profile_Completion_Screen SHALL display appropriate loading indicators during API calls

### Requirement 2: Update User Profile with Full Name

**User Story:** As a user, I want my name to be saved when I submit the profile completion form, so that my profile information is stored in the system.

#### Acceptance Criteria

1. WHEN the user submits the Full_Name, THE Profile_Completion_Screen SHALL call the Update_Profile_API with form-data containing the full_name field
2. THE Update_Profile_API call SHALL include the Bearer_Token for authentication
3. WHEN the Update_Profile_API returns success response {"message": "User profile updated successfully", "data": {"full_name": "value"}}, THE Profile_Completion_Screen SHALL proceed to call the View_Profile_API
4. IF the Update_Profile_API returns an error, THEN THE Profile_Completion_Screen SHALL display an error message to the user
5. THE Profile_Completion_Screen SHALL validate that Full_Name is not empty before making the API call

### Requirement 3: Fetch Profile Data After Update

**User Story:** As a user, I want my profile data to be loaded immediately after I complete my profile, so that I don't experience loading delays when viewing the home screen.

#### Acceptance Criteria

1. WHEN the Update_Profile_API succeeds, THE Profile_Completion_Screen SHALL call the View_Profile_API to fetch the updated profile
2. THE View_Profile_API call SHALL include the Bearer_Token in the Authorization header
3. WHEN the View_Profile_API returns {"full_name": "value"}, THE Profile_Completion_Screen SHALL store the Full_Name locally for immediate access
4. WHEN both API calls succeed, THE Profile_Completion_Screen SHALL navigate to the Home_Screen
5. IF the View_Profile_API fails, THEN THE Profile_Completion_Screen SHALL still navigate to the Home_Screen (graceful degradation)

### Requirement 4: Display User Name in Home Screen App Bar

**User Story:** As a user, I want to see my name displayed in the home screen welcome message, so that I have a personalized experience.

#### Acceptance Criteria

1. THE Home_Screen App_Bar SHALL display the Full_Name retrieved from the View_Profile_API
2. WHEN Full_Name is available, THE App_Bar SHALL display "Welcome Back" followed by the Full_Name
3. WHEN Full_Name is null or empty, THE App_Bar SHALL display a default placeholder or loading state
4. THE App_Bar SHALL replace the hardcoded "Davidson Edgar" text with the dynamic Full_Name value
5. THE Full_Name display SHALL be tappable and navigate to the Profile_Screen when clicked

### Requirement 5: Preload Profile Data on App Restart

**User Story:** As a user, I want my profile information to be loaded when the app starts, so that I see my name immediately without delays.

#### Acceptance Criteria

1. WHEN the app starts and a Bearer_Token exists, THE app SHALL call the View_Profile_API during initialization
2. THE View_Profile_API call SHALL occur in main.dart or the splash screen before navigating to the Home_Screen
3. WHEN the View_Profile_API returns {"full_name": "value"}, THE app SHALL store the Full_Name for use throughout the app session
4. WHEN the View_Profile_API returns {"full_name": null}, THE app SHALL handle this gracefully without errors
5. IF the View_Profile_API call fails, THEN THE app SHALL continue to the Home_Screen without blocking navigation

### Requirement 6: Integrate Profile APIs with Existing Profile Screen

**User Story:** As a user, I want to view and update my profile information from the profile screen, so that I can manage my account details.

#### Acceptance Criteria

1. THE Profile_Screen SHALL use the View_Profile_API to fetch and display the current Full_Name
2. THE Profile_Screen SHALL use the Update_Profile_API to save changes to the Full_Name
3. THE Profile_Screen SHALL replace the hardcoded "Arun Prakash" placeholder with the dynamic Full_Name from the View_Profile_API
4. WHEN the Profile_Screen updates the Full_Name, THE updated value SHALL be reflected in the Home_Screen App_Bar without requiring app restart
5. THE Profile_Screen SHALL maintain the existing UI design while integrating the dynamic data

### Requirement 7: Handle Profile Completion State

**User Story:** As a user, I want to be directed appropriately based on whether I've completed my profile, so that I don't see the profile completion screen repeatedly.

#### Acceptance Criteria

1. WHEN OTP verification succeeds and Full_Name is null, THE app SHALL navigate to the Profile_Completion_Screen
2. WHEN OTP verification succeeds and Full_Name is not null, THE app SHALL navigate directly to the Home_Screen
3. THE app SHALL determine profile completion status by calling the View_Profile_API after OTP verification
4. WHEN the View_Profile_API returns {"full_name": null}, THE Profile_Completion_Screen SHALL be shown
5. WHEN the View_Profile_API returns {"full_name": "value"}, THE Profile_Completion_Screen SHALL be skipped

### Requirement 8: Profile API Service Implementation

**User Story:** As a developer, I want a dedicated API service for profile operations, so that profile-related API calls are centralized and reusable.

#### Acceptance Criteria

1. THE app SHALL implement a Profile_API_Service class in lib/core/services/
2. THE Profile_API_Service SHALL provide a method to call the Update_Profile_API with form-data
3. THE Profile_API_Service SHALL provide a method to call the View_Profile_API with Bearer Token authentication
4. THE Profile_API_Service SHALL handle API errors and throw appropriate exceptions
5. THE Profile_API_Service SHALL follow the same patterns as the existing AuthApiService (timeout handling, error extraction, response parsing)

### Requirement 9: Profile Data Model

**User Story:** As a developer, I want a data model for user profile information, so that profile data is type-safe and structured.

#### Acceptance Criteria

1. THE app SHALL implement a UserProfile model class in lib/core/models/
2. THE UserProfile model SHALL include a full_name field
3. THE UserProfile model SHALL provide JSON serialization methods (fromJson, toJson)
4. THE UserProfile model SHALL handle null values for full_name gracefully
5. THE UserProfile model SHALL be extensible for future profile fields (while keeping other fields as placeholders)

### Requirement 10: Profile Data Storage

**User Story:** As a developer, I want to cache profile data locally, so that the app can display user information without repeated API calls.

#### Acceptance Criteria

1. THE app SHALL implement profile data caching using SharedPreferences or similar local storage
2. THE cached profile data SHALL be updated after successful Update_Profile_API calls
3. THE cached profile data SHALL be updated after successful View_Profile_API calls
4. THE cached profile data SHALL be cleared when the user logs out
5. THE app SHALL use cached profile data as a fallback when the View_Profile_API call fails
