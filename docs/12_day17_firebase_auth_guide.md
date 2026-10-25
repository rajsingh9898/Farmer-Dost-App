# Day 17 — Firebase Authentication, User Document Sync & Failure Diagnosis

This guide documents the implementation of Firebase Authentication for the **Farmer Dost App**, covering Email/Password registration, Phone OTP verification, Firestore profile synchronization at `users/{uid}`, error message mapping, and failure troubleshooting.

---

## 1. Authentication Architecture Overview

```text
  +------------------------------------------------------------------------+
  |                              User Enters App                           |
  +------------------------------------------------------------------------+
                                      |
                                      v
  +------------------------------------------------------------------------+
  |                   SplashScreen (2-second branding)                     |
  +------------------------------------------------------------------------+
                                      |
                                      v
  +------------------------------------------------------------------------+
  |              AuthGate: StreamBuilder<User?>(authStateChanges)          |
  +------------------------------------------------------------------------+
                 |                                          |
        Logged In (user != null)                   Logged Out (user == null)
                 v                                          v
  +-----------------------------+            +-----------------------------+
  |         HomeScreen          |            |         LoginScreen         |
  |  - Hero Scan CTA            |            |  - Email / Password Login   |
  |  - Quick Actions            |            |  - New Account Sign Up      |
  |  - Profile Screen -> Logout |            |  - Phone OTP Verification   |
  +-----------------------------+            +-----------------------------+
```

---

## 2. Core Service Implementation: `AuthService`

