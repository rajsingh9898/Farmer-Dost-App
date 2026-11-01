# Day 26 — Service Layer Architecture & API Reference

## 1. Service Layer Directory Structure

```
lib/
├── models/
│   ├── product_model.dart       # Product domain entity (code, name, batch, type, status, dates)
│   ├── report_model.dart        # Report domain entity (code, userId, location, note, status)
│   ├── report_result.dart       # Structured non-throwing ReportResult & ReportStatus enum
│   ├── scan_model.dart          # Scan record entity (userId, productCode, productName, result, timestamp)
│   ├── user_model.dart          # Farmer profile entity (uid, name, phone, language, district, createdAt)
│   └── verification_result.dart # Structured VerificationResult & VerificationStatus enum
│
├── services/
│   ├── services.dart            # SINGLE BARREL EXPORT: one import for all services and models
│   ├── service_helper.dart      # Shared error mapping, timeouts, and exception classifiers
│   ├── auth_service.dart        # Authentication, phone OTP, email/pass, authStateChanges
│   ├── verification_service.dart# Code validation, Firestore verification, scan logging
│   ├── report_service.dart      # Counterfeit/defect reporting with deterministic deduplication
│   ├── profile_service.dart     # User profile fetching, missing profile auto-creation, update
│   └── scan_history_service.dart# Paginated user scan logs with composite index query
```

---

## 2. Public Function Signatures & API Reference

| Service | Method | Return Type | Key Parameters | Description |
| :--- | :--- | :--- | :--- | :--- |
| **`VerificationService`** | `verifyProduct()` | `Future<VerificationResult>` | `String rawCode, {Duration? timeoutDuration}` | Normalizes and validates QR code format locally, checks Firestore `products` collection, verifies status & expiry date, logs scan asynchronously. |
| **`VerificationService`** | `normalizeAndValidate()` | `String?` | `String raw` | Pure static validator returning uppercase normalized code or null if invalid. |
| **`VerificationService`** | `logScan()` | `Future<void>` | `String rawCode, VerificationResult result` | Logs non-transient verification outcomes to `scans` collection with server timestamp. |
| **`ReportService`** | `submitReport()` | `Future<ReportResult>` | `required String productCode, GeoPoint? location, String? note` | Submits farmer report using deterministic ID `{uid}_{code}` preventing duplicates. Enforces 100 char max note. |
| **`ProfileService`** | `getProfile()` | `Future<ProfileResult>` | `{String? uid, bool createIfMissing = true}` | Fetches farmer profile from `users/{uid}`. Auto-creates doc with server timestamp if missing. |
| **`ProfileService`** | `updateProfile()` | `Future<ProfileResult>` | `{String? name, String? phone, String? language, String? district, String? email}` | Updates profile while strictly preserving immutable `createdAt`. |
| **`ScanHistoryService`** | `getScanHistory()` | `Future<ScanHistoryResult>` | `{int limit = 20, DocumentSnapshot? startAfter}` | Paginated query on `scans` where `userId == currentUid`, ordered by `timestamp` DESC. |
| **`ScanHistoryService`** | `streamScanHistory()`| `Stream<List<ScanModel>>` | `{int limit = 10}` | Real-time reactive stream of user scans for home screen dashboard. |
| **`AuthService`** | `signInWithEmailAndPassword()` | `Future<UserCredential?>` | `String email, String password` | Authenticates existing user with error mapping. |
| **`AuthService`** | `signUpWithEmailAndPassword()` | `Future<UserCredential?>` | `String email, String password, {String? displayName}` | Creates account and seeds initial profile doc. |
| **`AuthService`** | `signOut()` | `Future<void>` | None | Cleans up user session. |
| **`ServiceHelper`** | `mapErrorToUserMessage()`| `String` | `Object error` | Translates timeouts and FirebaseExceptions into farmer-friendly UI strings. |

---

## 3. Cloud Firestore Composite Index Specification

For **`ScanHistoryService`**, queries filtering by `userId` and sorting by `timestamp DESC` require a composite index:

- **Collection ID**: `scans`
- **Fields**:
  1. `userId` (Ascending)
  2. `timestamp` (Descending)
- **Query Scope**: `Collection`

---

## 4. Single-Import Usage for UI Screens

Every UI screen imports only one file:

```dart
import 'package:farmer_dost_app/services/services.dart';
```

No raw exceptions will ever reach widgets — all service operations return structured, non-throwing response objects (`VerificationResult`, `ReportResult`, `ProfileResult`, `ScanHistoryResult`).
