# Day 20 — Repeatable Test Suite & Risk Mitigation Guide

> **Farmer Dost App** — Comprehensive Verification Engine Test Suite  
> Target Files: `lib/services/verification_service.dart`, `test/code_validation_test.dart`, `test/verification_integration_test.dart`

---

## 1. Test Architecture Overview

The Day 20 test suite establishes a fast, hermetic, and repeatable testing pipeline split across two tiers:

```
┌────────────────────────────────────────────────────────────────────────┐
│                   TIER 1: PURE UNIT TESTS (test/code_validation_test.dart)                   │
├────────────────────────────────────────────────────────────────────────┤
│ • Zero Firebase dependency (no network, no mock Firestore, 100% offline).             │
│ • Tests standalone `normalizeAndValidate()` function across 24 table-driven vectors.    │
│ • Validates case conversion, whitespace trimming, regex boundary limits, injections.   │
└────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│             TIER 2: FIRESTORE INTEGRATION (test/verification_integration_test.dart)         │
├────────────────────────────────────────────────────────────────────────┤
│ • In-memory `fake_cloud_firestore` (hermetic, zero network latency, instant run).       │
│ • Seeds genuine, recalled, and expired product documents.                              │
│ • Tests direct document resolution, status routing, and scan history audit logging.   │
│ • Simulates network dropouts (unavailable) and timeouts via dependency injection.      │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Minimal Changes Needed to Inject Firestore

To allow tests to inject `FakeFirebaseFirestore` or exception mocks without affecting production, `verifyProduct` accepts an optional `FirebaseFirestore? firestore` parameter:

```dart
Future<VerificationResult> verifyProduct(
  String rawCode, {
  FirebaseFirestore? firestore,
  Duration? timeoutDuration,
}) async {
  // 1. Validation happens BEFORE resolving database
  final String? normalizedCode = normalizeAndValidate(rawCode);
  if (normalizedCode == null) {
    return VerificationResult.invalidInput(...);
  }

  // 2. Injected Firestore instance or production default
  final db = firestore ?? _firestore;
  if (db == null) {
    return VerificationResult.networkError(...);
  }

  final timeout = timeoutDuration ?? this.timeoutDuration;
  final docSnapshot = await db.collection('products').doc(normalizedCode).get().timeout(timeout);
  ...
}
```

---

## 3. Risk Analysis & Verification Checklist

| Risk Scenario | Handled? | Implementation & Defense Mechanism |
| :--- | :---: | :--- |
| **Uppercase / Lowercase mismatch** | **YES** | Cloud Firestore document IDs are case-sensitive. `normalizeAndValidate()` calls `.toUpperCase()` prior to querying. Lowercase scans (`"fd-ft-00123-a7x9km"`) match uppercase document IDs (`"FD-FT-00123-A7X9KM"`). |
| **Slash `/` passed to `.doc()`** | **YES** | In Firestore client SDK, slashes split path segments into subcollections (`/products/a/b/c`), throwing runtime errors. The regex `^FD-(FT|PS)-\d{5}-[A-Z0-9]{6,12}$` strictly rejects slashes and backslashes before Firestore is contacted. |
| **10-Second Timeout Firing** | **YES** | Weak rural connections can hang indefinitely. `.get().timeout(timeout)` triggers a `TimeoutException`, which is caught and returned as `VerificationStatus.networkError`. |
| **`logScan` skipping transient errors** | **YES** | `logScan` checks `if (result.status == VerificationStatus.networkError || result.status == VerificationStatus.invalidInput) return;`. Scans collection is never polluted with typo garbage or network drops. |

---

## 4. Commands to Run Tests

```bash
# 1. Run Pure Unit Tests (Table-Driven Normalization & Format)
flutter test test/code_validation_test.dart

# 2. Run Firestore Integration Tests (Fake Cloud Firestore)
flutter test test/verification_integration_test.dart

# 3. Run Entire App Test Suite
flutter test

# 4. Verify Code Cleanliness & Static Analysis
flutter analyze
```
