# GOSIKA Flutter – Google OAuth Credential Configuration Guide

This document summarizes the Google Authentication configuration and setup steps required for the **GOSIKA E-Commerce** Flutter application.

---

## Configuration Reference Table

| Configuration | Actual value required | Where to obtain it | Where to configure | Status / Notes |
|---|---|---|---|---|
| **Web Client ID** | `962580735721-2lt123pqoi2ovrpuno025bh57d81bk08.apps.googleusercontent.com` | Google Cloud Console → Google Auth Platform → Clients → Web Client | `lib/core/constants.dart` (`kGoogleWebClientId`) | ✅ Configured |
| **Android package ID** | `com.gosika.app` | Flutter Gradle configuration | Android OAuth client in Google Cloud Console & `android/app/build.gradle.kts` | ✅ Configured in Gradle (`applicationId = "com.gosika.app"`) |
| **Debug SHA-1** | `80:61:AD:B5:6B:70:93:BF:AC:4A:B3:E3:38:38:6F:D5:A0:14:45:A3` | Terminal / Gradle: `./gradlew signingReport` | Android OAuth client in Google Cloud Console | ⚠️ Action Required (Register in Google Cloud) |
| **Debug SHA-256** | `D5:2E:9F:32:11:83:05:EE:D4:89:98:28:84:59:5A:45:F3:04:08:F4:7D:B9:28:F3:DF:A5:CE:5D:B5:FA:8F:99` | Keytool / `./gradlew signingReport` | Android OAuth client in Google Cloud Console | ℹ️ Additional Fingerprint |
| **Release SHA-1** | Actual release fingerprint | Keytool / Play Console App Signing | Android OAuth client in Google Cloud Console | ⚠️ Action Required (Register in Google Cloud) |
| **iOS Client ID** | Actual iOS client ID, if applicable | Google Cloud Console → Clients → iOS Client | `ios/Runner/Info.plist` (if building iOS) | ℹ️ Optional (Scope: Flutter Android/Web API) |

---

## Source Code Placeholders & Configuration Locations

### 1. Web Client ID
- **File**: `lib/core/constants.dart`
- **Placeholder**:
  ```dart
  const String kGoogleWebClientId =
      'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';
  ```
- **Instructions**: Replace `YOUR_WEB_CLIENT_ID.apps.googleusercontent.com` with the Web Client ID generated from:
  `Google Cloud Console → Google Auth Platform → Clients → GOSIKA Backend Authentication`
- **Security Notice**: 🔒 The Web Client ID is used as the `serverClientId` audience for backend ID Token validation. Do NOT store Web Client Secrets in Flutter code.

### 2. Android Application ID
- **File**: `android/app/build.gradle.kts`
- **Configured Value**:
  ```kotlin
  defaultConfig {
      applicationId = "com.gosika.app"
  }
  ```
- **Status**: ✅ Configured.

---

## Google Cloud Console Credentials Setup Summary

1. **Android OAuth Credentials**:
   - Application type: **Android**
   - Package name: `com.gosika.app`
   - SHA-1 Fingerprints: Obtain using `./gradlew signingReport` in the `android` directory and register under the Android OAuth Client.

2. **Web OAuth Credentials**:
   - Application type: **Web application**
   - Name: `GOSIKA Backend Authentication`
   - Copy the generated **Client ID** and set it in `lib/core/constants.dart` as `kGoogleWebClientId`.

---

## Laravel Backend API Contract

- **Endpoint**: `POST /auth/google` (Base URL: `https://gosika.sital.info.np/api/v1`)
- **Request Payload**:
  ```json
  {
    "id_token": "<GOOGLE_ID_TOKEN>",
    "token": "<GOOGLE_ID_TOKEN>",
    "device_name": "Flutter"
  }
  ```
- **Response Structure**:
  ```json
  {
    "success": true,
    "data": {
      "user": {},
      "token": "<SANCTUM_BEARER_TOKEN>"
    }
  }
  ```
- **Storage**: Sanitized Bearer Token stored securely via `flutter_secure_storage` under key `gosika_token`.

---

## Summary of Completed Tasks

- [x] Application ID updated to `com.gosika.app` in `android/app/build.gradle.kts`.
- [x] Integrated `google_sign_in` package in `AuthService` and `AuthNotifier`.
- [x] Configured Google Sign-In with backend `POST /auth/google` API integration and secure token storage.
- [x] Added Google button with official G logo and "Continue with Google" text to `LoginScreen`, `RegisterScreen`, and `WelcomeScreen`.
- [x] Handled account selection, token extraction, backend response processing, and navigation to home (`/`).
- [x] Created `docs/GOOGLE_AUTH_CONFIGURATION.md`.
