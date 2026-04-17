# Design Document: Accepted Drivers Display

## Overview

This feature integrates accepted driver information into the home screen of the porter_clone_user Flutter application. The system fetches data from the backend API endpoint `https://lorry.workwista.com/api/users/trips/all/accepted-drivers/` and displays it in a card-based UI on the dashboard home tab.

The implementation follows the existing architectural patterns in the codebase:
- API services for network communication (similar to `TripApiService` and `AuthApiService`)
- Direct state management within StatefulWidget components
- Shared preferences for authentication token storage
- Material Design UI components with custom styling

The feature replaces or augments the current "Current Requests" section with real data from the backend, providing users with visibility into which drivers have accepted their trip requests.

## Architecture

### Layer Structure

The implementation follows a three-layer architecture consistent with the existing codebase:

**1. Service Layer** (`lib/core/services/`)
- `AcceptedDriversApiService`: Handles HTTP communication with the backend API
- Manages request construction, authentication headers, and response parsing
- Throws typed exceptions for error handling

**2. Model Layer** (`lib/core/models/`)
- `AcceptedDriver`: Represents a driver who has accepted trips
- `TripAcceptance`: Represents a single trip acceptance by a driver
- Provides JSON deserialization and data validation

**3. UI Layer** (`lib/features/dashboard/view/`)
- `_DashboardHomeTab`: Modified to fetch and display accepted drivers
- `_AcceptedDriverCard`: New widget for displaying driver information
- Manages loading, error, and empty states

### Data Flow

```
User Opens Dashboard
    ↓
_DashboardHomeTab.initState()
    ↓
_fetchAcceptedDrivers()
    ↓
AcceptedDriversApiService.getAcceptedDrivers()
    ↓
[Retrieve access token from AuthLocalStorage]
    ↓
[HTTP GET with Bearer token]
    ↓
[Parse JSON response into List<AcceptedDriver>]
    ↓
setState() with drivers list
    ↓
Build driver cards in UI
```

### Error Handling Flow

```
API Call Fails
    ↓
AcceptedDriversApiException thrown
    ↓
Caught in _fetchAcceptedDrivers()
    ↓
setState() with error state
    ↓
Display error message + retry button
```

## Components and Interfaces

### AcceptedDriversApiService

**Purpose**: Manages HTTP communication with the accepted drivers API endpoint.

**Interface**:
```dart
class AcceptedDriversApiService {
  const AcceptedDriversApiService();
  
  Future<List<AcceptedDriver>> getAcceptedDrivers({
    required String? accessToken,
  });
}

class AcceptedDriversApiException implements Exception {
  AcceptedDriversApiException(this.message);
  final String message;
}
```

**Responsibilities**:
- Construct HTTP GET request to the API endpoint
- Add Authorization header with Bearer token
- Handle HTTP response status codes (200, 401, 500, etc.)
- Parse JSON response body
- Convert JSON to `List<AcceptedDriver>` models
- Throw `AcceptedDriversApiException` on failures

**Configuration**:
- Endpoint: `https://lorry.workwista.com/api/users/trips/all/accepted-drivers/`
- Timeout: 20 seconds (consistent with other API services)
- Headers: `Accept: application/json`, `Authorization: Bearer {token}`

### AcceptedDriver Model

**Purpose**: Represents a driver and their trip acceptances.

**Interface**:
```dart
class AcceptedDriver {
  const AcceptedDriver({
    required this.driverId,
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.isVerified,
    required this.acceptances,
  });
  
  final int driverId;
  final int userId;
  final String fullName;
  final String phoneNumber;
  final bool isVerified;
  final List<TripAcceptance> acceptances;
  
  factory AcceptedDriver.fromJson(Map<String, dynamic> json);
}
```

**JSON Mapping**:
- `driver_id` → `driverId`
- `user_id` → `userId`
- `full_name` → `fullName`
- `phone_number` → `phoneNumber`
- `is_verified` → `isVerified`
- `acceptances` → `acceptances` (list of TripAcceptance)

**Validation**:
- All fields are required
- Missing fields throw `FormatException`
- `acceptances` defaults to empty list if missing

### TripAcceptance Model

