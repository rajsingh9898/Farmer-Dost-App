# Day 15 — Firestore Database Schema Design & Architecture

## Overview
This document specifies the complete Cloud Firestore database schema for the **Farmer Dost App** (MVP for 20 sample products, ~50 test users). It defines document ID strategies, field definitions, indexes, queries, offline caching implications, security rules, and entity relationships.

---

## 1. Collection Specifications

### 1.1 `products` Collection (Genuine Product Registry)

- **Purpose**: Master database of authentic agricultural products (fertilizers and pesticides) registered by verified manufacturers or government regulatory authorities.
- **Top-Level Collection**: `/products/{code}`

#### a. Document ID Strategy
- **Strategy**: **Use the normalized QR/Barcode string itself as the Document ID** (e.g., `doc("KRIBHCO-UREA-2026-99A")` or `doc("GENUINE-123")`).
- **Senior Developer Reasoning**:
  1. **Direct Point Lookup ($O(1)$)**: The scanner calls `db.collection('products').doc(scannedCode).get()`. This avoids running an indexed `where('code', '==', code)` query.
  2. **Cost & Latency**: A direct document read costs exactly 1 read operation and executes in single-digit milliseconds without index traversal overhead.
  3. **Guaranteed Uniqueness**: Prevents duplicate product codes from ever existing in the database at the Firestore storage engine level.
  4. **Deterministic Offline Cache Key**: When caching for offline verification, querying by doc ID hits the local SQLite cache with zero ambiguity.

#### b. Fields & Data Types
| Field Name | Type | Required? | Description / Constraints |
| :--- | :--- | :---: | :--- |
| `code` | `string` | **Yes** | Primary product QR string (mirrors document ID for query convenience). |
| `name` | `string` | **Yes** | Full commercial product name (e.g. `"KRIBHCO Neem Coated Urea 50kg"`). |
| `manufacturer` | `string` | **Yes** | Licensed brand or cooperative (e.g. `"Krishak Bharati Cooperative Ltd"`). |
| `batch` | `string` | **Yes** | Manufacturing batch identifier (e.g. `"BATCH-2026-99A"`). |
| `type` | `string` | **Yes** | Category enum: `"fertilizer"` \| `"pesticide"`. |
| `status` | `string` | **Yes** | Verification state enum: `"active"` \| `"recalled"` \| `"expired"`. |
| `manufactureDate`| `timestamp` | **Yes** | Date of production. |
| `expiryDate` | `timestamp` | **Yes** | Official expiry timestamp (used to flag expired products even if code is authentic). |
| `createdAt` | `timestamp` | **Yes** | Document creation server timestamp. |
| `dosage` *(Recommended)* | `string` | *Optional* | Short farmer advisory (e.g. `"2 bags per acre for wheat"`). |

#### c. Realistic Sample Document
```json
// Path: /products/GENUINE-123
{
  "code": "GENUINE-123",
  "name": "KRIBHCO Neem Coated Urea 50kg",
  "manufacturer": "Krishak Bharati Cooperative Ltd",
  "batch": "BATCH-2026-99A",
  "type": "fertilizer",
  "status": "active",
  "manufactureDate": "2026-03-15T00:00:00.000Z",
  "expiryDate": "2028-03-14T23:59:59.000Z",
  "createdAt": "2026-03-16T10:00:00.000Z",
  "dosage": "45-50 kg per acre during first irrigation"
}
```

#### d. App Queries & Indexing
1. **Product Verification**:
   ```dart
   db.collection('products').doc(scannedCode).get();
   ```
   *Indexes needed*: None (built-in document ID index).
2. **Bulk Cache Sync (Phase 5 Offline Mode)**:
   ```dart
   db.collection('products').where('status', isEqualTo: 'active').get();
   ```
   *Indexes needed*: Single-field automatic index on `status`.

---

### 1.2 `reports` Collection (Counterfeit Product Incident Reports)

- **Purpose**: Farmer-submitted reports flagging fake, suspicious, or unrecognized packages.
- **Top-Level Collection**: `/reports/{reportId}`

#### a. Document ID Strategy
- **Strategy**: **Firestore Auto-generated ID** (e.g., `db.collection('reports').add(...)` -> `rpt_7xK9...`).
- **Senior Developer Reasoning**:
  Multiple farmers can scan and report the exact same counterfeit barcode. Using an auto-generated push ID allows multiple independent reports for the same product code without write collisions or overwrites.

