# Bugfix Requirements Document

## Introduction

The OTP authentication flow is broken because the `sendOtp` method in `auth_api_service.dart` looks for `verificationId` at the root level of the API response, but the backend API `/api/users/sendotp/` returns it nested inside a `data` object. The app throws an error "Invalid response: verificationId is missing" and fails to navigate to the OTP verification screen, even though the `verificationId` is present in the response.

The bug occurs because the code at lines 92-93 attempts to extract `verificationId` directly from `payload['verificationId']` instead of first extracting the `data` object and then accessing `data['verificationId']`. The `verifyOtp` method already implements the correct pattern by extracting the `data` object first (lines 167-168).

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN the backend API `/api/users/sendotp/` returns a successful response with `verificationId` nested inside the `data` object THEN the system looks for `verificationId` at the root level of the response

1.2 WHEN the system looks for `verificationId` at the root level and it is not found there THEN the system throws an AuthApiException with message "Invalid response: verificationId is missing"

1.3 WHEN the system looks for `mobileNumber` at the root level and it is not found there THEN the system uses the input phone number as fallback instead of the value from `data['mobileNumber']`

1.4 WHEN the AuthApiException is thrown due to missing `verificationId` THEN the user cannot proceed with OTP verification even though the `verificationId` exists in the response

### Expected Behavior (Correct)

2.1 WHEN the backend API `/api/users/sendotp/` returns a successful response with `verificationId` nested inside the `data` object THEN the system SHALL first extract the `data` object and then look for `verificationId` inside it

2.2 WHEN the system extracts `verificationId` from `data['verificationId']` and it is not empty THEN the system SHALL proceed with navigation to the OTP verification screen

2.3 WHEN the system extracts `mobileNumber` from `data['mobileNumber']` THEN the system SHALL use that value instead of looking at the root level

2.4 WHEN the `data` object is successfully extracted THEN the system SHALL use the same pattern as the `verifyOtp` method (lines 167-168 in auth_api_service.dart)

### Unchanged Behavior (Regression Prevention)

3.1 WHEN the backend API `/api/users/sendotp/` returns an error response (status code >= 300) THEN the system SHALL CONTINUE TO throw an AuthApiException with the appropriate error message

3.2 WHEN the backend API `/api/users/sendotp/` returns a response with `responseCode` != 200 THEN the system SHALL CONTINUE TO throw an AuthApiException with the appropriate error message

3.3 WHEN the phone number input is empty or invalid THEN the system SHALL CONTINUE TO throw an AuthApiException with message "Phone number is required."

3.4 WHEN the `data` object is missing or `verificationId` is empty within the `data` object THEN the system SHALL CONTINUE TO throw an AuthApiException with message "Invalid response: verificationId is missing."

3.5 WHEN the OTP verification process is initiated THEN the system SHALL CONTINUE TO send the `verificationId` to the `/api/users/verifyotp/` endpoint

3.6 WHEN the user successfully verifies the OTP THEN the system SHALL CONTINUE TO navigate to the dashboard page

3.7 WHEN the `verifyOtp` method processes a response THEN the system SHALL CONTINUE TO extract data from the `data` object as it currently does
