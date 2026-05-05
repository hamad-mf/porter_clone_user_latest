# Design Document: Profile Contact Section

## Overview

This design document specifies the implementation of a contact section for the profile page. The feature adds a tappable contact section displaying "Contact Us" with the phone number +91 95626 17519 that opens the device's native phone dialer when tapped.

### Scope

**In Scope:**
- Adding a contact section UI component to the profile page
- Integrating phone dialer functionality using the `url_launcher` package
- Error handling for devices without calling capability
- Visual feedback for user interactions

**Out of Scope:**
- In-app calling functionality
- Contact form or messaging features
- Multiple contact methods (email, chat, etc.)
- Contact information management or configuration

### Key Design Decisions

1. **Use `url_launcher` package**: This is the standard Flutter package for launching URLs including `tel:` schemes for phone dialing. It provides cross-platform support and handles platform-specific permissions.

2. **Position at bottom of scrollable content**: The contact section will be placed after all existing profile fields within the `SingleChildScrollView`, ensuring it's accessible but doesn't interfere with primary profile information.

3. **Consistent styling**: The contact section will follow the existing profile page design patterns, using the same color scheme, typography, and spacing as other field rows.

4. **Graceful degradation**: On devices without calling capability (e.g., tablets without cellular), the feature will display an error message rather than failing silently.

## Architecture

### Component Structure

```
ProfilePage (StatefulWidget)
├── _ProfilePageState
│   ├── _loadProfile()
│   ├── _saveProfile()
│   ├── _logout()
│   ├── _launchPhoneDialer()  [NEW]
│   └── build()
│       └── SingleChildScrollView
│           └── Column
│               ├── _buildFieldRow() [existing fields]
│               └── _buildContactSection()  [NEW]
```

### Dependencies

**New Dependency:**
- `url_launcher: ^6.2.0` - For launching phone dialer with tel: URL scheme

**Existing Dependencies:**
- Flutter Material widgets
- Existing profile models and services

## Components and Interfaces

### 1. Contact Section Widget

**Method:** `_buildContactSection()`

**Purpose:** Renders the contact section UI with label and tappable phone number.

**Returns:** `Widget`

**UI Structure:**
```
Container
└── Column
    ├── Text("Contact Us") [label]
    └── InkWell [tappable area]
        └── Row
            ├── Icon(Icons.phone)
            └── Text("+91 95626 17519")
```

**Styling:**
- Background: White (`Color(0xFFFFFFFF)`)
- Label text: 12px, font-weight 300, color `Color(0xFF1B1B1B)`
- Phone number: 14px, font-weight 400, color `Color(0xFF111827)`
- Icon: 20px, color `Color(0xFF111827)`
- Padding: Consistent with `_buildFieldRow()` pattern
- Height: 48px for tappable area (matching field rows)

**Visual Feedback:**
- InkWell provides ripple effect on tap
- Splash color: `Color(0xFFE5E7EB)` (light gray)

### 2. Phone Dialer Launcher

**Method:** `_launchPhoneDialer()`

**Purpose:** Opens the device's native phone dialer with the contact number pre-populated.

**Signature:**
```dart
Future<void> _launchPhoneDialer() async
```

**Implementation:**
```dart
Future<void> _launchPhoneDialer() async {
  final Uri phoneUri = Uri(
    scheme: 'tel',
    path: '+919562617519',
  );
  
  try {
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone calling is not available on this device.'),
        ),
      );
    }
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to open phone dialer. Please try again.'),
      ),
    );
  }
}
```

**Behavior:**
1. Constructs a `tel:` URI with the contact number
2. Checks if the device can handle the tel: scheme using `canLaunchUrl()`
3. Launches the dialer using `launchUrl()`
4. Shows error message if calling is not available or launch fails
5. Respects widget lifecycle with `mounted` check before showing SnackBar

### 3. Integration Point

**Location:** `ProfilePage._ProfilePageState.build()`

**Modification:** Add `_buildContactSection()` call after existing field rows in the Column widget within SingleChildScrollView.

**Before:**
```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    _buildFieldRow(label: 'Name', ...),
    _buildFieldRow(label: 'Mobile number', ...),
    const SizedBox(height: 32),
  ],
)
```

**After:**
```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    _buildFieldRow(label: 'Name', ...),
    _buildFieldRow(label: 'Mobile number', ...),
    const SizedBox(height: 16),
    _buildContactSection(),
    const SizedBox(height: 32),
  ],
)
```

## Data Models

No new data models are required. The contact number is hardcoded as specified in requirements: `+91 95626 17519`.

**Rationale:** The contact number is a static configuration value that does not change per user or require backend storage. Hardcoding is appropriate for this use case.

## Error Handling

### Error Scenarios

1. **Device Cannot Make Calls**
   - **Condition:** `canLaunchUrl()` returns `false`
   - **Handling:** Display SnackBar with message "Phone calling is not available on this device."
   - **User Impact:** User is informed that calling is not supported