#### b. Fields & Data Types
| Field Name | Type | Required? | Description / Constraints |
| :--- | :--- | :---: | :--- |
| `productCode` | `string` | **Yes** | The scanned barcode or manually entered code that triggered the report. |
| `userId` | `string` | **Yes** | Submitting farmer's Firebase Auth UID. |
| `location` | `geopoint` | *Optional* | GPS coordinates (`GeoPoint(lat, lng)`) or `null` if location disabled. |
| `note` | `string` | *Optional* | Farmer comments (max 100 characters; e.g. `"Purchased from Sharma Krishi Kendra"`). |
| `status` | `string` | **Yes** | Review lifecycle: `"pending"` \| `"reviewed"` \| `"confirmed"`. Defaults to `"pending"`. |
| `timestamp` | `timestamp` | **Yes** | Server timestamp of report submission (`FieldValue.serverTimestamp()`). |
| `resolvedAt` | `timestamp` | *Optional* | Timestamp when an admin/moderator reviewed the report. |

#### c. Realistic Sample Document
```json
// Path: /reports/rpt_88dFa29kL
{
  "productCode": "FAKE-456",
  "userId": "usr_harpreet_9898",
  "location": {
    "_latitude": 30.9010,
    "_longitude": 75.8573
  },
  "note": "Bag print was faded and seller did not give tax invoice.",
  "status": "pending",
  "timestamp": "2026-10-24T15:30:00.000Z",
  "resolvedAt": null
}
```

#### d. App Queries & Indexing
1. **Submit Report**:
   ```dart
   db.collection('reports').add(reportData);
   ```
2. **Admin Dashboard / Investigator Query (Reports by status ordered by time)**:
   ```dart
   db.collection('reports')
     .where('status', isEqualTo: 'pending')
     .orderBy('timestamp', descending: true);
   ```
   *Composite Index needed*:
   - Collection: `reports`
   - Fields: `status` (ASCENDING), `timestamp` (DESCENDING)

---

### 1.3 `users` Collection (Farmer Accounts)

- **Purpose**: Stores profile details, phone numbers, and language preferences for farmers.
- **Top-Level Collection**: `/users/{uid}`

#### a. Document ID Strategy
- **Strategy**: **Firebase Auth UID** (`FirebaseAuth.instance.currentUser.uid`).
- **Senior Developer Reasoning**:
  Creates a strict 1-to-1 relationship between authentication and database record. Fetching a profile is a direct `doc(auth.currentUser.uid).get()` lookup. It also simplifies security rules to `request.auth.uid == userId`.

#### b. Fields & Data Types
| Field Name | Type | Required? | Description / Constraints |
| :--- | :--- | :---: | :--- |
| `name` | `string` | **Yes** | Farmer's display name (e.g. `"Raj Singh"`). |
| `phone` | `string` | **Yes** | Normalized E.164 phone number (e.g. `"+919876543210"`). |
| `language` | `string` | **Yes** | ISO language code for localization: `"en"` \| `"hi"` \| `"pa"`. Default `"en"`. |
| `createdAt` | `timestamp` | **Yes** | Account registration timestamp. |
| `district` *(Recommended)* | `string` | *Optional* | Farmer's district / state (e.g. `"Ludhiana, Punjab"`). |

#### c. Realistic Sample Document
```json
// Path: /users/usr_harpreet_9898
{
  "name": "Raj Singh",
  "phone": "+919876543210",
  "language": "hi",
  "createdAt": "2026-09-01T08:00:00.000Z",
  "district": "Ludhiana"
}
```

#### d. App Queries & Indexing
1. **Fetch Profile on Login / Profile Screen**:
   ```dart
   db.collection('users').doc(authUid).get();
   ```
   *Indexes needed*: None (Direct document lookup).

---

### 1.4 `scans` Collection (Verification Audit Log)

- **Purpose**: Historical audit trail recording every verification attempt made by every farmer.
- **Structure Decision**: **Top-Level `/scans/{scanId}`** *(Recommended for this app)*.

#### a. Document ID Strategy
- **Strategy**: **Firestore Auto-generated ID** (`db.collection('scans').add(...)`).
- **Senior Developer Reasoning**:
  A single user will scan multiple products over weeks, and different users can scan the same product. Auto IDs give append-only logs without key collisions.

