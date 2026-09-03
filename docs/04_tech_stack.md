# Day 4 — Tech Stack Rationale & Architecture

## Core Technology Rationale

| Layer | Selected Tech | Rationale & Trade-offs |
|---|---|---|
| **Mobile Framework** | **Flutter (Dart)** | Single codebase targeting Android & iOS with native camera performance, fast hot reload, and rich UI customization. |
| **Backend & Auth** | **Firebase Auth** | Supports native Phone OTP (`verifyPhoneNumber`) out of the box — essential for rural farmers without email addresses — with Email fallback for testing. |
| **Database** | **Cloud Firestore** | NoSQL document database providing real-time synchronization, offline persistence capabilities, and fast queries for product lookup & scan history. |
| **Camera & QR Reading**| **`mobile_scanner`** | High-performance Flutter camera scanner plugin backed by Google ML Kit (Android) & AVFoundation (iOS). |
| **Timestamp & Formatting**| **`intl` package** | Formats scan timestamps for rural farmer readability (e.g. "Sep 03, 2026 • 10:30 AM"). |

---

## Data Model Schemas (Firestore)

### 1. `products` Collection
```json
{
  "code": "GENUINE-123",
  "name": "KRIBHCO Neem Coated Urea 50kg",
  "batch": "BATCH-2026-99A",
  "manufacturer": "Krishak Bharati Cooperative Ltd",
  "status": "genuine" // "genuine" | "fake" | "unrecognized"
}
```

### 2. `reports` Collection
```json
{
  "productCode": "FAKE-456",
  "userId": "user_uid_123",
  "location": "Khanna Mandi Shop #4",
  "note": "Bag seal was damaged and contents appeared diluted",
  "timestamp": "FieldValue.serverTimestamp()"
}
```

### 3. `users` Collection
```json
{
  "uid": "user_uid_123",
  "name": "Gurdev Singh",
  "phone": "+919876543210",
  "createdAt": "FieldValue.serverTimestamp()"
}
```

### 4. `scans` Collection
```json
{
  "userId": "user_uid_123",
  "productCode": "GENUINE-123",
  "productName": "KRIBHCO Neem Coated Urea 50kg",
  "result": "genuine",
  "timestamp": "FieldValue.serverTimestamp()"
}
```
