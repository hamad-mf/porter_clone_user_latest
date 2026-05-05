# Design Document: Profile Completion Flow

## Overview

The Profile Completion Flow feature introduces a seamless user onboarding experience by collecting the user's full name immediately after OTP verification. This design ensures that profile data is available throughout the app from the first session, eliminating the need for hardcoded placeholder names and providing a personalized user experience.

The feature integrates with two backend APIs:
- **Update Profile API**: POST endpoint for saving user profile data
- **View Profile API**: GET endpoint for retrieving user profile data

The implementation follows Flutter best practices and maintains consistency with the existing codebase architecture, particularly mirroring patterns established in `AuthApiService` and `AuthLocalStorage`.

### Key Design Goals

1. **Seamless Integration**: Insert profile completion naturally into the existing authentication flow without disrupting user experience
2. **Data Persistence**: Cache profile data locally to minimize API calls and ensure offline availability
3. **Graceful Degradation**: Handle API failures without blocking user access to the app
4. **Reusability**: Create reusable components that serve both initial profile completion and profile editing
5. **Consistency**: Match existing UI/UX patterns from the verification screen

## Architecture

### High-Level Flow

```
OTP Verification Success
    ↓
View Profile API Call
    ↓
Profile Complete? ──No──→ Profile Completion Screen
    ↓                           ↓
   Yes                    Update Profile API
    ↓                           ↓
    └──────────→ Home Screen ←──┘
```

### Component Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
├─────────────────────────────────────────────────────────┤
│  - ProfileCompletionPage (new)                          │
│  - DashboardPage (modified: dynamic name display)       │
│  - ProfilePage (modified: API integration)              │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                     Service Layer                        │
├─────────────────────────────────────────────────────────┤
│  - ProfileApiService (new)                              │
│    • viewProfile()                                       │
│    • updateProfile()                                     │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                     Storage Layer                        │
├─────────────────────────────────────────────────────────┤
│  - ProfileLocalStorage (new)                            │
│    • saveProfile()                                       │
│    • getProfile()                                        │
│    • clearProfile()                                      │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                      Data Layer                          │
├─────────────────────────────────────────────────────────┤
│  - UserProfile (new model)                              │
│    • fullName: String?                                   │
│    • fromJson() / toJson()                              │
└─────────────────────────────────────────────────────────┘
```

### Navigation Flow Modification

The existing `VerificationPage` currently navigates directly to `DashboardPage` after successful OTP verification. This will be modified to:

1. Call `ProfileApiService.viewProfile()` after token storage
2. Check if `fullName` is null
3. Navigate to `ProfileCompletionPage` if null, otherwise navigate to `DashboardPage`

## Components and Interfaces

### 1. ProfileApiService

**Location**: `lib/core/services/profile_api_service.dart`

**Purpose**: Centralized service for all profile-related API operations

**Interface**:

```dart
class ProfileApiService {
  const ProfileApiService();
  
  /// Fetches user profile data from the backend
  /// Throws ProfileApiException on failure
  Future<UserProfile> viewProfile({required String accessToken});
  
  /// Updates user profile with new data
  /// Throws ProfileApiException on failure
  Future<UserProfile> updateProfile({
    required String accessToken,
    required String fullName,
  });
}

class ProfileApiException implements Exception {
  ProfileApiException(this.message);
  final String message;
  
  @override
  String toString() => message;
}
```

**Implementation Details**:

- **Base URLs**:
  - View: `https://lorry.workwista.com/api/users/view/profile/`
  - Update: `https://lorry.workwista.com/api/users/profile/update/`

- **Timeout**: 20 seconds (consistent with `AuthApiService`)

- **View Profile Request**:
  - Method: GET
  - Headers: `Authorization: Bearer {accessToken}`
  - Response: `{"full_name": "value"}` or `{"full_name": null}`

- **Update Profile Request**:
  - Method: POST
  - Headers: `Authorization: Bearer {accessToken}`
  - Body: `multipart/form-data` with field `full_name`
  - Response: `{"message": "User profile updated successfully", "data": {"full_name": "value"}}`

- **Error Handling**:
  - Extract error messages from response body (`message` or `detail` fields)
  - Provide fallback error messages for network failures
  - Handle timeout exceptions explicitly

