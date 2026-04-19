# Splash Screen Stuck Fix - Bugfix Design

## Overview

The splash screen becomes stuck after the 2-second timer completes, failing to navigate to either DashboardPage or SignInPage. The bug manifests when the Timer callback attempts to execute navigation logic - the callback fires but navigation does not occur. The fix will ensure reliable navigation by addressing potential async timing issues, context availability problems, or widget lifecycle conflicts that prevent the navigation from completing.

## Glossary

- **Bug_Condition (C)**: The condition that triggers the bug - when the 2-second timer completes and attempts navigation
- **Property (P)**: The desired behavior when the timer completes - successful navigation to DashboardPage (if authenticated) or SignInPage (if not authenticated)
- **Preservation**: Existing splash screen display, status bar styling, and timer cleanup that must remain unchanged by the fix
- **_startDelay**: The method in `lib/features/splash/view/splash_page.dart` that initializes the Timer and handles navigation logic
- **mounted**: The Flutter widget lifecycle property that indicates whether the widget is still in the widget tree
- **AuthLocalStorage.hasAccessToken()**: The async method that checks SharedPreferences for an access token

## Bug Details

### Bug Condition

The bug manifests when the 2-second Timer completes and the callback attempts to navigate to the next screen. The `_startDelay` method is either encountering a context issue where the BuildContext becomes invalid, experiencing a race condition with widget disposal, or facing an unhandled exception in the async callback that silently fails.

**Formal Specification:**
```
FUNCTION isBugCondition(input)
  INPUT: input of type TimerCompletionEvent
  OUTPUT: boolean
  
  RETURN input.timerDuration == 2 seconds
         AND input.timerCallback is executed
         AND NOT navigationOccurred(input.context)
END FUNCTION
```

### Examples

- **Scenario 1**: User launches app with valid access token → Timer completes after 2 seconds → Navigation to DashboardPage does NOT occur → User remains on splash screen indefinitely
- **Scenario 2**: User launches app without access token → Timer completes after 2 seconds → Navigation to SignInPage does NOT occur → User remains on splash screen indefinitely
- **Scenario 3**: User launches app → Timer completes → mounted check passes → hasAccessToken() completes → Navigator.pushReplacement is called but fails silently
- **Edge case**: User launches app → Widget is disposed before timer completes → Timer callback should be cancelled (this currently works correctly)

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors:**
- Splash screen must continue to display the logo centered on a white background
- Status bar must remain transparent with light icons during splash screen display
- Timer must continue to be cancelled in the dispose method to prevent memory leaks
- Firebase and notification services initialization in main() must continue to complete successfully

**Scope:**
All aspects of the splash screen that do NOT involve the navigation logic should be completely unaffected by this fix. This includes:
- Visual presentation (logo, background color, layout)
- Status bar styling (SystemChrome configuration)
- Widget lifecycle management (dispose cleanup)
- App initialization sequence (Firebase, notifications)

## Hypothesized Root Cause

Based on the bug description and code analysis, the most likely issues are:

1. **Async Timing Issue**: The `hasAccessToken()` call is async and may be taking longer than expected, or the Timer callback may not be properly awaiting the async operation before attempting navigation

2. **Context Invalidation**: The BuildContext used in `Navigator.of(context).pushReplacement` may become invalid between the Timer creation and callback execution, especially if there are widget rebuilds during the 2-second delay

3. **Silent Exception**: An unhandled exception in the async callback (from `hasAccessToken()` or navigation) may be failing silently without proper error handling, causing the navigation to never execute

4. **Widget Lifecycle Conflict**: Although the `mounted` check exists, there may be a race condition where the widget is mounted when checked but becomes unmounted before navigation completes

5. **Navigator State Issue**: The Navigator may not be properly initialized or available when the splash screen attempts to use it, possibly due to MaterialApp initialization timing

## Correctness Properties

Property 1: Bug Condition - Timer Completion Triggers Navigation

_For any_ timer completion event where the 2-second delay has elapsed and the widget is still mounted, the fixed _startDelay function SHALL successfully navigate to DashboardPage (if access token exists) or SignInPage (if no access token exists), removing the splash screen from the navigation stack.

**Validates: Requirements 2.1, 2.2**

Property 2: Preservation - Visual and Lifecycle Behavior

_For any_ splash screen initialization and display that does NOT involve the navigation callback execution, the fixed code SHALL produce exactly the same behavior as the original code, preserving the logo display, status bar styling, timer cleanup on disposal, and app initialization sequence.

**Validates: Requirements 3.1, 3.2, 3.3, 3.4**

## Fix Implementation

### Changes Required

Assuming our root cause analysis is correct:

**File**: `lib/features/splash/view/splash_page.dart`

**Function**: `_startDelay`