2. **Dialer Launch Failure**
   - **Condition:** `launchUrl()` throws exception
   - **Handling:** Catch exception, display SnackBar with message "Unable to open phone dialer. Please try again."
   - **User Impact:** User is informed of the failure and can retry

3. **Widget Unmounted During Async Operation**
   - **Condition:** Widget is disposed while async operation is in progress
   - **Handling:** Check `mounted` before calling `ScaffoldMessenger`
   - **User Impact:** Prevents runtime errors, no user-visible impact

### Error Message Design

All error messages follow the existing pattern:
- Displayed via SnackBar
- Clear, user-friendly language
- No technical jargon or error codes
- Consistent with existing profile page error handling

## Testing Strategy

### Assessment: Property-Based Testing Not Applicable

Property-based testing is **not appropriate** for this feature because:

1. **UI Rendering**: The contact section is primarily a UI component with fixed layout and styling. There are no universal properties that vary meaningfully with input.

2. **Side-Effect Operation**: Phone dialer launching is a side-effect operation that opens a native application. There's no return value to assert properties on.

3. **No Data Transformation**: The feature doesn't transform or process data in ways that would benefit from randomized input testing.

4. **Deterministic Behavior**: The behavior is deterministic - tapping always attempts to launch the dialer with the same number.

### Unit Testing Strategy

**Test Coverage:**

1. **Widget Rendering Tests**
   - Verify contact section is displayed on profile page
   - Verify "Contact Us" label is present
   - Verify phone number "+91 95626 17519" is displayed
   - Verify phone icon is present
   - Verify styling matches design specifications

2. **Interaction Tests**
   - Verify tapping phone number calls `_launchPhoneDialer()`
   - Verify InkWell provides visual feedback on tap

3. **Phone Dialer Integration Tests**
   - Mock `url_launcher` package
   - Verify correct URI is constructed (`tel:+919562617519`)
   - Verify `canLaunchUrl()` is called before `launchUrl()`
   - Verify `launchUrl()` is called when `canLaunchUrl()` returns true

4. **Error Handling Tests**
   - Test behavior when `canLaunchUrl()` returns false
   - Verify error SnackBar is displayed with correct message
   - Test behavior when `launchUrl()` throws exception
   - Verify error SnackBar is displayed with correct message
   - Test that `mounted` check prevents errors after widget disposal

5. **Layout Tests**
   - Verify contact section is positioned after profile fields
   - Verify spacing is consistent with design
   - Verify contact section scrolls with other content

### Integration Testing Strategy

**Manual Testing Checklist:**

1. **Device with Calling Capability (Phone)**
   - Tap phone number → Dialer opens with correct number
   - Verify number is pre-populated correctly
   - Cancel call and return to app → App state is preserved

2. **Device without Calling Capability (Tablet/Emulator)**
   - Tap phone number → Error message is displayed
   - Verify error message is clear and helpful

3. **Visual Design Verification**
   - Verify styling matches existing profile fields
   - Verify spacing and alignment
   - Verify tap feedback (ripple effect)
   - Test on different screen sizes

4. **Edge Cases**
   - Rapidly tap phone number multiple times → Should not crash
   - Tap while profile is loading → Should work correctly
   - Tap while in edit mode → Should work correctly

### Test Framework

- **Unit Tests**: Flutter's built-in `flutter_test` package
- **Widget Tests**: `testWidgets()` for UI component testing
- **Mocking**: `mockito` or manual mocks for `url_launcher`

### Test File Location

```
test/
└── features/
    └── profile/
        └── view/
            └── profile_page_contact_section_test.dart
```

## Implementation Notes

### Package Installation

Add to `pubspec.yaml`:
```yaml
dependencies:
  url_launcher: ^6.2.0
```

Run: `flutter pub get`

### Platform Configuration

**Android (`android/app/src/main/AndroidManifest.xml`):**

Add query for phone dialer:
```xml
<queries>
  <intent>
    <action android:name="android.intent.action.DIAL" />
  </intent>
</queries>
```

**iOS (`ios/Runner/Info.plist`):**

No additional configuration required for `tel:` scheme.

### Phone Number Format

The phone number is formatted as `+919562617519` in the URI (no spaces or special characters) but displayed as `+91 95626 17519` in the UI for readability.

### Accessibility

- InkWell provides semantic tap target
- Phone icon provides visual cue
- Text is readable and meets minimum contrast requirements
- Tappable area meets minimum touch target size (48px height)

## Future Enhancements

Potential future improvements (out of scope for this feature):

1. **Configurable Contact Number**: Store contact number in backend configuration
2. **Multiple Contact Methods**: Add email, chat, or support ticket options
3. **Contact History**: Track when users contact support
4. **Business Hours Indicator**: Show if support is currently available
5. **Localization**: Support multiple languages for "Contact Us" label
