# Requirements Document

## Introduction

This feature integrates the accepted drivers API into the home screen of the porter_clone_user Flutter application. The system will fetch accepted driver information from the backend API and display it in card format on the dashboard home tab, replacing or augmenting the current "Current Requests" section. This enables users to view drivers who have accepted their trip requests along with relevant trip details.

## Glossary

- **Accepted_Drivers_API**: The REST API endpoint at "https://lorry.workwista.com/api/users/trips/all/accepted-drivers/" that returns accepted driver information
- **Dashboard_Home_Tab**: The home screen widget (_DashboardHomeTab) in the dashboard_page.dart file
- **Driver_Card**: A UI card component that displays information about a driver who has accepted a trip
- **Access_Token**: The authentication token stored locally and used to authorize API requests
- **API_Client**: The HTTP client service responsible for making network requests
- **Driver_Repository**: The data layer component that fetches and manages accepted driver data
- **Driver_State**: The state management object that holds the current status of driver data (loading, loaded, error, empty)
- **Trip_Acceptance**: A record of a driver accepting a specific trip request, including trip details and acceptance timestamp

## Requirements

### Requirement 1: Fetch Accepted Drivers Data

**User Story:** As a user, I want the app to automatically fetch accepted drivers when I open the home screen, so that I can see which drivers have accepted my trip requests.

#### Acceptance Criteria

1. WHEN the Dashboard_Home_Tab is displayed, THE Driver_Repository SHALL fetch data from the Accepted_Drivers_API
2. THE API_Client SHALL include the Access_Token in the authorization header of the request
3. WHEN the Accepted_Drivers_API returns a successful response, THE Driver_Repository SHALL parse the JSON response into driver model objects
4. WHEN the Accepted_Drivers_API returns an error response, THE Driver_Repository SHALL return an error state with the error message
5. WHEN the network request fails, THE Driver_Repository SHALL return an error state indicating network failure

### Requirement 2: Parse API Response

**User Story:** As a developer, I want the API response to be parsed into strongly-typed models, so that the data can be safely used throughout the application.

#### Acceptance Criteria

1. THE Driver_Repository SHALL parse the "accepted_drivers" array into a list of driver model objects
2. FOR EACH driver object, THE Driver_Repository SHALL extract driver_id, user_id, full_name, phone_number, and is_verified fields
3. FOR EACH acceptance in the driver's acceptances array, THE Driver_Repository SHALL extract acceptance_id, trip_id, trip_status, pickup_location, drop_location, and accepted_at fields
4. WHEN a required field is missing from the API response, THE Driver_Repository SHALL handle the parsing error gracefully
5. THE Driver_Repository SHALL parse the accepted_at timestamp into a DateTime object

### Requirement 3: Display Driver Cards

**User Story:** As a user, I want to see accepted drivers displayed in cards on the home screen, so that I can quickly view driver and trip information.

#### Acceptance Criteria

1. WHEN accepted driver data is available, THE Dashboard_Home_Tab SHALL display a Driver_Card for each driver
2. THE Driver_Card SHALL display the driver's full_name prominently
3. THE Driver_Card SHALL display the driver's phone_number
4. WHEN the driver has a verification status, THE Driver_Card SHALL display a verification indicator if is_verified is true
5. FOR EACH trip acceptance, THE Driver_Card SHALL display the pickup_location and drop_location
6. THE Driver_Card SHALL display the trip_status for each acceptance
7. THE Driver_Card SHALL format and display the accepted_at timestamp in a human-readable format

### Requirement 4: Handle Loading State

**User Story:** As a user, I want to see a loading indicator while driver data is being fetched, so that I know the app is working.

#### Acceptance Criteria

1. WHEN the Dashboard_Home_Tab initiates a data fetch, THE Dashboard_Home_Tab SHALL display a loading indicator
2. WHILE the Driver_Repository is fetching data, THE Dashboard_Home_Tab SHALL prevent user interaction with the driver cards section
3. WHEN the data fetch completes successfully, THE Dashboard_Home_Tab SHALL hide the loading indicator and display the driver cards
4. WHEN the data fetch completes with an error, THE Dashboard_Home_Tab SHALL hide the loading indicator and display an error message

