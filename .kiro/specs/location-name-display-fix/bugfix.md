# Bugfix Requirements Document

## Introduction

The Trip Details screen currently displays location coordinates in "Lat X, Lng Y" format instead of human-readable location names. When users select a location from the map picker, the destination fields show raw latitude/longitude coordinates (e.g., "Lat 12.97157, Lng 77.59460") rather than meaningful location names (e.g., "Bangalore City Center"). This makes the trip details difficult to read and verify, reducing user experience quality.

The bug occurs when the map picker returns a location without a resolved address name, causing the fallback coordinate format to be displayed in the trip form fields.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN a user selects a location from the map picker by panning the map (without using search) THEN the system displays the location as "Lat X, Lng Y" format in the destination field

1.2 WHEN a user selects a location from the map picker and the reverse geocoding fails or returns no address THEN the system displays the location as "Lat X, Lng Y" format in the destination field

1.3 WHEN the map picker's reverse geocoding completes but the user confirms the location before the address is resolved THEN the system displays the location as "Lat X, Lng Y" format in the destination field

### Expected Behavior (Correct)

2.1 WHEN a user selects a location from the map picker by panning the map (without using search) THEN the system SHALL display a human-readable address obtained through reverse geocoding in the destination field

2.2 WHEN a user selects a location from the map picker and the reverse geocoding fails or returns no address THEN the system SHALL display a fallback human-readable format such as "Location at [coordinates]" or retry the reverse geocoding before confirming

2.3 WHEN the map picker's reverse geocoding completes successfully THEN the system SHALL display the resolved address in the destination field instead of raw coordinates

### Unchanged Behavior (Regression Prevention)

3.1 WHEN a user selects a location from the map picker using the search functionality and selects a place from suggestions THEN the system SHALL CONTINUE TO display the place name or formatted address in the destination field

3.2 WHEN a user manually types a location in the search field and selects it THEN the system SHALL CONTINUE TO display the typed/selected location name in the destination field

3.3 WHEN a user uses the "current location" button in the map picker THEN the system SHALL CONTINUE TO obtain and display the reverse geocoded address for that location

3.4 WHEN location data is submitted as part of the trip creation payload THEN the system SHALL CONTINUE TO send the correct location coordinates to the backend API