#### b. Fields & Data Types
| Field Name | Type | Required? | Description / Constraints |
| :--- | :--- | :---: | :--- |
| `userId` | `string` | **Yes** | The UID of the farmer who initiated the scan. |
| `productCode` | `string` | **Yes** | The scanned barcode string. |
| `result` | `string` | **Yes** | Outcome enum: `"genuine"` \| `"fake"` \| `"unrecognized"`. |
| `productName` | `string` | *Optional* | Denormalized product name (e.g. `"KRIBHCO Neem Coated Urea 50kg"`). |
| `timestamp` | `timestamp` | **Yes** | Server timestamp of scan. |

#### c. Realistic Sample Document
```json
// Path: /scans/scn_4M89xZ10
{
  "userId": "usr_harpreet_9898",
  "productCode": "GENUINE-123",
  "result": "genuine",
  "productName": "KRIBHCO Neem Coated Urea 50kg",
  "timestamp": "2026-10-24T15:28:10.000Z"
}
```

#### d. App Queries & Indexing
1. **Fetch Farmer's Scan History (Newest first, limit 20)**:
   ```dart
   db.collection('scans')
     .where('userId', isEqualTo: currentUserId)
     .orderBy('timestamp', descending: true)
     .limit(20);
   ```
   *Composite Index needed*:
   - Collection: `scans`
   - Fields: `userId` (ASCENDING), `timestamp` (DESCENDING)

---

## 2. Top-Level Collection vs. Subcollection: `/scans` vs `/users/{uid}/scans`

### The Decision:
Use **Top-Level `/scans`** with `userId` indexed.

| Metric | Top-Level `/scans` | Subcollection `/users/{uid}/scans` |
| :--- | :--- | :--- |
| **User History Query** | Simple `where('userId', '==', uid).orderBy('timestamp')` | Direct `collection('users').doc(uid).collection('scans').orderBy(...)` |
| **Counterfeit Hotspot Analysis** | Easy: `where('productCode', '==', 'FAKE-123')` across all farmers | Requires `collectionGroup('scans')` with cross-collection indexing |
| **Admin Fraud Monitoring** | Single query across recent scans across India | Difficult without collectionGroup rules and indexes |
| **Security Rules** | `allow read: if request.auth.uid == resource.data.userId;` | `allow read: if request.auth.uid == uid;` |
| **Firestore Limits** | Unlimited documents across collection | 1 write/sec recommended per single document hierarchy |

**Senior Dev Verdict**:
For an authenticity verification platform, **fraud detection is an aggregate problem**, not just a single-user problem. Agricultural departments need to see *"How many people scanned FAKE-456 today?"*. Keeping `scans` at the top level makes aggregate queries straightforward while requiring only one simple composite index for user history.

---

## 3. Entity Relationship Diagram

```text
  +-----------------------------------------------------------+
  |                        users (Collection)                 |
  |  Doc ID: {userId} (Firebase Auth UID)                     |
  |  - name: string                                           |
  |  - phone: string                                          |
  |  - language: string ("en" | "hi" | "pa")                  |
  |  - createdAt: timestamp                                   |
  +-----------------------------------------------------------+
         |                                           |
         | 1:N (owns)                                | 1:N (submits)
         v                                           v
  +--------------------------------+   +------------------------------------+
  |        scans (Collection)      |   |        reports (Collection)        |
  |  Doc ID: {autoId}              |   |  Doc ID: {autoId}                  |
  |  - userId: string  ------------+   |  - userId: string  ----------------+
  |  - productCode: string ------+     |  - productCode: string ------+
  |  - productName: string (denorm)    |  - location: GeoPoint        |
  |  - result: "genuine" | "fake"      |  - note: string              |
  |  - timestamp: timestamp            |  - status: "pending"         |
  +--------------------------------+   |  - timestamp: timestamp      |
                                 |     +------------------------------------+
                                 |                     |
                                 |                     | References
                                 +----------+----------+
                                            |
                                            v N:1
                               +------------------------------------+
                               |        products (Collection)       |
                               |  Doc ID: {code} (QR string)        |
                               |  - code: string                    |
                               |  - name: string                    |
                               |  - manufacturer: string            |
                               |  - batch: string                   |
                               |  - type: "fertilizer"|"pesticide"  |
                               |  - status: "active"|"recalled"     |
                               |  - manufactureDate: timestamp      |
                               |  - expiryDate: timestamp           |
                               |  - createdAt: timestamp            |
                               +------------------------------------+
```