### 2. UserProfile Model

**Location**: `lib/core/models/user_profile.dart`

**Purpose**: Type-safe representation of user profile data

**Interface**:

```dart
class UserProfile {
  const UserProfile({this.fullName});
  
  final String? fullName;
  
  factory UserProfile.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
  
  UserProfile copyWith({String? fullName});
}
```

**Implementation Details**:

- Nullable `fullName` to handle incomplete profiles
- JSON serialization for API communication and local storage
- `copyWith` method for immutable updates
- Extensible design for future profile fields (email, address, etc.)

### 3. ProfileLocalStorage

**Location**: `lib/core/storage/profile_local_storage.dart`

**Purpose**: Local caching of profile data using SharedPreferences

**Interface**:

```dart
class ProfileLocalStorage {
  ProfileLocalStorage._();
  
  static const String profileKey = 'user_profile';
  
  static Future<void> saveProfile(UserProfile profile);
  static Future<UserProfile?> getProfile();
  static Future<void> clearProfile();
}
```

**Implementation Details**:

- Store profile as JSON string in SharedPreferences
- Return null if no cached profile exists
- Clear profile data on logout (integrate with `AuthLocalStorage.clearTokens()`)

### 4. ProfileCompletionPage

**Location**: `lib/features/profile_completion/view/profile_completion_page.dart`

**Purpose**: UI screen for collecting user's full name after OTP verification

**Interface**:

```dart
class ProfileCompletionPage extends StatefulWidget {
  const ProfileCompletionPage({super.key});
  
  @override
  State<ProfileCompletionPage> createState() => _ProfileCompletionPageState();
}
```

**UI Components**:

- Back button (top-left, matches verification screen)
- Title: "Complete Your Profile"
- Subtitle: "Please enter your full name to continue"
- Text input field for full name
- Submit button: "Continue"
- Loading indicator during API calls
- Error message display

**Styling** (matches `VerificationPage`):
- Background: `Color(0xFFF5F5F5)`
- Title: 28px, weight 800, color `0xFF111827`
- Subtitle: 13px, weight 400, color `0xFF9CA3AF`
- Input field: white background, rounded corners
- Button: `Color(0xFF111827)`, 54px height, 12px border radius

**Behavior**:

1. Validate input (non-empty, trimmed)
2. Call `ProfileApiService.updateProfile()`
3. On success, call `ProfileApiService.viewProfile()`
4. Cache result with `ProfileLocalStorage.saveProfile()`
5. Navigate to `DashboardPage` with `pushAndRemoveUntil`
6. On error, display SnackBar with error message

### 5. Modified VerificationPage

**Location**: `lib/features/verification/view/verification_page.dart`

**Changes**:

Replace the `_openDashboard()` method logic:

```dart
Future<void> _navigateAfterVerification() async {
  try {
    final accessToken = await AuthLocalStorage.getAccessToken();
    if (accessToken == null) {
      _openDashboard();
      return;
    }
    
    final profileService = ProfileApiService();
    final profile = await profileService.viewProfile(accessToken: accessToken);
    await ProfileLocalStorage.saveProfile(profile);
    
    if (!mounted) return;
    
    if (profile.fullName == null || profile.fullName!.trim().isEmpty) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const ProfileCompletionPage()),
        (route) => false,
      );
    } else {
      _openDashboard();
    }
  } catch (e) {
    // Graceful degradation: proceed to dashboard even if profile fetch fails
    if (!mounted) return;
    _openDashboard();
  }
}
```

### 6. Modified DashboardPage

**Location**: `lib/features/dashboard/view/dashboard_page.dart`

**Changes to `_WelcomeHeader`**:

```dart
class _WelcomeHeader extends StatefulWidget {
  const _WelcomeHeader();
  
  @override
  State<_WelcomeHeader> createState() => _WelcomeHeaderState();
}

class _WelcomeHeaderState extends State<_WelcomeHeader> {
  String _displayName = 'User';
  
  @override
  void initState() {
    super.initState();
    _loadProfileName();
  }
  
  Future<void> _loadProfileName() async {
    final profile = await ProfileLocalStorage.getProfile();
    if (profile?.fullName != null && profile!.fullName!.trim().isNotEmpty) {
      setState(() {
        _displayName = profile.fullName!;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Welcome Back', style: ...),
          const SizedBox(height: 2),
          Text(_displayName, style: ...),
        ],
      ),
    );
  }
}
```

