# Design Document: Trip Request Sharing

## Overview

This design implements deep linking and trip request sharing functionality for the lorry app, enabling users to share trip requests via HTTPS links that open directly in the app. The feature adapts the Workwista job sharing pattern to the lorry app's trip request model.

The implementation consists of three main components:
1. **Share Service**: Generates shareable HTTPS links with trip summaries
2. **Deep Link Handler**: Processes incoming deep links and extracts trip IDs
3. **Navigation Integration**: Routes users to trip details based on authentication state

The design follows Flutter best practices with widget-based deep link handling, leveraging the `app_links` package for Android App Links and custom scheme support.

## Architecture

### Component Structure

```
lib/
├── core/
│   ├── services/
│   │   ├── trip_sharing_service.dart      # Generates shareable links
│   │   └── trip_details_api_service.dart  # Fetches trip details by ID
│   └── handlers/
│       └── deep_link_handler.dart         # Processes incoming deep links
├── features/
│   ├── dashboard/
│   │   └── view/
│   │       └── dashboard_page.dart        # Updated with share button
│   ├── trip_details/
│   │   └── view/
│   │       └── trip_details_page.dart     # New screen for trip details
│   └── splash/
│       └── view/
│           └── splash_screen.dart         # Updated for deep link routing
└── main.dart                              # Wrapped with DeepLinkHandler
```

### Data Flow

1. **Sharing Flow**:
   - User taps share button on trip card
   - TripSharingService generates HTTPS link
   - System share dialog opens with link and summary

2. **Deep Link Reception (App Launch)**:
   - Android receives HTTPS link
   - DeepLinkHandler extracts trip ID
   - SplashScreen receives trip ID
   - Routes to TripDetailsPage (authenticated) or SignInPage (unauthenticated)

3. **Deep Link Reception (App Running)**:
   - DeepLinkHandler stream receives link
   - Extracts trip ID
   - Pushes TripDetailsPage onto navigation stack

## Components and Interfaces

### 1. TripSharingService

**Purpose**: Generate shareable links for trip requests

**Interface**:
```dart
class TripSharingService {
  static void shareTrip({
    required String tripId,
    required String pickupLocation,
    required String dropLocation,
    required String vehicleSize,
  });
}
```

**Behavior**:
- Constructs HTTPS URL: `https://lorry.workwista.com/share/trip/{tripId}`
- Formats share text with trip summary
- Invokes `Share.share()` from `share_plus` package

### 2. DeepLinkHandler Widget

**Purpose**: Listen for and process incoming deep links throughout app lifecycle

**Interface**:
```dart
class DeepLinkHandler extends StatefulWidget {
  final Widget child;
  const DeepLinkHandler({required this.child});
}
```

**Behavior**:
- Initializes `AppLinks` instance
- Checks for initial deep link on app launch
- Sets up stream listener for runtime deep links
- Extracts trip ID from URLs
- Routes to appropriate screen based on app state

**URL Parsing**:
- HTTPS: `https://lorry.workwista.com/share/trip/{tripId}`
- Custom scheme: `lorry://trip/{tripId}`

### 3. TripDetailsPage

**Purpose**: Display full trip request information

**Interface**:
```dart
class TripDetailsPage extends StatefulWidget {
  final String tripId;
  final bool isFromDeepLink;
  
  const TripDetailsPage({
    required this.tripId,
    this.isFromDeepLink = false,
  });
}
```

**Behavior**:
- Fetches trip data using TripDetailsApiService
- Displays all trip information (pickup, drop, load details, vehicle requirements, amount, time)
- Shows loading state during fetch
- Shows error state if trip not found
- Displays accept button (requires authentication)

### 4. TripDetailsApiService

**Purpose**: Fetch trip details by ID

**Interface**:
```dart
class TripDetailsApiService {
  Future<Trip> getTripById({
    required String tripId,
    String? accessToken,
  });
}
```

**API Endpoint**: `GET https://lorry.workwista.com/api/trips/{tripId}/`

