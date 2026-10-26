# Day 19 — Core Verification Service Architecture Guide

> **Farmer Dost App** — Agricultural Authenticity Verification Engine  
> Target Files: `lib/services/verification_service.dart` & `lib/models/verification_result.dart`

---

## 1. Architectural Design Overview

The verification engine provides rapid authenticity verification for farmers in rural fields with weak connectivity (2G/3G/intermittent). It follows a **3-tier verification pipeline**:

```
[QR Code Scanned]
       │
       ▼
[Tier 1: Pre-Firestore Sanitization & Format Validation]
   ├── Normalization: Trim whitespace & uppercase
   ├── Regex Check: ^FD-(FT|PS)-\d{5}-[A-Z0-9]{6,}$
   └── If Invalid ──► Returns VerificationStatus.invalidInput (Zero Firestore cost)
       │ (Valid format)
       ▼
[Tier 2: Direct Document Key Lookup (O(1))]
   ├── doc(code).get() with 10-second rural timeout
   ├── Document does not exist? ──► VerificationStatus.notRecognized (Counterfeit alert)
   ├── Status == "recalled"?   ──► VerificationStatus.recalled (Safety alert)
   ├── ExpiryDate < Now?       ──► VerificationStatus.expired (Chemical warning)
   └── Active & Valid?         ──► VerificationStatus.genuine
       │
       ▼
[Tier 3: Decoupled Failure-Tolerant Audit Logging]
   ├── logScan(result) triggered in background
   ├── Records userId, productCode, productName, status, serverTimestamp to /scans
   ├── Skips transient states (invalidInput, networkError)
   └── Failures are non-fatal (never blocks UI or crashes app)
```

---

## 2. Why Direct Document Lookup is Superior to `where()` Queries

When architecting Cloud Firestore for high-scale mobile apps, using the QR code string as the document ID (`/products/{code}`) provides decisive advantages over `where('code', '==', code)`:

| Dimension | `doc(code).get()` (Direct Lookup) | `collection('products').where(...)` |
| :--- | :--- | :--- |
| **Lookup Complexity** | **$O(1)$** direct hash / partition key lookup | **$O(\log N)$** B-tree index traversal |
| **Network Latency** | Minimal round-trip payload (direct fetch from Cloud Spanner / Bigtable) | Higher latency (query planning + index scan + doc fetch) |
| **Offline Cache Behavior** | **Instant hit**: Local persistence indexes docs by primary key (`/products/{code}`). Resolves immediately offline. | Local cache must execute client-side query filter, which can fail or miss unindexed records. |
| **Cost & Billable Operations** | Exactly 1 read. Zero composite index write costs on batch insertions. | 1 read + requires maintaining field index for every inserted product document. |
| **Security Rules Alignment** | Clean, fast rules matching: `match /products/{code}`. | Requires verifying query constraints in rules. |
| **Collision Protection** | **Guaranteed uniqueness** at the database engine level (document IDs are inherently unique). | `where()` allows duplicate codes if batch inserts ever create duplicates. |

---

## 3. Pre-Firestore Validation (Security & Crash Prevention)

The pre-validation regex:
```dart
final RegExp _kProductCodeRegex = RegExp(r'^FD-(FT|PS)-\d{5}-[A-Z0-9]{6,}$');
```

### Why this is critical:
1. **Prevents Slash `/` Path Breakage**: In Cloud Firestore, passing a string with a forward slash (e.g. `doc('FD/FT/123')`) causes the SDK to interpret the string as a subcollection path (`/products/FD/FT/123`), resulting in runtime errors or invalid document references.
2. **Rejects Foreign URLs**: Many QR codes on consumer packaging are generic website URLs (`https://...`). The regex instantly discards them as `invalidInput` without wasting a billable Firestore read.
3. **Stops NoSQL Injection & Extreme Payloads**: Prevents huge string scans or malicious payloads from hitting Firestore quotas.
4. **Zero-Latency Feedback**: Invalid scans fail in $< 1\text{ms}$ locally on the device.

---

## 4. Verification Status Model

```dart
enum VerificationStatus {
  genuine,        // Verified active product in registry
  recalled,       // Batch recalled by manufacturer
  expired,        // Past chemical efficacy expiration date
  notRecognized,  // Format matched but not found in registry (Counterfeit alert)
  invalidInput,   // Failed pre-validation (malformed QR, URL, empty)
  networkError,   // Connection timeout (10s), socket error, or server unavailable
}
```

---

## 5. Failure-Tolerant Scan Logging (`logScan`)

The `logScan` method is strictly separated from `verifyProduct`:
- **Independent Execution**: A failure to write to the `scans` collection (e.g. temporary write lock or auth timeout) **never** blocks displaying the verification outcome to the farmer.
- **Noise Filtering**: Transient states (`networkError` and `invalidInput`) are deliberately excluded from the audit log to keep analytics and scan history clean.
- **Denormalization**: Stores `productName` directly on the scan document so the Farmer History screen can render without executing expensive $N+1$ product joins.