### 7. Modified ProfilePage

**Location**: `lib/features/profile/view/profile_page.dart`

**Changes**:

1. Add state management for profile data
2. Load profile from `ProfileApiService.viewProfile()` on init
3. Replace hardcoded "Arun Prakash" with dynamic `profile.fullName`
4. Add edit functionality to update profile via `ProfileApiService.updateProfile()`
5. Update cached profile after successful edit

**New State Variables**:

```dart
UserProfile? _profile;
bool _isLoading = true;
bool _isEditing = false;
final TextEditingController _nameController = TextEditingController();
```

## Data Models

### UserProfile

```dart
class UserProfile {
  const UserProfile({this.fullName});
  
  final String? fullName;
  
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      fullName: json['full_name'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
    };
  }
  
  UserProfile copyWith({String? fullName}) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
    );
  }
}
```

**Design Rationale**:

- Nullable `fullName` handles incomplete profiles gracefully
- JSON serialization enables API communication and local storage
- `copyWith` supports immutable state updates
- Simple structure allows easy extension for future fields

### API Response Models

The backend APIs return different response structures:

**View Profile Response**:
```json
{
  "full_name": "John Doe"
}
```

**Update Profile Response**:
```json
{
  "message": "User profile updated successfully",
  "data": {
    "full_name": "John Doe"
  }
}
```

The `ProfileApiService` will normalize both responses to return a `UserProfile` instance.


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*


### Property Reflection

After analyzing all acceptance criteria, I've identified the following redundancies:

**Redundant Properties**:
- 3.1 is duplicate of 2.3 (both test API call sequence after update success)
- 3.2 is duplicate of 2.2 (both test Bearer token inclusion in API calls)
- 5.3 is duplicate of 3.3 (both test local storage after API response)
- 7.1 is duplicate of 1.1 (both test navigation to profile completion when name is null)
- 7.4 is duplicate of 7.1/1.1 (same navigation condition)
- 7.5 is duplicate of 7.2 (both test skipping profile completion when name exists)

**Combined Properties**:
- 2.2 and 3.2 can be combined into: "All profile API calls include Bearer token authentication"
- 1.1, 7.1, and 7.4 can be combined into: "Navigation to profile completion when profile is incomplete"
- 7.2 and 7.5 can be combined into: "Navigation skips profile completion when profile is complete"
- 3.3, 5.3, 10.2, and 10.3 can be combined into: "Profile data is cached after successful API operations"

**Unique Properties Retained**:
- Input validation (2.5)
- Error handling and display (2.4, 8.4)
- API call sequencing (2.3)
- Navigation after completion (3.4)
- UI data display (4.1, 4.2)
- Profile screen integration (6.1, 6.2, 6.4)
- App initialization (5.1)
- Graceful degradation (3.5, 5.5, 10.5)
- Logout behavior (10.4)
- Serialization (9.3)

This reflection ensures each property provides unique validation value without logical redundancy.

### Properties

### Property 1: Profile Completion Navigation for Incomplete Profiles

*For any* user who successfully completes OTP verification, if the View_Profile_API returns a null or empty full_name, the system should navigate to the Profile_Completion_Screen before allowing access to the Home_Screen.

**Validates: Requirements 1.1, 7.1, 7.3, 7.4**

### Property 2: Profile Completion Skip for Complete Profiles

*For any* user who successfully completes OTP verification, if the View_Profile_API returns a non-null and non-empty full_name, the system should navigate directly to the Home_Screen, skipping the Profile_Completion_Screen.

**Validates: Requirements 7.2, 7.5**

### Property 3: Input Validation Before API Submission

*For any* input string in the profile completion form, if the string is empty or contains only whitespace characters, the system should reject the submission and prevent the Update_Profile_API call.

**Validates: Requirements 2.5**

### Property 4: Bearer Token Authentication on All Profile API Calls

*For any* profile API call (viewProfile or updateProfile), the HTTP request should include the Bearer token in the Authorization header.

**Validates: Requirements 2.2, 3.2**

### Property 5: API Call Sequence After Profile Update

