# Location Name Display Fix - Bugfix Design

## Overview

The Trip Details screen displays raw coordinates ("Lat X, Lng Y") instead of human-readable location names when users select locations by panning the map. The bug occurs because the `_confirm()` method in `MapPickerPage` prioritizes the search field text over the resolved address from reverse geocoding. When users pan the map without using search, the search field is cleared but the reverse geocoding result stored in `_resolvedAddress` is not used as the primary label source.

The fix will reorder the label selection logic to prioritize `_resolvedAddress` over the search field text, ensuring that reverse geocoded addresses are displayed when available.

## Glossary

- **Bug_Condition (C)**: The condition that triggers the bug - when a user selects a location by panning the map (search field is empty) and reverse geocoding has completed
- **Property (P)**: The desired behavior - the destination field should display the reverse geocoded address instead of "Lat X, Lng Y"
- **Preservation**: Existing search-based location selection and current location functionality that must remain unchanged
- **MapPickerPage**: The widget in `lib/features/map/view/map_picker_page.dart` that allows users to select locations from a map
- **_confirm()**: The method that returns the selected location to the calling page
- **_resolvedAddress**: The state variable that stores the reverse geocoded address for the current map position
- **_searchController**: The TextEditingController for the search field
- **_reverseGeocode()**: The method that calls the Places API to convert coordinates to an address

## Bug Details

### Bug Condition

The bug manifests when a user selects a location by panning the map without using the search functionality. The `_confirm()` method constructs the label using this logic:

```dart
final label = _searchController.text.trim().isNotEmpty
    ? _searchController.text.trim()
    : (_resolvedAddress?.isNotEmpty == true ? _resolvedAddress! : _labelFor(_selected));
```

When the user pans the map, `_searchController.text` is cleared (empty), but the fallback logic checks `_resolvedAddress` only as a secondary option. If reverse geocoding is slow or hasn't completed yet, `_labelFor(_selected)` is used, which returns the coordinate format.

**Formal Specification:**
```
FUNCTION isBugCondition(input)
  INPUT: input of type UserInteraction
  OUTPUT: boolean
  
  RETURN input.interactionType == 'MAP_PAN'
         AND input.searchFieldText.isEmpty
         AND (input.resolvedAddress == null OR input.confirmedBeforeResolve)
         AND input.locationSelected == true
END FUNCTION
```

### Examples

- **Example 1**: User opens map picker, pans to a location in Bangalore, waits 1 second, clicks "Use this location". Expected: "Bangalore City Center, Karnataka". Actual: "Lat 12.97157, Lng 77.59460"

- **Example 2**: User opens map picker, pans to a location, immediately clicks "Use this location" before reverse geocoding completes. Expected: Wait for address or show "Loading..." then update. Actual: "Lat 12.97157, Lng 77.59460"

- **Example 3**: User opens map picker, pans to a remote location where reverse geocoding returns null. Expected: "Location at 12.97157, 77.59460" or similar human-readable fallback. Actual: "Lat 12.97157, Lng 77.59460"

- **Edge Case**: User opens map picker, searches for "MG Road", selects from suggestions, then pans slightly. Expected: Show new reverse geocoded address for panned location. Actual: May show "Lat X, Lng Y" if reverse geocoding hasn't completed

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors:**
- Search-based location selection must continue to display the selected place name or formatted address
- Manual text entry in the search field must continue to work as before
- Current location button must continue to obtain and display the reverse geocoded address
- Location coordinates sent to the backend API must remain unchanged

**Scope:**
All inputs that involve using the search functionality (typing and selecting from suggestions) should be completely unaffected by this fix. This includes:
- Selecting a location from autocomplete suggestions
- Using the current location button (already works correctly)
- The map camera positioning and animation behavior

## Hypothesized Root Cause

Based on the bug description and code analysis, the most likely issues are:

1. **Incorrect Priority in Label Selection**: The `_confirm()` method prioritizes `_searchController.text` over `_resolvedAddress`, which means an empty search field takes precedence over a successfully resolved address

2. **Race Condition**: When users click "Use this location" immediately after panning, the reverse geocoding may not have completed yet, causing `_resolvedAddress` to be null

3. **No Loading State**: There's no indication to the user that reverse geocoding is in progress, leading them to confirm before the address is resolved

4. **Insufficient Fallback**: When reverse geocoding fails or returns null, the fallback format "Lat X, Lng Y" is not user-friendly

## Correctness Properties

Property 1: Bug Condition - Display Reverse Geocoded Address

_For any_ user interaction where a location is selected by panning the map (search field is empty) and reverse geocoding has completed successfully, the fixed `_confirm()` method SHALL return the reverse geocoded address as the label, not the coordinate format.

**Validates: Requirements 2.1, 2.3**

Property 2: Preservation - Search-Based Selection

_For any_ user interaction where a location is selected using the search functionality (search field is not empty), the fixed `_confirm()` method SHALL produce exactly the same behavior as the original code, returning the search field text as the label.

**Validates: Requirements 3.1, 3.2**

## Fix Implementation

### Changes Required

Assuming our root cause analysis is correct:

**File**: `lib/features/map/view/map_picker_page.dart`