Located in [`lib/services/auth_service.dart`](file:///c:/Users/Raj%20Singh/Desktop/Farmer-Dost-app/lib/services/auth_service.dart):

### 2.1 `signUpWithEmail(name, email, password)`
- **Step 1**: Creates the user credential via `FirebaseAuth.instance.createUserWithEmailAndPassword()`.
- **Step 2**: Updates the user's `displayName` in Firebase Auth.
- **Step 3**: Creates the document at `users/{uid}` with:
  ```json
  {
    "name": "Harpreet Singh",
    "email": "farmer@example.com",
    "phone": null,
    "language": "en",
    "createdAt": "FieldValue.serverTimestamp()"
  }
  ```
- **Graceful Error Handling**: If the Firestore write fails (due to momentary connection drop or security rules latency), the account creation is not aborted. A warning is logged, and the user document is automatically created ("healed") on their next login via `_ensureUserDocumentExists()`.

### 2.2 `signInWithEmail(email, password)`
- Signs in existing user with `signInWithEmailAndPassword()`.
- Automatically calls `_ensureUserDocumentExists(credential.user!)` to heal any half-registered user states.

### 2.3 Phone OTP Flow
- **`sendOtp(phoneNumber, onCodeSent, onError)`**:
  - Uses `verifyPhoneNumber()`.
  - Normalizes numbers with `+91` prefix for Indian farmers.
  - Automatically triggers auto-retrieval on Android devices.
- **`verifyOtp(verificationId, smsCode)`**:
  - Validates submitted 6-digit code via `PhoneAuthProvider.credential()`.
  - On first phone sign-in, creates the `users/{uid}` document if not already existing.

### 2.4 `signOut()` & `authStateChanges`
- `signOut()`: Clears authentication tokens and local user session.
- `Stream<User?> get authStateChanges`: Stream listened to by `AuthGate` to reactively update the UI when the user signs in or out.

---

## 3. Farmer-Friendly Error Message Mapping

Technical Firebase error codes are automatically translated into intuitive, friendly messages:

| Firebase Error Code | Farmer-Friendly UI Message |
| :--- | :--- |
| `user-not-found` | *"No account found with this email. Please sign up."* |
| `wrong-password` | *"Incorrect password. Please try again."* |
| `invalid-credential` | *"Invalid email or password. Please check and try again."* |
| `email-already-in-use` | *"An account already exists with this email. Please log in."* |
| `weak-password` | *"Password is too weak. Please use at least 6 characters."* |
| `invalid-email` | *"Please enter a valid email address."* |
| `invalid-verification-code`| *"Incorrect OTP entered. Please check and try again."* |
| `invalid-verification-id` | *"OTP session expired. Please request a new code."* |
| `session-expired` | *"OTP has expired. Please request a new code."* |
| `invalid-phone-number` | *"Invalid phone number. Please enter a valid 10-digit mobile number."* |
| `too-many-requests` | *"Too many attempts. Please wait a few minutes and try again."* |
| `network-request-failed` | *"No internet connection. Please check your mobile data or Wi-Fi."* |
| `operation-not-allowed` | *"This sign-in method is not enabled. Please contact support."* |
| `user-disabled` | *"This account has been disabled. Please contact support."* |

---

## 4. Temporary Verification Script (`runDay17AuthVerification`)

Located in [`lib/services/auth_verifier.dart`](file:///c:/Users/Raj%20Singh/Desktop/Farmer-Dost-app/lib/services/auth_verifier.dart).

### How to Run:
Uncomment line 16 in [`lib/main.dart`](file:///c:/Users/Raj%20Singh/Desktop/Farmer-Dost-app/lib/main.dart):
```dart
import 'services/auth_verifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    // RUN AUTH VERIFICATION ON APP LAUNCH:
    await runDay17AuthVerification();
  } catch (e) { ... }
}
```

### Verification Flow:
1. **Signs in with test account** (`testfarmer@farmerdost.com` / `Password123!`), auto-creating it if not yet registered.
2. **Prints the UID** in the debug console.
3. **Reads `users/{uid}` in Firestore** and confirms document exists.
4. **Signs out** and verifies `currentUser == null`.
5. **Prints Summary**:
```text
======================================================
📊 DAY 17 AUTH VERIFICATION SUMMARY: ALL PASSED ✅
------------------------------------------------------
Step 1 (Sign In & Print UID):           PASS ✅
Step 2 (Read users/{uid} in Firestore): PASS ✅
Step 3 (Sign Out & Confirm Null):       PASS ✅
======================================================
```

---

## 5. Most Common Auth Failures & Diagnosis Guide

When building mobile authentication with Firebase, 95% of issues stem from 4 root causes:

### 1. Missing or Incorrect SHA-1 / SHA-256 Fingerprint
- **Symptom**: Phone Auth fails with `17010`, `app-not-authorized`, SafetyNet/Play Integrity verification failure, or app hangs during SMS dispatch.
- **Cause**: Google Play Integrity / reCAPTCHA requires the SHA-1 and SHA-256 keys of your development debug keystore registered in the Firebase console.
- **Diagnosis**: Terminal logs `[firebase_auth/unknown] [SmsRetrieverHelper]` or `App validation failed`.
- **How to Fix**:
  1. In terminal, navigate to `android/` directory and run:
     ```bash
     ./gradlew signingReport
     ```
  2. Copy the `SHA1` and `SHA-256` fingerprints for the `debug` variant.
  3. Go to **Firebase Console** -> **Project Settings** -> **Your apps** -> **Android App**.
  4. Click **Add fingerprint**, paste SHA-1, then add SHA-256.
  5. Download the updated `google-services.json` and replace `android/app/google-services.json`.

---

### 2. Wrong or Outdated `google-services.json`
- **Symptom**: App crashes on start with `Default FirebaseApp is not initialized in this process` or `Could not find google-services.json`.
- **Cause**: The `package_name` inside `google-services.json` does not match the `applicationId` in `android/app/build.gradle` (or project ID is different).
- **Diagnosis**: Look inside `android/app/google-services.json` at:
  ```json
  "client_info": {
    "android_client_info": {
      "package_name": "com.example.farmer_dost_app"
    }
  }
  ```
- **How to Fix**: Ensure `applicationId` in `android/app/build.gradle` matches the package name in Firebase console. Re-download and place file in `android/app/`.

---

### 3. Provider Not Enabled in Firebase Console
- **Symptom**: `FirebaseAuthException: [firebase_auth/operation-not-allowed] The given sign-in provider is disabled for this Firebase project.`
- **Cause**: Email/Password or Phone sign-in has not been toggled on in the Firebase Console.
- **Diagnosis**: The error code will explicitly be `operation-not-allowed`.
- **How to Fix**:
  1. Go to **Firebase Console** -> **Build** -> **Authentication** -> **Sign-in method**.
  2. Click **Email/Password** -> Toggle **Enable** -> Click **Save**.
  3. Click **Phone** -> Toggle **Enable** -> Add test phone numbers (e.g. `+91 9876543210` with code `123456`) -> Click **Save**.

---

### 4. No Internet or DNS Failure on Android Emulator
- **Symptom**: `FirebaseAuthException: [firebase_auth/network-request-failed] A network error (such as timeout, interrupted connection or unreachable host) has occurred.`
- **Cause**: Android emulator lost DNS routing to Google servers, or local machine is behind a proxy/VPN.
- **Diagnosis**: Open Chrome inside the Android emulator. If web pages fail to load, the emulator has no connectivity.
- **How to Fix**:
  1. Restart emulator with Cold Boot:
     In Android Studio Device Manager -> Click the three dots -> **Cold Boot Now**.
  2. Or specify Google DNS when launching emulator via CLI:
     ```bash
     emulator -avd <emulator_name> -dns-server 8.8.8.8
     ```
