# Requirements Document

## Introduction

This feature implements a full-featured Status screen that displays user trips grouped by status (Ongoing, Completed, Pending). The screen replaces the current blank placeholder with a tabbed interface that fetches trip data from the API and displays trip cards with detailed information. Users can view their trips organized by status, pull to refresh the data, and navigate to trip details.

## Glossary

- **Status_Page**: The main screen widget that displays trips grouped by status with a tabbed interface
- **Dashboard_Page**: The main screen of the application containing the bottom navigation bar
- **Status_Screen**: The placeholder widget in Dashboard_Page that navigates to Status_Page
- **Trip**: A transportation request with pickup/drop locations, vehicle details, and status
- **Trip_Status**: The current state of a trip (pending, ongoing, or completed)
- **Trips_API_Service**: The service that fetches trips grouped by status from the backend API
- **Trip_Model**: The data model representing a trip object
- **Tab_Bar**: The horizontal navigation component displaying Ongoing, Completed, and Pending tabs
- **Trip_Card**: A widget displaying trip information in a card format
- **Pull_To_Refresh**: The gesture that triggers data refresh when user pulls down the list

## Requirements

### Requirement 1: Create Status Page Widget

**User Story:** As a developer, I want a dedicated Status_Page widget, so that the status screen follows the app's feature-based architecture pattern.

#### Acceptance Criteria

1. THE Status_Page SHALL be created in lib/features/status/view/status_page.dart
2. THE Status_Page SHALL be a StatefulWidget
3. THE Status_Page SHALL include an AppBar with the title "Status"
4. THE Status_Page SHALL use the app's background color (Color(0xFFF2F2F2))
5. THE Status_Page SHALL follow the existing app styling patterns from Dashboard_Page

### Requirement 2: Implement Tab Navigation

**User Story:** As a user, I want to see three tabs (Ongoing, Completed, Pending), so that I can view trips organized by their status.

#### Acceptance Criteria

1. THE Status_Page SHALL display a Tab_Bar with three tabs
2. THE Tab_Bar SHALL display tabs in the order: Ongoing, Completed, Pending
3. THE selected tab SHALL have a white background with a border outline
4. THE unselected tabs SHALL have a gray background (Color(0xFFEEEEEE))
5. THE Tab_Bar SHALL use rounded rectangle styling for tab indicators
6. THE Status_Page SHALL display a TabBarView with three corresponding tab views

### Requirement 3: Create Trip Data Model

**User Story:** As a developer, I want a Trip_Model class, so that trip data from the API can be properly structured and type-safe.

#### Acceptance Criteria

1. THE Trip_Model SHALL be created in lib/core/models/trip.dart
2. THE Trip_Model SHALL include id as a String field
3. THE Trip_Model SHALL include pickup_location as a String field
4. THE Trip_Model SHALL include drop_location as a String field
5. THE Trip_Model SHALL include load_size as a String field
6. THE Trip_Model SHALL include load_type as a String field
7. THE Trip_Model SHALL include vehicle_size as a String field
8. THE Trip_Model SHALL include body_type as a String field
9. THE Trip_Model SHALL include trip_status as a String field
10. THE Trip_Model SHALL include amount as a String field
11. THE Trip_Model SHALL include pickup_time as a String field (ISO datetime)
12. THE Trip_Model SHALL include name as a String field (customer name)
13. THE Trip_Model SHALL include contact_number as a String field
14. THE Trip_Model SHALL include accepted_drivers as a List field
15. THE Trip_Model SHALL provide a fromJson factory constructor for JSON deserialization

### Requirement 4: Create Trips API Service

**User Story:** As a developer, I want a Trips_API_Service, so that the app can fetch trips grouped by status from the backend.

#### Acceptance Criteria

1. THE Trips_API_Service SHALL be created in lib/core/services/trips_api_service.dart
2. THE Trips_API_Service SHALL make GET requests to https://lorry.workwista.com/api/users/trips/by-status/
3. THE Trips_API_Service SHALL include an Authorization header with Bearer token
4. THE Trips_API_Service SHALL accept an accessToken parameter
5. THE Trips_API_Service SHALL have a 20-second timeout for requests
6. THE Trips_API_Service SHALL return a Map containing pending, ongoing, and completed trip lists
7. WHEN the API returns status code 401, THE Trips_API_Service SHALL throw an authentication error
8. WHEN the API returns status code 500, THE Trips_API_Service SHALL throw a server error
9. WHEN the request times out, THE Trips_API_Service SHALL throw a timeout error
10. THE Trips_API_Service SHALL follow the same pattern as AcceptedDriversApiService

### Requirement 5: Parse API Response

**User Story:** As a developer, I want the API response properly parsed, so that trip data is correctly structured for display.

#### Acceptance Criteria

1. THE Trips_API_Service SHALL parse the response JSON structure with message and data fields
2. THE data field SHALL contain pending, ongoing, and completed objects
3. EACH status object SHALL contain count and trips fields
4. THE trips field SHALL be parsed into a List of Trip_Model objects
5. WHEN the response is invalid JSON, THE Trips_API_Service SHALL throw a parse error
6. WHEN the trips field is null or missing, THE Trips_API_Service SHALL return an empty list

### Requirement 6: Fetch and Display Trips

**User Story:** As a user, I want to see my trips when I open the Status screen, so that I can view my transportation requests.

#### Acceptance Criteria

