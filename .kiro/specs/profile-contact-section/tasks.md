# Implementation Plan: Profile Contact Section

## Overview

This implementation adds a contact section to the profile page with a tappable phone number that opens the device's native phone dialer. The feature uses the `url_launcher` package for cross-platform phone dialing support and follows the existing profile page design patterns.

## Tasks

- [x] 1. Add url_launcher dependency and configure platform permissions
  - Add `url_launcher: ^6.2.0` to pubspec.yaml dependencies
  - Add Android query intent for phone dialer in AndroidManifest.xml
  - Run `flutter pub get` to install the package
  - _Requirements: 2.3_

- [ ] 2. Implement phone dialer launcher method
  - [x] 2.1 Add `_launchPhoneDialer()` method to `_ProfilePageState`
    - Create async method that constructs tel: URI with +919562617519
    - Implement `canLaunchUrl()` check before launching
    - Call `launchUrl()` to open phone dialer
    - Add try-catch error handling with SnackBar messages
    - Include `mounted` check before showing SnackBars
    - _Requirements: 2.1, 2.2, 4.1, 4.2, 4.3_
  
  - [ ]* 2.2 Write unit tests for phone dialer launcher
    - Mock url_launcher package
    - Test correct URI construction (tel:+919562617519)
    - Test canLaunchUrl() is called before launchUrl()
    - Test error handling when canLaunchUrl() returns false
    - Test error handling when launchUrl() throws exception
    - Test mounted check prevents errors after disposal
    - _Requirements: 2.1, 2.2, 4.1, 4.2_

- [ ] 3. Create contact section UI component
  - [x] 3.1 Add `_buildContactSection()` method to `_ProfilePageState`
    - Create Container with Column layout
    - Add "Contact Us" label with styling (12px, font-weight 300, color 0xFF1B1B1B)
    - Add InkWell wrapper for tappable area (48px height)
    - Add Row with phone icon (Icons.phone, 20px, color 0xFF111827)
    - Add phone number text "+91 95626 17519" (14px, font-weight 400, color 0xFF111827)
    - Set background color to white (0xFFFFFFFF)
    - Configure InkWell splash color (0xFFE5E7EB)
    - Wire onTap to call `_launchPhoneDialer()`
    - _Requirements: 1.2, 1.3, 3.3, 3.4_
  
  - [ ]* 3.2 Write widget tests for contact section UI
    - Test "Contact Us" label is displayed
    - Test phone number "+91 95626 17519" is displayed
    - Test phone icon is present
    - Test styling matches design specifications
    - Test InkWell provides tap feedback
    - Test tapping calls _launchPhoneDialer()
    - _Requirements: 1.2, 1.3, 3.3, 3.4_

- [x] 4. Integrate contact section into profile page
  - Add `_buildContactSection()` call in build() method's Column
  - Position after existing _buildFieldRow() calls
  - Add SizedBox(height: 16) spacing before contact section
  - Maintain existing SizedBox(height: 32) after contact section
  - _Requirements: 1.1, 3.1, 3.2_

- [x] 5. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ]* 6. Write integration tests for contact section
  - Test contact section is visible on profile page
  - Test contact section is positioned after profile fields
  - Test contact section scrolls with other content
  - Test layout on different screen sizes
  - _Requirements: 1.1, 1.4, 3.1, 3.2_

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- The contact number +91 95626 17519 is hardcoded as specified in requirements
- Error messages follow existing profile page patterns using SnackBar
- UI styling matches existing profile field rows for consistency
- The feature gracefully handles devices without calling capability