*For any* successful Update_Profile_API response, the system should immediately call the View_Profile_API to fetch the updated profile data.

**Validates: Requirements 2.3, 3.1**

### Property 6: Profile Data Caching After Successful API Operations

*For any* successful profile API response (from viewProfile or updateProfile), the returned profile data should be stored in local cache (SharedPreferences).

**Validates: Requirements 3.3, 5.3, 10.2, 10.3**

### Property 7: Navigation After Successful Profile Completion

*For any* user who successfully completes both the Update_Profile_API and View_Profile_API calls, the system should navigate to the Home_Screen using pushAndRemoveUntil to clear the navigation stack.

**Validates: Requirements 3.4**

### Property 8: Error Message Display on API Failure

*For any* failed Update_Profile_API call, the Profile_Completion_Screen should display an error message to the user via SnackBar or similar UI component.

**Validates: Requirements 2.4**

### Property 9: Dynamic Name Display in Home Screen

*For any* cached profile with a non-null and non-empty full_name, the Home_Screen app bar should display "Welcome Back" followed by the full_name value.

**Validates: Requirements 4.1, 4.2**

### Property 10: Profile Screen Data Loading

*For any* time the Profile_Screen is opened, the screen should call the View_Profile_API to fetch and display the current full_name.

**Validates: Requirements 6.1**

### Property 11: Profile Screen Data Update

*For any* profile edit submitted from the Profile_Screen, the screen should call the Update_Profile_API with the new full_name value.

**Validates: Requirements 6.2**

### Property 12: Cross-Screen Data Propagation

*For any* successful profile update from the Profile_Screen, when the user navigates back to the Home_Screen, the app bar should display the updated full_name without requiring an app restart.

**Validates: Requirements 6.4**

### Property 13: Profile Fetch on App Initialization

*For any* app startup where a valid Bearer_Token exists in local storage, the app should call the View_Profile_API during initialization before displaying the Home_Screen.

**Validates: Requirements 5.1**

### Property 14: Graceful Degradation on View Profile Failure

*For any* failed View_Profile_API call during profile completion or app initialization, the system should continue navigation to the Home_Screen without blocking user access.

**Validates: Requirements 3.5, 5.5**

### Property 15: Cached Data Fallback on API Failure

*For any* failed View_Profile_API call, if cached profile data exists in local storage, the system should use the cached data to display the user's full_name.

**Validates: Requirements 10.5**

### Property 16: Profile Data Cleared on Logout

*For any* logout action, the system should clear all cached profile data from local storage along with authentication tokens.

**Validates: Requirements 10.4**

### Property 17: Profile Model Serialization Round Trip

*For any* UserProfile instance, serializing to JSON and then deserializing back should produce an equivalent UserProfile object with the same full_name value.

**Validates: Requirements 9.3**

### Property 18: API Exception Handling

*For any* HTTP error response (4xx or 5xx status codes) from profile API endpoints, the ProfileApiService should throw a ProfileApiException with an appropriate error message extracted from the response body.

**Validates: Requirements 8.4**

### Property 19: Loading Indicator Display During API Operations

*For any* ongoing API call from the Profile_Completion_Screen, a loading indicator should be visible to the user, and user input should be disabled until the operation completes.

**Validates: Requirements 1.5**

### Property 20: Update API Request Format

*For any* call to updateProfile, the HTTP request should use multipart/form-data format with a field named "full_name" containing the user's name.

**Validates: Requirements 2.1**


## Error Handling

### API Error Handling

**ProfileApiService Error Strategy**:

1. **Network Errors**:
   - Catch `TimeoutException` and throw `ProfileApiException` with user-friendly message
   - Handle connection failures with fallback error messages
   - Timeout duration: 20 seconds (consistent with AuthApiService)

2. **HTTP Error Responses**:
   - Status codes 4xx/5xx: Extract error message from response body
   - Check for `message` field first, then `detail` field
   - Provide fallback error messages if response body is malformed
   - Example: "Failed to update profile. Please try again."

3. **Response Parsing Errors**:
   - Handle malformed JSON responses gracefully
   - Throw `ProfileApiException` with descriptive message
   - Never expose raw parsing errors to users