**Purpose**: Represents a single trip acceptance by a driver.

**Interface**:
```dart
class TripAcceptance {
  const TripAcceptance({
    required this.acceptanceId,
    required this.tripId,
    required this.tripStatus,
    required this.pickupLocation,
    required this.dropLocation,
    required this.acceptedAt,
  });
  
  final int acceptanceId;
  final int tripId;
  final String tripStatus;
  final String pickupLocation;
  final String dropLocation;
  final DateTime acceptedAt;
  
  factory TripAcceptance.fromJson(Map<String, dynamic> json);
}
```

**JSON Mapping**:
- `acceptance_id` → `acceptanceId`
- `trip_id` → `tripId`
- `trip_status` → `tripStatus`
- `pickup_location` → `pickupLocation`
- `drop_location` → `dropLocation`
- `accepted_at` → `acceptedAt` (parsed as ISO 8601 DateTime)

### _DashboardHomeTab (Modified)

**Purpose**: Displays the home screen with accepted drivers section.

**State Management**:
```dart
class _DashboardHomeTabState extends State<_DashboardHomeTab> {
  bool _isLoading = true;
  String? _errorMessage;
  List<AcceptedDriver> _drivers = [];
  
  @override
  void initState() {
    super.initState();
    _fetchAcceptedDrivers();
  }
  
  Future<void> _fetchAcceptedDrivers();
  Future<void> _refreshDrivers();
}
```

**UI States**:
- **Loading**: Shows `CircularProgressIndicator` while fetching data
- **Loaded**: Displays list of `_AcceptedDriverCard` widgets
- **Empty**: Shows message "No accepted drivers yet" with icon
- **Error**: Shows error message with retry button

### _AcceptedDriverCard Widget

**Purpose**: Displays information about a single driver and their trip acceptances.

**Interface**:
```dart
class _AcceptedDriverCard extends StatelessWidget {
  const _AcceptedDriverCard({required this.driver});
  final AcceptedDriver driver;
  
  @override
  Widget build(BuildContext context);
}
```

**Layout**:
- Driver name (bold, 22px)
- Phone number (gray, 13px)
- Verification badge (if `isVerified` is true)
- For each trip acceptance:
  - Pickup → Drop location with arrow
  - Trip status badge
  - Accepted timestamp (formatted as "2 hours ago", "Yesterday", etc.)
- Dividers between multiple trip acceptances

**Styling**:
- Background: White
- Border radius: 14px
- Padding: 16px
- Matches existing card design in dashboard

## Data Models

### API Response Structure

The API returns JSON in the following format:

```json
{
  "accepted_drivers": [
    {
      "driver_id": 123,
      "user_id": 456,
      "full_name": "Ramkumar",
      "phone_number": "+91 98765 43210",
      "is_verified": true,
      "acceptances": [
        {
          "acceptance_id": 789,
          "trip_id": 101,
          "trip_status": "accepted",
          "pickup_location": "Kochi",
          "drop_location": "Bangalore",
          "accepted_at": "2024-01-15T10:30:00Z"
        }
      ]
    }
  ]
}
```

### Model Relationships

```
AcceptedDriver (1) ──── (N) TripAcceptance
```

Each `AcceptedDriver` can have multiple `TripAcceptance` records. The relationship is one-to-many.

### Data Validation Rules

**AcceptedDriver**:
- `driverId`: Must be positive integer
- `userId`: Must be positive integer
- `fullName`: Must be non-empty string
- `phoneNumber`: Must be non-empty string
- `isVerified`: Must be boolean
- `acceptances`: Must be list (can be empty)

**TripAcceptance**:
- `acceptanceId`: Must be positive integer
- `tripId`: Must be positive integer
- `tripStatus`: Must be non-empty string
- `pickupLocation`: Must be non-empty string
- `dropLocation`: Must be non-empty string
- `acceptedAt`: Must be valid ISO 8601 datetime string

### Timestamp Formatting

The `acceptedAt` field is formatted for display using relative time:
- Less than 1 hour: "X minutes ago"
- Less than 24 hours: "X hours ago"
- Less than 7 days: "X days ago"
- Older: "MMM dd, yyyy" format

