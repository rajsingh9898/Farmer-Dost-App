# Day 28 — Backend Architecture Summary & Design Freeze

## 1. Executive Summary

The backend foundation for the **Farmer Dost App** is complete, tested, and locked for production. It combines:
- A cryptographic Python product code and QR generator (`backend/generate_codes.py`).
- Google Cloud Firestore & Firebase Authentication with strict least-privilege security rules (`firestore.rules`).
- A clean, decoupled Dart service layer (`lib/services/services.dart`) returning non-throwing structured result objects.
- A repeatable automated test suite with 100% pass rate across unit, integration, and End-to-End emulator tests.

---

## 2. Inventory of Backend Deliverables

### A. Firestore Collections & Schema Contracts
| Collection | Document ID | Key Fields | Access Constraints |
| :--- | :--- | :--- | :--- |
| **`products`** | QR Code string (e.g., `FD-FT-00101-GEN001`) | `code`, `name`, `manufacturer`, `batch`, `type`, `status` (`active`/`recalled`/`expired`), `manufactureDate`, `expiryDate`, `createdAt` | **Get only** by authenticated users. Writes disallowed from client apps. |
| **`users`** | Firebase Auth UID (`request.auth.uid`) | `name`, `phone`, `language`, `email`, `district`, `createdAt` | Owner read/create/update. `createdAt` is immutable. |
| **`scans`** | Auto-generated Firestore ID | `userId`, `productCode`, `productName`, `result` (`genuine`/`recalled`/`expired`/`notRecognized`), `timestamp` | Append-only by owner. Queries require composite index `(userId ASC, timestamp DESC)`. |
| **`reports`** | Deterministic `{uid}_{code}` | `productCode`, `userId`, `location` (GeoPoint/null), `note` (<=100 chars), `status` (`pending`), `timestamp` | Create-only by owner. Single report per user per product code. |

### B. Python Product Code & QR Generator
- **Location**: [`backend/generate_codes.py`](file:///c:/Users/Raj%20Singh/Desktop/Farmer-Dost-app/backend/generate_codes.py)
- **Features**:
  - `secrets` CSPRNG random generation.
  - 31-character unambiguous alphabet (excluding `0`, `O`, `1`, `I`, `L`).
  - Optional polynomial checksum toggle.
  - Batch CSV ingestion (`backend/products_input.csv`, 18 realistic Punjab agricultural products).
  - `--fake-only` mode generating 5 valid-format unregistered codes, 1 tampered code, and [`backend/qr_output/demo_qr_sheet.html`](file:///c:/Users/Raj%20Singh/Desktop/Farmer-Dost-app/backend/qr_output/demo_qr_sheet.html).

### C. Service Layer (`lib/services/`)
- Single barrel import: [`lib/services/services.dart`](file:///c:/Users/Raj%20Singh/Desktop/Farmer-Dost-app/lib/services/services.dart)
- All services enforce a 10-second rural network timeout (`kDefaultServiceTimeout`).
- Never throws raw exceptions or stack traces to the UI widgets:
  - `VerificationService.verifyProduct()` -> `VerificationResult`
  - `ReportService.submitReport()` -> `ReportResult`
  - `ProfileService.getProfile()` & `updateProfile()` -> `ProfileResult`
  - `ScanHistoryService.getScanHistory()` & `streamScanHistory()` -> `ScanHistoryResult`
  - `ServiceHelper.mapErrorToUserMessage()`

---

## 3. Operational Commands Guide

### Running Code Generation
```bash
# Seed 18 sample products to Firestore and generate QR codes
python backend/generate_codes.py --csv backend/products_input.csv

# Generate 5 fake demo codes and 1 tampered code with printable HTML sheet
python backend/generate_codes.py --fake-only
```

### Running Automated Test Suites
```bash
# Full test suite (all unit, integration, and E2E tests)
flutter test

# Specific subsystem tests
flutter test test/code_validation_test.dart
flutter test test/verification_integration_test.dart
flutter test test/report_service_test.dart
flutter test test/day26_services_test.dart
flutter test test/e2e_emulator_test.dart
```

### Running Local Firebase Emulators
```bash
# Start Firestore & Auth emulators
firebase emulators:start --only firestore,auth

# In separate terminal, seed test catalog & user
python backend/seed_emulator.py
```

---

## 4. Known Limitations & Architecture Trade-offs

1. **Client Read-Only Products**: Because security rules disable listing `/products` to prevent commercial scraping, the app performs single-document lookups (`/products/{code}`).
2. **Offline Mode**: When completely offline without cached documents, verification cleanly surfaces `VerificationStatus.networkError` rather than guessing.
3. **Deterministic Report ID**: Using `{uid}_{productCode}` prevents duplicate counterfeit reports, preventing database spam while giving farmers clear confirmation that their report is already logged.
4. **Composite Index Required**: `scans` queries require `scans (userId ASC, timestamp DESC)` deployed via `firestore.indexes.json`.

---

## 5. Failing Items Audit

- **Current Failing Tests**: **0**
- **Passing Tests**: **78 / 78**
- **Analysis Status**: Clean (`flutter analyze` validated).

---

## 6. Design Freeze Checklist (Sign-Off Before Day 29 UI Wiring)

- [x] **Schema Freeze**: Document structures for `products`, `users`, `scans`, and `reports` are locked.
- [x] **Model Contracts**: All data models (`Product`, `UserModel`, `ScanModel`, `ReportResult`, `VerificationResult`) are finalized.
- [x] **Service Layer Freeze**: All 5 services (`AuthService`, `VerificationService`, `ReportService`, `ProfileService`, `ScanHistoryService`) exposed via `services.dart`.
- [x] **Security Rules Signed Off**: `firestore.rules` verified with least privilege.
- [x] **Emulator & Seeder Ready**: `firebase.json` and `backend/seed_emulator.py` validated.
- [x] **Green Light for Day 29 UI Wiring**: Proceed to wire `ScanScreen`, `ResultScreen`, `ReportScreen`, `HomeScreen`, and `ProfileScreen`.