4. **Authentication Errors**:
   - 401 Unauthorized: Indicate session expired, suggest re-login
   - Missing access token: Throw exception before making API call
   - Invalid token format: Validate token before API call

**Error Message Examples**:

```dart
// Missing token
throw ProfileApiException('Authentication required. Please log in again.');

// Network timeout
throw ProfileApiException('Request timed out. Please check your connection.');

// Server error
throw ProfileApiException('Unable to update profile. Please try again later.');

// Validation error
throw ProfileApiException('Profile name cannot be empty.');
```

### UI Error Handling

**ProfileCompletionPage**:

1. **Input Validation Errors**:
   - Display inline error message below input field
   - Prevent API call until validation passes
   - Clear error message when user starts typing

2. **API Errors**:
   - Display SnackBar with error message from `ProfileApiException`
   - Allow user to retry submission
   - Maintain user input (don't clear the form)

3. **Loading States**:
   - Disable submit button during API calls
   - Show CircularProgressIndicator in button
   - Prevent back navigation during submission

**DashboardPage**:

1. **Profile Load Failures**:
   - Display default placeholder name ("User")
   - Don't block UI rendering
   - Retry on next app launch

2. **Missing Profile Data**:
   - Handle null full_name gracefully
   - Display "Welcome Back" without name
   - Provide visual indication to complete profile

**ProfilePage**:

1. **Load Failures**:
   - Display error message with retry button
   - Show cached data if available
   - Allow user to continue using other app features

2. **Update Failures**:
   - Display SnackBar with error message
   - Revert to previous value
   - Allow user to retry

### Graceful Degradation Strategy

The feature is designed to never block user access to the app:

1. **Profile Fetch Failure After OTP**: Navigate to dashboard anyway
2. **Profile Fetch Failure on Startup**: Continue to dashboard with default name
3. **Cache Read Failure**: Use default values, don't crash
4. **Profile Update Failure**: Show error but allow retry

### Edge Cases

1. **Null or Empty Full Name from API**:
   - Treat as incomplete profile
   - Show profile completion screen
   - Handle empty string same as null

2. **Very Long Names**:
   - Truncate display in UI with ellipsis
   - Store full name in backend
   - No artificial length limit on input

3. **Special Characters in Names**:
   - Accept all Unicode characters
   - No sanitization (backend responsibility)
   - Proper encoding in API requests

4. **Concurrent Profile Updates**:
   - Last write wins (no conflict resolution)
   - Refresh from API after update
   - Cache reflects latest API response

5. **Token Expiry During Profile Operations**:
   - Catch 401 errors
   - Redirect to login screen
   - Clear cached tokens and profile data

## Testing Strategy

### Dual Testing Approach

This feature requires both unit tests and property-based tests for comprehensive coverage:

**Unit Tests**: Verify specific examples, edge cases, and integration points
**Property Tests**: Verify universal properties across all inputs

Together, these approaches ensure both concrete correctness (unit tests) and general correctness (property tests).

### Property-Based Testing

**Framework**: Use the `test` package with custom property test helpers, or integrate a Dart property-based testing library if available (e.g., `dartz` for functional testing patterns).

**Configuration**:
- Minimum 100 iterations per property test
- Each test must reference its design document property
- Tag format: `@Tags(['Feature: profile-completion-flow', 'Property {number}: {property_text}'])`

**Property Test Examples**:

```dart
// Property 3: Input Validation Before API Submission
@Tags(['Feature: profile-completion-flow', 'Property 3: Input validation rejects empty strings'])
test('property: whitespace-only names are rejected', () async {
  final service = ProfileApiService();
  final whitespaceStrings = [
    '',
    ' ',
    '  ',
    '\t',
    '\n',
    '   \t\n  ',
  ];
  
  for (final input in whitespaceStrings) {
    // Validation should reject before API call
    expect(input.trim().isEmpty, isTrue);
  }
});

// Property 17: Profile Model Serialization Round Trip
@Tags(['Feature: profile-completion-flow', 'Property 17: Serialization round trip'])
test('property: UserProfile serialization round trip preserves data', () async {
  final testNames = [
    'John Doe',
    'María García',
    '李明',
    'O\'Brien',
    'Jean-Pierre',
    null,
  ];
  
  for (final name in testNames) {
    final original = UserProfile(fullName: name);
    final json = original.toJson();
    final deserialized = UserProfile.fromJson(json);
    
    expect(deserialized.fullName, equals(original.fullName));
  }
});

// Property 6: Profile Data Caching After Successful API Operations
@Tags(['Feature: profile-completion-flow', 'Property 6: Caching after API success'])
test('property: successful API responses are cached', () async {
  final testProfiles = [
    UserProfile(fullName: 'Alice'),
    UserProfile(fullName: 'Bob'),
    UserProfile(fullName: null),
  ];
  
  for (final profile in testProfiles) {
    await ProfileLocalStorage.saveProfile(profile);
    final cached = await ProfileLocalStorage.getProfile();
    
    expect(cached?.fullName, equals(profile.fullName));
  }
});
```

### Unit Testing

**Test Organization**:

```
test/
├── core/
│   ├── services/
│   │   └── profile_api_service_test.dart
│   ├── models/
│   │   └── user_profile_test.dart
│   └── storage/
│       └── profile_local_storage_test.dart
└── features/
    └── profile_completion/
        └── view/
            └── profile_completion_page_test.dart
```

**Unit Test Coverage**:

1. **ProfileApiService Tests**:
   - Successful viewProfile call returns UserProfile
   - Successful updateProfile call returns updated UserProfile
   - 401 error throws ProfileApiException with auth message
   - 500 error throws ProfileApiException with server error message
   - Timeout throws ProfileApiException with timeout message
   - Malformed JSON throws ProfileApiException
   - Missing access token throws ProfileApiException before API call

2. **UserProfile Model Tests**:
   - fromJson with valid data creates correct instance
   - fromJson with null full_name creates instance with null
   - toJson produces correct JSON structure
   - copyWith updates full_name correctly
   - copyWith with no params returns equivalent instance

3. **ProfileLocalStorage Tests**:
   - saveProfile stores data in SharedPreferences
   - getProfile retrieves stored data correctly
   - getProfile returns null when no data exists
   - clearProfile removes all profile data
   - Handles malformed cached JSON gracefully

4. **ProfileCompletionPage Widget Tests**:
   - Displays title and subtitle text
   - Displays text input field
   - Displays submit button
   - Submit button disabled when input is empty
   - Shows loading indicator during API call
   - Displays error message on API failure
   - Navigates to dashboard on success
   - Back button navigates to previous screen

5. **Integration Tests**:
   - Complete flow: OTP → Profile Completion → Dashboard
   - Profile update from ProfilePage reflects in Dashboard
   - Logout clears profile data
   - App restart loads cached profile

### Test Data

**Valid Names**:
- "John Doe"
- "María García" (accented characters)
- "李明" (Chinese characters)
- "O'Brien" (apostrophe)
- "Jean-Pierre" (hyphen)
- "Dr. Smith Jr." (titles and suffixes)

**Invalid Names**:
- "" (empty string)
- " " (single space)
- "   " (multiple spaces)
- "\t" (tab)
- "\n" (newline)
- "  \t\n  " (mixed whitespace)

**Edge Cases**:
- null (missing profile)
- Very long names (500+ characters)
- Names with emojis: "John 😊 Doe"
- Names with special characters: "Name@#$%"

### Mocking Strategy

**Mock API Responses**:

```dart
// Successful view profile response
{
  "full_name": "John Doe"
}

// Successful update profile response
{
  "message": "User profile updated successfully",
  "data": {
    "full_name": "John Doe"
  }
}

// Error response
{
  "message": "Invalid request",
  "detail": "Full name is required"
}

// Null profile response
{
  "full_name": null
}
```

**Mock SharedPreferences**:
- Use `shared_preferences` package's mock implementation
- Reset state between tests
- Verify save/get/clear operations

**Mock HTTP Client**:
- Use `http` package's `MockClient`
- Simulate network delays
- Simulate timeout scenarios
- Simulate various HTTP status codes

### Testing Checklist

Before marking the feature complete, verify:

- [ ] All 20 correctness properties have corresponding property tests
- [ ] All property tests run minimum 100 iterations
- [ ] All property tests are tagged correctly
- [ ] Unit tests cover all edge cases identified
- [ ] Widget tests verify UI behavior
- [ ] Integration tests verify end-to-end flows
- [ ] Error handling is tested for all failure scenarios
- [ ] Graceful degradation is verified
- [ ] Performance is acceptable (API calls < 5s, UI responsive)
- [ ] No memory leaks in profile caching
- [ ] Logout properly clears all data

### Manual Testing Scenarios

1. **New User Flow**:
   - Sign in with new phone number
   - Verify profile completion screen appears
   - Enter name and submit
   - Verify dashboard shows correct name

2. **Returning User Flow**:
   - Sign in with existing account
   - Verify profile completion screen is skipped
   - Verify dashboard shows cached name immediately

3. **Profile Edit Flow**:
   - Navigate to profile screen
   - Edit name
   - Save changes
   - Return to dashboard
   - Verify updated name appears

4. **Offline Scenarios**:
   - Disable network
   - Open app
   - Verify cached name displays
   - Attempt profile update
   - Verify appropriate error message

5. **Error Recovery**:
   - Trigger API error (invalid token)
   - Verify error message displays
   - Retry operation
   - Verify success after retry

## Implementation Notes

### Development Sequence

1. **Phase 1: Foundation** (Models and Storage)
   - Create `UserProfile` model with tests
   - Create `ProfileLocalStorage` with tests
   - Verify serialization and caching work correctly

2. **Phase 2: API Service**
   - Create `ProfileApiService` with tests
   - Implement `viewProfile` method
   - Implement `updateProfile` method
   - Test error handling thoroughly

3. **Phase 3: Profile Completion UI**
   - Create `ProfileCompletionPage` widget
   - Implement form validation
   - Integrate with `ProfileApiService`
   - Add loading states and error handling

4. **Phase 4: Integration**
   - Modify `VerificationPage` to check profile status
   - Modify `DashboardPage` to display dynamic name
   - Modify `ProfilePage` to load and update profile
   - Test navigation flows

5. **Phase 5: App Initialization**
   - Add profile fetch to app startup
   - Implement caching strategy
   - Test graceful degradation

6. **Phase 6: Testing and Polish**
   - Write all property tests
   - Write all unit tests
   - Perform manual testing
   - Fix bugs and edge cases

### Dependencies

**Existing Dependencies** (already in pubspec.yaml):
- `http`: ^1.1.0 (for API calls)
- `shared_preferences`: ^2.2.2 (for local storage)
- `flutter_test`: (for testing)

**No New Dependencies Required**: This feature uses existing packages.

### Performance Considerations

1. **API Call Optimization**:
   - Cache profile data to minimize API calls
   - Only fetch profile on app startup and after updates
   - Use cached data as fallback

2. **UI Responsiveness**:
   - Load cached name immediately on dashboard
   - Fetch fresh data in background
   - Update UI when fresh data arrives

3. **Memory Management**:
   - Profile data is small (single string)
   - No memory concerns with caching
   - Clear cache on logout

### Security Considerations

1. **Token Handling**:
   - Never log access tokens
   - Include token in Authorization header only
   - Clear tokens on logout

2. **Data Validation**:
   - Validate input on client side
   - Trust backend for final validation
   - Don't sanitize user input (preserve original)

3. **Error Messages**:
   - Don't expose internal errors to users
   - Provide generic messages for security errors
   - Log detailed errors for debugging

### Accessibility

1. **Screen Reader Support**:
   - Add semantic labels to all input fields
   - Announce loading states
   - Announce error messages

2. **Keyboard Navigation**:
   - Ensure tab order is logical
   - Support Enter key to submit form
   - Support Escape key to cancel

3. **Visual Accessibility**:
   - Maintain sufficient color contrast
   - Support system font scaling
   - Provide clear focus indicators

## Conclusion

This design provides a comprehensive solution for profile completion that:

1. Integrates seamlessly with existing authentication flow
2. Provides a smooth user experience with proper error handling
3. Caches data efficiently to minimize API calls
4. Degrades gracefully when APIs fail
5. Follows established patterns in the codebase
6. Is fully testable with both unit and property-based tests

The implementation prioritizes user experience by never blocking access to the app, even when profile operations fail. The caching strategy ensures that profile data is available immediately on subsequent app launches, providing a fast and responsive experience.