---

## 4. Offline Caching Strategy (Phase 5 Preparation)

In rural farming belts (Punjab, Haryana, UP, MP), cellular network drops are normal. The schema supports offline operation:

1. **Products Collection Is Safe for Bulk Download**:
   * For the MVP with 20 sample products (or even 1,000 regional products in production), each product document is only **~300 bytes**.
   * 1,000 products = **~300 KB total payload** — smaller than a single low-res smartphone photo!
   * The entire active product catalog can be safely synced to Firestore's local cache on app launch.
2. **Keep Large Assets Out of Documents**:
   * **Do NOT store Base64 images** or certificate PDFs inside Firestore product docs. Store only strings, numbers, and timestamps.
   * If product packaging photos are added in future versions, store them in Cloud Storage and keep only the public CDN URL string (~80 bytes) in the document.
3. **Denormalization for Zero-Lookup History**:
   * `scans` stores `productName` directly. When the farmer opens their Scan History offline, the app reads entirely from the local `scans` cache without performing join queries to `products`.

---

## 5. Fields You Will Regret NOT Adding Now

Adding these optional fields now prevents breaking schema migrations later:

1. **`products.type` (`"fertilizer"` vs `"pesticide"`)**:
   Crucial because regulatory rules and banned chemical lists differ completely between fertilizers and insecticides/fungicides.
2. **`products.expiryDate`**:
   A counterfeit product is dangerous, but an **expired genuine product** whose chemicals degraded is equally dangerous to crops. Without `expiryDate`, expired products scan as "Genuine".
3. **`users.language`**:
   Rural Indian farmers rarely speak English. Adding `"hi"` (Hindi) or `"pa"` (Punjabi) language preference now means localization can be toggled without changing user documents.
4. **`reports.status`**:
   Without `"pending" | "reviewed" | "confirmed"`, you cannot build an admin queue or give the farmer feedback that their counterfeit report was handled by authorities.

---

## 6. Firestore Security Rules (Plain English Logic)

```text
1. products collection (/products/{code}):
   - READ: Public (any authenticated or anonymous farmer can read product details to verify authenticity).
   - WRITE: Strictly forbidden for farmers. Only backend admins or manufacturer CMS can create/edit products.

2. users collection (/users/{uid}):
   - READ: Allowed ONLY if the requesting user's Auth UID matches {uid}.
   - WRITE: Allowed ONLY if the requesting user's Auth UID matches {uid} (farmers can only edit their own name/phone/language).

3. scans collection (/scans/{scanId}):
   - CREATE: Allowed if the user is authenticated and request.resource.data.userId == request.auth.uid.
   - READ: Allowed ONLY if resource.data.userId == request.auth.uid (farmers cannot spy on other farmers' scans).
   - UPDATE / DELETE: Forbidden (audit scan logs are immutable).

4. reports collection (/reports/{reportId}):
   - CREATE: Allowed if authenticated and request.resource.data.userId == request.auth.uid, with note length <= 100 characters.
   - READ: Allowed for the user who filed it (or admin users).
   - UPDATE / DELETE: Admin-only (farmers cannot tamper with submitted incident reports).
```

---

## 7. College Project MVP Scope & Anti-Over-Engineering Audit

For a college demonstration project with **20 products and <50 users**, avoid these unnecessary complexities:

| Pattern | Verdict | Reason |
| :--- | :--- | :--- |
| **Algolia / Elasticsearch** | ❌ **Over-engineered** | Firestore direct document ID lookup `doc(code)` handles QR verification instantly. Full-text search is not needed for QR code lookups. |
| **Geohash Proximity Clusters** | ❌ **Over-engineered** | Storing a standard `GeoPoint(lat, lng)` is sufficient for demo pins. No need for complex spatial quad-trees. |
| **Distributed Counter Shards** | ❌ **Over-engineered** | With under 50 users, standard Firestore writes will never hit the 1 write/second document contention limit. |
| **Nested Subcollections for History** | ❌ **Over-engineered** | Top-level `/scans` with a single composite index is simpler, cleaner to inspect in the Firebase Console, and easily exportable. |