**Function**: `_confirm()`

**Specific Changes**:

1. **Reorder Label Priority**: Change the label selection logic to prioritize `_resolvedAddress` over `_searchController.text` when the search field is empty:
   ```dart
   final label = _resolvedAddress?.isNotEmpty == true
       ? _resolvedAddress!
       : (_searchController.text.trim().isNotEmpty
           ? _searchController.text.trim()
           : _labelFor(_selected));
   ```

2. **Add Loading State** (Optional Enhancement): Add a boolean `_isReverseGeocoding` to track when reverse geocoding is in progress, and disable the "Use this location" button or show a loading indicator

3. **Improve Fallback Format** (Optional Enhancement): Replace `_labelFor()` with a more user-friendly format like "Location at [coordinates]" or "Selected Location"

4. **Ensure Reverse Geocoding Completes** (Optional Enhancement): In `_confirm()`, if `_resolvedAddress` is null and search field is empty, wait briefly for reverse geocoding to complete before returning

5. **Handle Null Resolved Address**: Ensure that when reverse geocoding fails, a user-friendly fallback is used instead of coordinates

## Testing Strategy

### Validation Approach

The testing strategy follows a two-phase approach: first, surface counterexamples that demonstrate the bug on unfixed code, then verify the fix works correctly and preserves existing behavior.

### Exploratory Bug Condition Checking

**Goal**: Surface counterexamples that demonstrate the bug BEFORE implementing the fix. Confirm or refute the root cause analysis. If we refute, we will need to re-hypothesize.

**Test Plan**: Write widget tests that simulate panning the map and clicking "Use this location". Mock the reverse geocoding service to return a known address. Run these tests on the UNFIXED code to observe that coordinates are returned instead of the address.

**Test Cases**:
1. **Pan and Confirm Test**: Simulate panning the map, wait for reverse geocoding, then confirm (will fail on unfixed code - returns coordinates)
2. **Immediate Confirm Test**: Simulate panning the map and immediately confirming before reverse geocoding completes (will fail on unfixed code - returns coordinates)
3. **Failed Reverse Geocoding Test**: Simulate panning to a location where reverse geocoding returns null (will fail on unfixed code - returns coordinates)
4. **Search Then Pan Test**: Simulate searching for a location, then panning slightly (may fail on unfixed code - returns coordinates)

**Expected Counterexamples**:
- `PickedLocation.label` contains "Lat X, Lng Y" format when `_resolvedAddress` has a valid address
- Possible causes: incorrect priority in label selection, race condition with reverse geocoding

### Fix Checking

**Goal**: Verify that for all inputs where the bug condition holds, the fixed function produces the expected behavior.

**Pseudocode:**
```
FOR ALL input WHERE isBugCondition(input) DO
  result := _confirm_fixed()
  ASSERT result.label == resolvedAddress OR result.label == userFriendlyFallback
  ASSERT result.label NOT LIKE "Lat %, Lng %"
END FOR
```

### Preservation Checking

**Goal**: Verify that for all inputs where the bug condition does NOT hold, the fixed function produces the same result as the original function.

**Pseudocode:**
```
FOR ALL input WHERE NOT isBugCondition(input) DO
  ASSERT _confirm_original() = _confirm_fixed()
END FOR
```

**Testing Approach**: Property-based testing is recommended for preservation checking because:
- It generates many test cases automatically across the input domain
- It catches edge cases that manual unit tests might miss
- It provides strong guarantees that behavior is unchanged for all non-buggy inputs

**Test Plan**: Observe behavior on UNFIXED code first for search-based selection, then write property-based tests capturing that behavior.

**Test Cases**:
1. **Search Selection Preservation**: Observe that searching and selecting from suggestions returns the selected place name on unfixed code, then verify this continues after fix
2. **Current Location Preservation**: Observe that using current location button returns reverse geocoded address on unfixed code, then verify this continues after fix
3. **Manual Search Entry Preservation**: Observe that manually typing in search field returns typed text on unfixed code, then verify this continues after fix
4. **Coordinate Submission Preservation**: Verify that the `position` field in `PickedLocation` remains unchanged (only `label` should change)

### Unit Tests

- Test `_confirm()` with empty search field and valid `_resolvedAddress` - should return resolved address
- Test `_confirm()` with non-empty search field - should return search field text
- Test `_confirm()` with empty search field and null `_resolvedAddress` - should return user-friendly fallback
- Test that `_reverseGeocode()` is called when map is panned
- Test that coordinates in `PickedLocation.position` are correct regardless of label

### Property-Based Tests

- Generate random map positions and verify that after panning and confirming, the label is either a resolved address or a user-friendly fallback (never raw coordinates)
- Generate random search queries and verify that after searching and selecting, the label matches the selected suggestion
- Test that across many scenarios, the `position` field always contains the correct coordinates

### Integration Tests

- Test full flow: open map picker, pan to location, wait for reverse geocoding, confirm - verify human-readable address is returned
- Test full flow: open map picker, search for location, select from suggestions, confirm - verify selected place name is returned
- Test full flow: open map picker, use current location button, confirm - verify reverse geocoded address is returned
- Test that the returned label is displayed correctly in the trip form fields
