# Day 5 — Dev Environment & Firebase Setup Guide

## Environment Prerequisites

- **Flutter SDK**: `>=3.0.0`
- **Dart SDK**: `>=3.0.0`
- **Android SDK Target**: API 34+ (Android 14)
- **Minimum Android SDK**: API 21 (Android 5.0 Lollipop)

---

## Package Dependencies (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  firebase_core: ^3.10.1
  firebase_auth: ^5.4.1
  cloud_firestore: ^5.6.2
  mobile_scanner: ^6.0.4
  intl: ^0.19.0
```

---

## Firebase Console Setup Checklist

1. **Create Firebase Project**: Name `farmer-dost-app`.
2. **Add Android App**: Package name `com.farmerdost.app`.
3. **Download Configuration**:
   - Place `google-services.json` in `android/app/google-services.json`.
   - Place `GoogleService-Info.plist` in `ios/Runner/GoogleService-Info.plist` (for iOS builds).
4. **Enable Firebase Authentication**:
   - Enable **Phone** sign-in method.
   - Enable **Email/Password** sign-in method.
5. **Create Cloud Firestore Database**:
   - Mode: Production mode or Test mode.
   - Collections: `products`, `reports`, `users`, `scans`.

---

## Native Permissions Setup

### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSCameraUsageDescription</key>
<string>Farmer Dost requires camera access to scan fertilizer packaging QR codes.</string>
```