**Response Handling**:
- 200: Parse and return Trip model
- 404: Throw TripNotFoundException
- Other errors: Throw TripDetailsApiException

### 5. Updated SplashScreen

**Purpose**: Handle initial routing with deep link support

**Interface**:
```dart
class SplashScreen extends StatefulWidget {
  final String? deepLinkTripId;
  
  const SplashScreen({this.deepLinkTripId});
}
```

**Routing Logic**:
- If `deepLinkTripId` is provided:
  - Authenticated: Navigate to TripDetailsPage
  - Unauthenticated: Navigate to SignInPage (preserve trip ID)
- If no deep link:
  - Standard authentication-based routing

### 6. Updated Dashboard Card

**Purpose**: Add share button to trip request cards

**Changes to `_AcceptedDriverCard`**:
- Add share icon button in card header
- Wire to TripSharingService.shareTrip()
- Pass trip details from acceptance data

## Data Models

### Trip Model (Existing)

The existing `Trip` model already contains all necessary fields:
```dart
class Trip {
  final String id;
  final String pickupLocation;
  final String dropLocation;
  final String loadSize;
  final String loadType;
  final String vehicleSize;
  final String bodyType;
  final String tripStatus;
  final String amount;
  final DateTime pickupTime;
  final String name;
  final String contactNumber;
  final List<dynamic> acceptedDrivers;
}
```

No modifications needed to the Trip model.

### AcceptedDriver Model (Existing)

Used in dashboard cards, contains acceptance data with trip information:
```dart
class AcceptedDriver {
  final String fullName;
  final String phoneNumber;
  final List<TripAcceptance> acceptances;
}

class TripAcceptance {
  final String tripId;
  final String acceptanceId;
  final String pickupLocation;
  final String dropLocation;
  // ... other fields
}
```

The `TripAcceptance` model provides the trip ID and location data needed for sharing.

## Android Configuration

### AndroidManifest.xml

Add intent filter to `<activity>` tag:

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="https"
        android:host="lorry.workwista.com"
        android:pathPrefix="/share/trip" />
</intent-filter>

<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="lorry"
        android:host="trip" />
</intent-filter>
```

### Digital Asset Links

For verified App Links, host `.well-known/assetlinks.json` at:
`https://lorry.workwista.com/.well-known/assetlinks.json`

Content:
```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.workwista.lorry",
    "sha256_cert_fingerprints": ["<SHA256_FINGERPRINT>"]
  }
}]
```

## Dependencies

Add to `pubspec.yaml`:
```yaml
dependencies:
  share_plus: ^7.2.1
  app_links: ^3.5.0
```


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Share URL Format

*For any* trip ID, the generated share URL SHALL match the pattern `https://lorry.workwista.com/share/trip/{tripId}` and contain the exact trip ID provided.

**Validates: Requirements 1.1**

### Property 2: Share Text Completeness

*For any* trip request with pickup location, drop location, and vehicle size, the generated share text SHALL contain all three pieces of information.

**Validates: Requirements 1.2**

### Property 3: URL Parsing Round-Trip

*For any* valid trip ID, constructing a share URL and then parsing it SHALL produce the original trip ID (for both HTTPS and custom scheme formats).

**Validates: Requirements 3.1, 3.2, 3.3, 9.1, 9.2, 9.3, 9.4**

### Property 4: Invalid URL Handling

*For any* URL that does not match the expected patterns (`https://lorry.workwista.com/share/trip/{tripId}` or `lorry://trip/{tripId}`), the parser SHALL return null without throwing an exception.

**Validates: Requirements 3.4, 9.5**

## Error Handling

### Share Service Errors

**Scenario**: Share dialog fails to open
- **Handling**: Log error, show user-friendly snackbar message
- **Recovery**: User can retry share action

**Scenario**: Missing trip information
- **Handling**: Validate required fields before generating share text
- **Recovery**: Disable share button if data incomplete

### Deep Link Handler Errors

**Scenario**: Malformed URL received
- **Handling**: Log error with URL details, return null trip ID
- **Recovery**: App continues normal operation, no navigation occurs

