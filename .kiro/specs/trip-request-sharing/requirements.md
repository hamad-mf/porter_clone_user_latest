# Requirements Document

## Introduction

This document specifies the requirements for implementing deep linking and trip request sharing functionality in the lorry app. The feature enables users to share trip requests via links that can be opened directly in the app, with proper handling of authentication states and navigation flows.

## Glossary

- **Deep_Link_Handler**: The service component that listens for and processes incoming deep links
- **Trip_Request**: A transportation job posted by a customer that drivers can view and accept
- **Share_Service**: The service component that generates shareable links for trip requests
- **App_Links**: Android App Links mechanism for verified HTTPS deep links
- **Authentication_Guard**: The component that checks user authentication status before allowing protected actions
- **Trip_Details_Screen**: The screen that displays full information about a specific trip request
- **Splash_Screen**: The initial screen shown when the app launches, responsible for routing based on authentication and deep link state

## Requirements

### Requirement 1: Generate Shareable Trip Request Links

**User Story:** As a user, I want to share trip requests via links, so that I can notify others about available transportation jobs.

#### Acceptance Criteria

1. THE Share_Service SHALL generate a unique HTTPS link for each trip request in the format `https://lorry.workwista.com/share/trip/{tripId}`
2. THE Share_Service SHALL include trip summary information in the share text (pickup location, drop location, vehicle type)
3. WHEN a user triggers the share action, THE Share_Service SHALL invoke the system share dialog with the generated link and summary text
4. THE generated link SHALL be valid for the lifetime of the trip request
5. THE home screen trip request card SHALL display a share button/icon for each trip request
6. WHEN a user taps the share button on a trip request card, THE Share_Service SHALL be invoked with that trip's information

### Requirement 2: Configure Android App Links

**User Story:** As a developer, I want to configure verified Android App Links, so that trip request links open directly in the app without disambiguation dialogs.

#### Acceptance Criteria

1. THE AndroidManifest SHALL declare an intent filter with `android:autoVerify="true"` for the host `lorry.workwista.com`
2. THE intent filter SHALL handle the HTTPS scheme for the host `lorry.workwista.com`
3. THE intent filter SHALL include VIEW action, DEFAULT category, and BROWSABLE category
4. THE app SHALL support a custom scheme `lorry://` as a fallback for deep linking

### Requirement 3: Process Incoming Deep Links

**User Story:** As a user, I want the app to open the correct trip request when I click a shared link, so that I can quickly view the details.

#### Acceptance Criteria

1. WHEN the app receives a deep link, THE Deep_Link_Handler SHALL extract the trip ID from the URL path
2. THE Deep_Link_Handler SHALL support the URL pattern `https://lorry.workwista.com/share/trip/{tripId}`
3. THE Deep_Link_Handler SHALL support the URL pattern `lorry://trip/{tripId}`
4. IF the URL does not contain a valid trip ID, THEN THE Deep_Link_Handler SHALL log the error and take no navigation action

### Requirement 4: Handle Deep Links at App Launch

**User Story:** As a user, I want the app to navigate to the shared trip request when I open the app from a link, so that I see the relevant content immediately.

#### Acceptance Criteria

1. WHEN the app is launched from a deep link, THE Splash_Screen SHALL receive the trip ID from the Deep_Link_Handler
2. WHILE the user is authenticated, THE Splash_Screen SHALL navigate directly to the Trip_Details_Screen with the trip ID
3. WHILE the user is not authenticated, THE Splash_Screen SHALL navigate to the login screen and preserve the trip ID for post-login navigation
4. WHEN login completes successfully, THE app SHALL navigate to the Trip_Details_Screen with the preserved trip ID

### Requirement 5: Handle Deep Links While App is Running

**User Story:** As a user, I want to open shared trip request links while the app is already running, so that I can view multiple trip requests without restarting the app.

#### Acceptance Criteria

1. WHEN the app receives a deep link while running, THE Deep_Link_Handler SHALL navigate to the Trip_Details_Screen with the trip ID
2. THE navigation SHALL push the Trip_Details_Screen onto the current navigation stack
3. THE Deep_Link_Handler SHALL listen for deep links throughout the app lifecycle
4. WHEN the Deep_Link_Handler is disposed, THE app SHALL cancel the deep link subscription

### Requirement 6: Display Trip Request Details Without Authentication

**User Story:** As an unauthenticated user, I want to view trip request details from a shared link, so that I can decide if I want to accept the job before logging in.

#### Acceptance Criteria

1. THE Trip_Details_Screen SHALL display trip information (pickup location, drop location, load details, vehicle requirements, amount, pickup time) without requiring authentication
2. THE Trip_Details_Screen SHALL fetch trip data using the trip ID from the deep link
3. IF the trip request does not exist, THEN THE Trip_Details_Screen SHALL display an error message
4. THE Trip_Details_Screen SHALL display all read-only trip information to unauthenticated users

### Requirement 7: Require Authentication for Trip Acceptance

**User Story:** As a product owner, I want to require authentication before users can accept trip requests, so that we maintain proper user accountability and tracking.

#### Acceptance Criteria

1. WHEN an unauthenticated user attempts to accept a trip request, THE Authentication_Guard SHALL navigate to the login screen
2. THE Authentication_Guard SHALL preserve the trip ID and return intent (accept action) during the login flow
3. WHEN login completes successfully, THE app SHALL return to the Trip_Details_Screen with the trip ID
4. WHEN the user returns to the Trip_Details_Screen after login, THE app SHALL automatically trigger the accept action

### Requirement 8: Initialize Deep Link Handler at App Startup

**User Story:** As a developer, I want the deep link handler to initialize when the app starts, so that deep links are processed correctly from the first moment.

#### Acceptance Criteria

1. THE app SHALL wrap the root widget with the Deep_Link_Handler widget
2. WHEN the Deep_Link_Handler initializes, THE handler SHALL check for an initial deep link
3. THE Deep_Link_Handler SHALL set up a stream listener for subsequent deep links
4. IF an error occurs during deep link initialization, THEN THE Deep_Link_Handler SHALL log the error and continue app initialization

### Requirement 9: Parse Deep Link URLs

**User Story:** As a developer, I want a robust URL parser for deep links, so that the app correctly extracts trip IDs from various URL formats.

#### Acceptance Criteria

1. THE Deep_Link_Handler SHALL parse HTTPS URLs with the pattern `https://lorry.workwista.com/share/trip/{tripId}`
2. THE Deep_Link_Handler SHALL parse custom scheme URLs with the pattern `lorry://trip/{tripId}`
3. THE Deep_Link_Handler SHALL extract the trip ID from the URL path segments
4. FOR ALL valid trip request URLs, parsing the URL SHALL produce the correct trip ID (round-trip property)
5. IF the URL format is invalid, THEN THE Deep_Link_Handler SHALL return null for the trip ID

### Requirement 10: Manage Deep Link State

**User Story:** As a developer, I want proper state management for deep links, so that the app handles edge cases like rapid link clicks or app state changes.

#### Acceptance Criteria

1. WHEN a deep link is processed at app launch, THE Splash_Screen SHALL pass the trip ID directly to the navigation logic without persisting it
2. THE app SHALL NOT store deep link data in SharedPreferences for initial links
3. WHEN the app is already running and receives a deep link, THE Deep_Link_Handler SHALL navigate immediately without storing state
4. THE app SHALL clear any legacy deep link storage mechanisms to prevent conflicts