**Specific Changes**:
1. **Add Error Handling**: Wrap the async operations in try-catch to surface any silent exceptions that may be preventing navigation
   - Catch exceptions from `AuthLocalStorage.hasAccessToken()`
   - Log errors for debugging
   - Provide fallback navigation behavior

2. **Strengthen Context Validation**: Ensure the BuildContext remains valid throughout the async operation
   - Verify `mounted` immediately before navigation
   - Consider using `Navigator.of(context, rootNavigator: true)` to ensure we're using the root navigator

3. **Add Debugging Logs**: Insert log statements to trace execution flow and identify where the navigation fails
   - Log when timer starts
   - Log when timer callback executes
   - Log token check result
   - Log navigation attempt

4. **Consider Alternative Timing Approach**: If Timer proves unreliable, consider using `Future.delayed` with async/await pattern for more predictable async behavior
   - Replace Timer with Future.delayed
   - Use async/await for cleaner error handling

5. **Add Timeout Protection**: Implement a timeout mechanism to ensure navigation occurs even if token check hangs
   - Use `Future.timeout` on the hasAccessToken call
   - Provide default behavior if timeout occurs

## Testing Strategy

### Validation Approach

The testing strategy follows a two-phase approach: first, surface counterexamples that demonstrate the bug on unfixed code, then verify the fix works correctly and preserves existing behavior.

### Exploratory Bug Condition Checking

**Goal**: Surface counterexamples that demonstrate the bug BEFORE implementing the fix. Confirm or refute the root cause analysis. If we refute, we will need to re-hypothesize.

**Test Plan**: Write tests that simulate the splash screen initialization and timer completion. Run these tests on the UNFIXED code to observe failures and understand the root cause. Use widget testing to control the async environment and observe navigation behavior.

**Test Cases**:
1. **Authenticated User Navigation Test**: Initialize splash screen with valid access token in SharedPreferences, wait for 2 seconds, verify navigation to DashboardPage occurs (will fail on unfixed code)
2. **Unauthenticated User Navigation Test**: Initialize splash screen with no access token, wait for 2 seconds, verify navigation to SignInPage occurs (will fail on unfixed code)
3. **Context Validity Test**: Monitor BuildContext validity throughout timer execution to identify if context becomes invalid (may reveal root cause)
4. **Exception Handling Test**: Inject failures in hasAccessToken() to see if exceptions are silently swallowed (may reveal root cause)

**Expected Counterexamples**:
- Navigation does not occur after timer completes
- Possible causes: silent exception in async callback, context invalidation, Navigator state not ready, async timing issue

### Fix Checking

**Goal**: Verify that for all inputs where the bug condition holds, the fixed function produces the expected behavior.

**Pseudocode:**
```
FOR ALL timerCompletion WHERE isBugCondition(timerCompletion) DO
  result := _startDelay_fixed(timerCompletion)
  ASSERT navigationOccurred(result)
  ASSERT correctDestination(result, hasAccessToken())
END FOR
```

### Preservation Checking

**Goal**: Verify that for all inputs where the bug condition does NOT hold, the fixed function produces the same result as the original function.

**Pseudocode:**
```
FOR ALL splashBehavior WHERE NOT isBugCondition(splashBehavior) DO
  ASSERT _SplashPageState_original(splashBehavior) = _SplashPageState_fixed(splashBehavior)
END FOR
```

**Testing Approach**: Property-based testing is recommended for preservation checking because:
- It generates many test cases automatically across the input domain
- It catches edge cases that manual unit tests might miss
- It provides strong guarantees that behavior is unchanged for all non-navigation aspects

**Test Plan**: Observe behavior on UNFIXED code first for visual display, status bar styling, and timer cleanup, then write property-based tests capturing that behavior.

**Test Cases**:
1. **Visual Display Preservation**: Observe that logo displays correctly on white background in unfixed code, then write test to verify this continues after fix
2. **Status Bar Preservation**: Observe that status bar is transparent with light icons in unfixed code, then write test to verify this continues after fix
3. **Timer Cleanup Preservation**: Observe that timer is cancelled on widget disposal in unfixed code, then write test to verify this continues after fix
4. **Initialization Preservation**: Observe that Firebase and notification services initialize correctly in unfixed code, then write test to verify this continues after fix

### Unit Tests

- Test timer initialization and callback execution
- Test token check with various SharedPreferences states (token present, token absent, token empty)
- Test navigation with valid and invalid contexts
- Test widget disposal cancels timer correctly
- Test error handling for hasAccessToken() failures

### Property-Based Tests

- Generate random app states (authenticated/unauthenticated) and verify navigation always occurs to correct destination
- Generate random timing scenarios and verify navigation completes within reasonable timeframe
- Test that visual display remains consistent across many initialization scenarios

### Integration Tests

- Test full app launch flow from main() through splash screen to dashboard/sign-in
- Test that Firebase initialization completes before splash screen navigation
- Test that notification services work correctly after splash screen navigation
- Test rapid app restarts to verify no race conditions in initialization
