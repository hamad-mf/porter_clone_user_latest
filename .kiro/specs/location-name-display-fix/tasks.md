# Implementation Plan

- [-] 1. Write bug condition exploration test
  - **Property 1: Bug Condition** - Display Reverse Geocoded Address for Map Pan Selection
  - **CRITICAL**: This test MUST FAIL on unfixed code - failure confirms the bug exists
  - **DO NOT attempt to fix the test or the code when it fails**
  - **NOTE**: This test encodes the expected behavior - it will validate the fix when it passes after implementation
  - **GOAL**: Surface counterexamples that demonstrate the bug exists
  - **Scoped PBT Approach**: For deterministic bugs, scope the property to the concrete failing case(s) to ensure reproducibility
  - Test that when a user selects a location by panning the map (search field is empty) and reverse geocoding has completed successfully, the `_confirm()` method returns the reverse geocoded address as the label, not the coordinate format
  - The test assertions should match the Expected Behavior Properties from design: label should be the resolved address, not "Lat X, Lng Y" format
  - Mock the reverse geocoding service to return a known address (e.g., "Bangalore City Center, Karnataka")
  - Simulate panning the map to a location and confirming
  - Run test on UNFIXED code
  - **EXPECTED OUTCOME**: Test FAILS (this is correct - it proves the bug exists)
  - Document counterexamples found to understand root cause (e.g., "PickedLocation.label contains 'Lat 12.97157, Lng 77.59460' instead of 'Bangalore City Center, Karnataka'")
  - Mark task complete when test is written, run, and failure is documented
  - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.3_

- [ ] 2. Write preservation property tests (BEFORE implementing fix)
  - **Property 2: Preservation** - Search-Based Selection and Current Location
  - **IMPORTANT**: Follow observation-first methodology
  - Observe behavior on UNFIXED code for non-buggy inputs (search-based selection)
  - Write property-based tests capturing observed behavior patterns from Preservation Requirements
  - Property-based testing generates many test cases for stronger guarantees
  - Test cases to observe and encode:
    - Search Selection: When user searches and selects from suggestions, label should be the selected place name
    - Current Location: When user uses current location button, label should be reverse geocoded address
    - Manual Search Entry: When user manually types in search field, label should be the typed text
    - Coordinate Submission: The `position` field in `PickedLocation` should contain correct coordinates regardless of label
  - Run tests on UNFIXED code
  - **EXPECTED OUTCOME**: Tests PASS (this confirms baseline behavior to preserve)
  - Mark task complete when tests are written, run, and passing on unfixed code
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [ ] 3. Fix for location name display bug

  - [ ] 3.1 Implement the fix in MapPickerPage
    - Reorder label selection logic in `_confirm()` method to prioritize `_resolvedAddress` over `_searchController.text` when search field is empty
    - Change from: `_searchController.text.trim().isNotEmpty ? _searchController.text.trim() : (_resolvedAddress?.isNotEmpty == true ? _resolvedAddress! : _labelFor(_selected))`
    - Change to: `_resolvedAddress?.isNotEmpty == true ? _resolvedAddress! : (_searchController.text.trim().isNotEmpty ? _searchController.text.trim() : _labelFor(_selected))`
    - Ensure reverse geocoding completes before confirming (if needed)
    - Improve fallback format for when reverse geocoding fails (optional enhancement)
    - _Bug_Condition: isBugCondition(input) where input.interactionType == 'MAP_PAN' AND input.searchFieldText.isEmpty AND (input.resolvedAddress == null OR input.confirmedBeforeResolve) AND input.locationSelected == true_
    - _Expected_Behavior: For all inputs where isBugCondition holds, result.label == resolvedAddress OR result.label == userFriendlyFallback, AND result.label NOT LIKE "Lat %, Lng %"_
    - _Preservation: Search-based location selection must continue to display the selected place name or formatted address; Manual text entry in search field must continue to work; Current location button must continue to work; Location coordinates sent to backend must remain unchanged_
    - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.2, 2.3, 3.1, 3.2, 3.3, 3.4_

  - [ ] 3.2 Verify bug condition exploration test now passes
    - **Property 1: Expected Behavior** - Display Reverse Geocoded Address for Map Pan Selection
    - **IMPORTANT**: Re-run the SAME test from task 1 - do NOT write a new test
    - The test from task 1 encodes the expected behavior
    - When this test passes, it confirms the expected behavior is satisfied
    - Run bug condition exploration test from step 1
    - **EXPECTED OUTCOME**: Test PASSES (confirms bug is fixed)
    - _Requirements: 2.1, 2.3_

  - [ ] 3.3 Verify preservation tests still pass
    - **Property 2: Preservation** - Search-Based Selection and Current Location
    - **IMPORTANT**: Re-run the SAME tests from task 2 - do NOT write new tests
    - Run preservation property tests from step 2
    - **EXPECTED OUTCOME**: Tests PASS (confirms no regressions)
    - Confirm all tests still pass after fix (no regressions)
    - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [ ] 4. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.