**Scenario**: AppLinks initialization fails
- **Handling**: Log error, continue app initialization
- **Recovery**: App functions normally, deep links won't work until restart

**Scenario**: Navigation context unavailable
- **Handling**: Log error, queue navigation for next frame
- **Recovery**: Retry navigation when context available

### Trip Details API Errors

**Scenario**: Trip not found (404)
- **Handling**: Show "Trip not found" error message
- **Recovery**: Provide button to return to home screen

**Scenario**: Network error
- **Handling**: Show "Connection error" message with retry button
- **Recovery**: User can retry fetch or return to home

**Scenario**: Unauthorized (401)
- **Handling**: For accept action only, redirect to login
- **Recovery**: Preserve trip ID for post-login return

**Scenario**: Server error (500)
- **Handling**: Show "Server error" message
- **Recovery**: Provide retry button and home navigation

### Authentication Flow Errors

**Scenario**: Login fails during deep link flow
- **Handling**: Show login error, preserve trip ID
- **Recovery**: User can retry login, trip ID remains available

**Scenario**: Token expired during trip acceptance
- **Handling**: Redirect to login, preserve trip ID and accept intent
- **Recovery**: After login, return to trip details and retry accept

## Testing Strategy

### Unit Testing

Unit tests will focus on specific examples, edge cases, and error conditions:

**TripSharingService**:
- Test URL generation with various trip IDs (including special characters)
- Test share text formatting with different location lengths
- Test handling of null/empty fields

**DeepLinkHandler URL Parsing**:
- Test HTTPS URL parsing with valid trip IDs
- Test custom scheme URL parsing
- Test invalid URL formats (missing segments, wrong host, etc.)
- Test URLs with query parameters
- Test URLs with fragments

**TripDetailsApiService**:
- Test successful API response parsing
- Test 404 error handling
- Test network error handling
- Test malformed response handling

**SplashScreen Routing**:
- Test routing with deep link + authenticated user
- Test routing with deep link + unauthenticated user
- Test routing without deep link

### Property-Based Testing

Property tests will verify universal properties across all inputs using the `flutter_test` framework with custom generators. Each test will run a minimum of 100 iterations.

**Test Library**: Use `flutter_test` with custom property-based test helpers (or `test` package with custom generators)

**Property Test 1: Share URL Format**
- **Generator**: Random alphanumeric trip IDs (length 8-32)
- **Property**: Generated URL matches pattern and contains trip ID
- **Tag**: `Feature: trip-request-sharing, Property 1: Share URL format`

**Property Test 2: Share Text Completeness**
- **Generator**: Random trip data (locations, vehicle types)
- **Property**: Share text contains all required fields
- **Tag**: `Feature: trip-request-sharing, Property 2: Share text completeness`

**Property Test 3: URL Parsing Round-Trip**
- **Generator**: Random trip IDs
- **Property**: `parse(generateUrl(tripId)) == tripId` for both URL formats
- **Tag**: `Feature: trip-request-sharing, Property 3: URL parsing round-trip`

**Property Test 4: Invalid URL Handling**
- **Generator**: Random invalid URLs (wrong host, missing segments, malformed)
- **Property**: Parser returns null without exception
- **Tag**: `Feature: trip-request-sharing, Property 4: Invalid URL handling`

### Integration Testing

Integration tests will verify component interactions:

**Deep Link to Trip Details Flow**:
- Test app launch with deep link → trip details screen
- Test runtime deep link → trip details screen
- Test deep link with authentication flow

**Share to Deep Link Flow**:
- Test share button → share dialog → deep link reception
- Verify shared link opens correct trip details

**Widget Testing**:
- Test share button appears on trip cards
- Test share button triggers share service
- Test trip details screen displays all information
- Test error states render correctly

### Manual Testing Checklist

- Verify Android App Links work without disambiguation dialog
- Test custom scheme fallback on devices without verified links
- Test share to various apps (WhatsApp, SMS, Email)
- Test deep links from various sources (browser, messaging apps)
- Verify authentication flow preserves trip ID correctly
- Test offline behavior for deep links
