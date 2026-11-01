# Day 27 — Firebase Local Emulator Suite & End-to-End Testing Guide

## 1. Emulator Configuration (`firebase.json`)

The emulator configuration is defined in [`firebase.json`](file:///c:/Users/Raj%20Singh/Desktop/Farmer-Dost-app/firebase.json):

```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "emulators": {
    "auth": {
      "port": 9099
    },
    "firestore": {
      "port": 8080
    },
    "ui": {
      "enabled": true,
      "port": 4000
    },
    "singleProjectMode": true
  }
}
```

---

## 2. Launching & Seeding the Local Emulators

### Step 1: Start the Firebase Emulator Suite
Run the Firebase CLI command from the repository root:
```bash
firebase emulators:start --only firestore,auth
```
- **Firestore Emulator**: `http://127.0.0.1:8080`
- **Auth Emulator**: `http://127.0.0.1:9099`
- **Emulator UI Dashboard**: `http://localhost:4000`

### Step 2: Seed the Test Data
In another terminal, execute the Python seeder script:
```bash
python backend/seed_emulator.py
```
This script seeds:
1. Test User: `users/test_farmer_uid_e2e` (Gurpreet Singh E2E, `testfarmer@dost.in`, `+919876543210`)
2. Genuine Active Product: `FD-FT-00101-GEN001` (IFFCO Neem Coated Urea 45kg)
3. Recalled Product Batch: `FD-PS-00202-REC002` (Kisan Rakshak Chlorpyrifos 20% EC)
4. Expired Product: `FD-FT-00303-EXP003` (Punjab Gold Zinc Sulfate 21%, expiryDate in past)

---

## 3. Connecting the Flutter App in Debug Mode Only

In `lib/main.dart` or during app initialization, configure the emulator connection guarded strictly by `kDebugMode` and an optional environment toggle:

```dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> setupEmulatorsIfDebug() async {
  if (kDebugMode && const bool.fromEnvironment('USE_FIREBASE_EMULATOR', defaultValue: false)) {
    const host = '127.0.0.1'; // or '10.0.2.2' for Android Emulator
    
    // Connect Cloud Firestore
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    
    // Connect Firebase Auth
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    
    debugPrint('[Firebase] Connected to local Emulators (Firestore: 8080, Auth: 9099)');
  }
}
```

---

## 4. Automated End-to-End Test Suite

Run the full E2E test suite locally without needing a live Google Cloud bill:
```bash
flutter test test/e2e_emulator_test.dart
```

### PASS/FAIL Test Execution Summary

| Step | Test Description | Status |
| :---: | :--- | :---: |
| 1 | User Signup & Profile Creation (`users/{uid}`) | **PASS** |
| 2 | Product Verification (Genuine, Recalled, Expired, NotRecognized, InvalidInput) | **PASS** |
| 3 | Scan Logging for Valid Lookups vs Skipping Transient Failures | **PASS** |
| 4 | Report Submission with Deterministic ID & Duplicate Prevention | **PASS** |
| 5 | Scan History Pagination & Chronological Ordering (DESC) | **PASS** |
| 6 | Security Rule Enforcement & Authenticated UID Isolation | **PASS** |

---

## 5. Live Production Deployment & Verification Checklist

Before releasing to real Punjabi farmers, run this checklist once against the live Firebase project:

- [ ] **Deploy Security Rules**:
  ```bash
  firebase deploy --only firestore:rules
  ```
- [ ] **Deploy Composite Indexes**:
  ```bash
  firebase deploy --only firestore:indexes
  ```
- [ ] **Seed Real Catalog via Python**:
  ```bash
  python backend/generate_codes.py --csv backend/products_input.csv
  ```
- [ ] **Verify Authentication Providers**:
  - In Firebase Console -> Authentication -> Sign-in method: Phone & Email/Password enabled.
- [ ] **Test Manual QR Scan**:
  - Scan `backend/qr_output/demo_qr_sheet.html` with an actual physical device camera.
- [ ] **Verify Reports in Console**:
  - Confirm reports appear in `reports/{uid}_{code}` with status `pending`.