### Requirement 5: Handle Empty State

**User Story:** As a user, I want to see a helpful message when there are no accepted drivers, so that I understand why no cards are displayed.

#### Acceptance Criteria

1. WHEN the Accepted_Drivers_API returns an empty accepted_drivers array, THE Dashboard_Home_Tab SHALL display an empty state message
2. THE Dashboard_Home_Tab SHALL display a message indicating "No accepted drivers yet" or similar text
3. THE Dashboard_Home_Tab SHALL display an icon or illustration in the empty state
4. THE Dashboard_Home_Tab SHALL maintain the layout structure even when no driver cards are present

### Requirement 6: Handle Error State

**User Story:** As a user, I want to see a clear error message when driver data cannot be loaded, so that I understand what went wrong and can take action.

#### Acceptance Criteria

1. WHEN the Driver_Repository returns an error state, THE Dashboard_Home_Tab SHALL display an error message
2. THE Dashboard_Home_Tab SHALL display a retry button in the error state
3. WHEN the user taps the retry button, THE Dashboard_Home_Tab SHALL re-initiate the data fetch
4. THE Dashboard_Home_Tab SHALL display different error messages for network errors versus API errors
5. WHEN authentication fails (401 response), THE Dashboard_Home_Tab SHALL display an authentication error message

### Requirement 7: Refresh Driver Data

**User Story:** As a user, I want to refresh the accepted drivers list, so that I can see the most up-to-date information.

#### Acceptance Criteria

1. THE Dashboard_Home_Tab SHALL support pull-to-refresh gesture
2. WHEN the user performs a pull-to-refresh gesture, THE Driver_Repository SHALL fetch fresh data from the Accepted_Drivers_API
3. WHILE refreshing, THE Dashboard_Home_Tab SHALL display a refresh indicator
4. WHEN the refresh completes, THE Dashboard_Home_Tab SHALL update the displayed driver cards with new data
5. WHEN the refresh fails, THE Dashboard_Home_Tab SHALL display an error message without removing existing driver cards

### Requirement 8: Manage Authentication Token

**User Story:** As a developer, I want the API client to automatically retrieve and use the stored access token, so that API requests are properly authenticated.

#### Acceptance Criteria

1. WHEN making a request to the Accepted_Drivers_API, THE API_Client SHALL retrieve the Access_Token from local storage
2. THE API_Client SHALL include the Access_Token in the "Authorization" header with "Bearer" prefix
3. WHEN the Access_Token is not available, THE API_Client SHALL return an authentication error
4. WHEN the API returns a 401 unauthorized response, THE API_Client SHALL indicate that the token is invalid or expired

### Requirement 9: Display Multiple Trip Acceptances

**User Story:** As a user, I want to see all trip acceptances for each driver, so that I can view all trips a driver has accepted.

#### Acceptance Criteria

1. WHEN a driver has multiple trip acceptances, THE Driver_Card SHALL display all acceptances
2. THE Driver_Card SHALL visually separate multiple trip acceptances within the same card
3. FOR EACH trip acceptance, THE Driver_Card SHALL display the complete trip information
4. THE Driver_Card SHALL display trip acceptances in chronological order based on accepted_at timestamp

### Requirement 10: Integrate with Existing UI

**User Story:** As a user, I want the accepted drivers section to fit seamlessly into the existing home screen design, so that the app feels cohesive.

#### Acceptance Criteria

1. THE Dashboard_Home_Tab SHALL display the accepted drivers section below the "Create Trip" card
2. THE Driver_Card SHALL use the same design language as existing cards (border radius, padding, colors)
3. THE Dashboard_Home_Tab SHALL display a section header "Accepted Drivers" or similar text above the driver cards
4. THE Dashboard_Home_Tab SHALL maintain consistent spacing between driver cards
5. THE Dashboard_Home_Tab SHALL use the existing color scheme defined in the dashboard (Color(0xFF111827), Color(0xFFEEEEEE), etc.)