1. WHEN the Status_Page loads, THE Status_Page SHALL fetch trips from Trips_API_Service
2. THE Status_Page SHALL retrieve the access token from AuthLocalStorage.getAccessToken()
3. WHILE trips are loading, THE Status_Page SHALL display a loading indicator
4. WHEN trips are fetched successfully, THE Status_Page SHALL display trip cards grouped by status
5. THE Ongoing tab SHALL display trips with trip_status "ongoing"
6. THE Completed tab SHALL display trips with trip_status "completed"
7. THE Pending tab SHALL display trips with trip_status "pending"

### Requirement 7: Display Trip Cards

**User Story:** As a user, I want to see trip details in cards, so that I can quickly understand each trip's information.

#### Acceptance Criteria

1. EACH trip SHALL be displayed in a Trip_Card widget
2. THE Trip_Card SHALL display a truck icon on the left side
3. THE Trip_Card SHALL display the route as "Pickup → Drop" with an arrow
4. THE Trip_Card SHALL display a status badge (e.g., "Accepted")
5. THE Trip_Card SHALL display the vehicle size (e.g., "15 Ton")
6. THE Trip_Card SHALL display a chevron right icon for navigation
7. THE Trip_Card SHALL display the pickup time formatted as "Today HH:MM AM/PM" or date
8. FOR completed trips, THE Trip_Card SHALL display a checkmark icon
9. THE Trip_Card SHALL display location details below the route
10. THE Trip_Card SHALL use white background with rounded corners
11. THE Trip_Card SHALL have consistent padding and spacing

### Requirement 8: Handle Empty States

**User Story:** As a user, I want to see a helpful message when there are no trips, so that I understand the screen is working correctly.

#### Acceptance Criteria

1. WHEN a tab has no trips, THE Status_Page SHALL display an empty state message
2. THE empty state SHALL display a truck icon
3. THE empty state SHALL display text like "No [status] trips"
4. THE empty state SHALL use gray colors for icon and text
5. THE empty state SHALL be centered in the tab view

### Requirement 9: Handle Error States

**User Story:** As a user, I want to see error messages when something goes wrong, so that I understand what happened and can retry.

#### Acceptance Criteria

1. WHEN the API request fails, THE Status_Page SHALL display an error message
2. THE error message SHALL display an error icon
3. THE error message SHALL display the error text from the exception
4. THE error message SHALL include a "Retry" button
5. WHEN the user taps "Retry", THE Status_Page SHALL fetch trips again
6. THE error state SHALL preserve the tab navigation

### Requirement 10: Implement Pull to Refresh

**User Story:** As a user, I want to pull down to refresh trips, so that I can see the latest trip data.

#### Acceptance Criteria

1. EACH tab view SHALL support Pull_To_Refresh gesture
2. WHEN the user pulls down, THE Status_Page SHALL fetch trips from the API
3. WHILE refreshing, THE Status_Page SHALL display a loading indicator
4. WHEN refresh completes successfully, THE Status_Page SHALL update the displayed trips
5. WHEN refresh fails, THE Status_Page SHALL display an error message via SnackBar
6. THE Pull_To_Refresh SHALL preserve the current tab selection

### Requirement 11: Navigate from Dashboard

**User Story:** As a user, I want to access the Status screen from the dashboard, so that I can view my trips.

#### Acceptance Criteria

1. THE _StatusScreen widget in Dashboard_Page SHALL navigate to Status_Page
2. WHEN the Status tab is tapped, THE _StatusScreen SHALL push Status_Page onto the navigation stack
3. THE Status_Page SHALL display a back button in the AppBar
4. WHEN the back button is tapped, THE Status_Page SHALL pop back to Dashboard_Page

### Requirement 12: Format Pickup Time Display

**User Story:** As a user, I want to see pickup times in a readable format, so that I can quickly understand when trips are scheduled.

#### Acceptance Criteria

1. WHEN the pickup_time is today, THE Trip_Card SHALL display "Today HH:MM AM/PM"
2. WHEN the pickup_time is tomorrow, THE Trip_Card SHALL display "Tomorrow HH:MM AM/PM"
3. WHEN the pickup_time is another day, THE Trip_Card SHALL display "MMM DD HH:MM AM/PM"
4. THE pickup_time SHALL be parsed from ISO datetime string format
5. THE time format SHALL use 12-hour clock with AM/PM

### Requirement 13: Extract City Names from Locations

**User Story:** As a user, I want to see concise location names, so that trip cards are easy to read.

#### Acceptance Criteria

1. THE Trip_Card SHALL extract city names from full addresses
2. WHEN a location contains commas, THE Trip_Card SHALL display only the first part before the comma
3. THE extracted city name SHALL be trimmed of whitespace
4. THE route display SHALL show "CityA → CityB" format

### Requirement 14: Maintain Consistent Styling

**User Story:** As a user, I want the Status screen to match the app's design, so that the experience feels cohesive.

#### Acceptance Criteria

1. THE Status_Page SHALL use the app's color scheme (0xFF111827 for dark, 0xFFF2F2F2 for background)
2. THE Trip_Card SHALL use the same styling as cards in Dashboard_Page
3. THE fonts SHALL match the existing app typography (weights, sizes)
4. THE spacing and padding SHALL be consistent with Dashboard_Page
5. THE loading and error states SHALL match the patterns in Dashboard_Page
