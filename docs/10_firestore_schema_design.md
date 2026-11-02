# Phase 3: Final Cloud Firestore Schema Design & Architecture

Authoritative specification of the Cloud Firestore database architecture for the **Farmer Dost App**. Designed for $O(1)$ direct point lookups, zero index-cost verification, append-only immutable audit trails, idempotent reporting, and rural offline cache persistence.

---

## 1. Core Architecture Decisions & Collections Matrix

| Collection | Document ID Strategy | Rationale & Defense | Primary Client Query | Indexing Needed |
| :--- | :--- | :--- | :--- | :---: |
| **`products`** | **Normalized QR Code**<br>(e.g. `FD-FT-00101-GEN001`) | Direct document get `doc(code)`. $O(1)$ complexity, zero composite index overhead, guaranteed uniqueness at the storage engine level. | `products.doc(scannedCode).get()` | None (Built-in primary key) |
| **`users`** | **Firebase Auth UID**<br>(e.g. `wK89xZ...`) | Strict 1-to-1 mapping with authentication record. Security rules enforce `request.auth.uid == userId`. | `users.doc(auth.uid).get()` | None (Built-in primary key) |
| **`scans`** | **Firestore Auto ID**<br>(e.g. `scn_78aB...`) | Append-only audit log. Farmers perform multiple scans over time; auto-ID prevents write collisions. | `scans.where('userId', '==', uid).orderBy('timestamp', descending: true).limit(20)` | **Composite Index**: `userId` (ASC) + `timestamp` (DESC) |
| **`reports`** | **Deterministic `${uid}_${productCode}`**<br>(e.g. `uid123_FD-PS-99999-FAKE01`) | Idempotent fraud reporting. Prevents the same user from spamming multiple reports for the same product code while allowing instant duplicate detection. | `reports.where('status', '==', 'pending').orderBy('timestamp', descending: true)` | **Composite Index**: `status` (ASC) + `timestamp` (DESC) |

---

## 2. Product Code Format Standard

All product QR codes adhere to the formal regular expression:
```regex
^FD-(FT|PS)-\d{5}-[A-Z0-9]{6,}$
```
- **Prefix**: `FD-` (Farmer Dost ecosystem namespace)
- **Product Category**: `FT` (Fertilizer) or `PS` (Pesticide)
- **Batch Serial**: 5-digit zero-padded serial (e.g., `00101`)
- **Cryptographic Entropy**: 6+ uppercase alphanumeric characters generated via Python `secrets` module (56+ bits of entropy) to prevent counterfeit sequential guessing.

---

## 3. Collection Specifications & Sample JSON

### 3.1 `products` Collection (`/products/{code}`)

Master registry of legitimate agricultural products registered by approved manufacturers and regulatory authorities.

#### Fields & Types
| Field | Type | Required | Description |
| :--- | :---: | :---: | :--- |
| `code` | `string` | **Yes** | Normalized QR string matching document ID. |
| `name` | `string` | **Yes** | Commercial brand name (e.g., `"IFFCO Neem Coated Urea 45kg"`). |
| `manufacturer` | `string` | **Yes** | Licensed enterprise (e.g., `"IFFCO Ltd."`). |
| `batch` | `string` | **Yes** | Manufacturing lot identifier (e.g., `"B-9021"`). |
| `type` | `string` | **Yes** | Category: `"fertilizer"` \| `"pesticide"`. |
| `status` | `string` | **Yes** | State: `"active"` \| `"recalled"` \| `"expired"`. |
| `manufactureDate` | `timestamp` | **Yes** | Production date. |
| `expiryDate` | `timestamp` | **Yes** | Expiration boundary (used to detect expired chemicals). |
| `createdAt` | `timestamp` | **Yes** | Registration server timestamp. |
| `dosage` | `string` | *Optional* | Farmer field application advisory. |

#### Sample Document JSON
```json
// Path: /products/FD-FT-00101-GEN001
{
  "code": "FD-FT-00101-GEN001",
  "name": "IFFCO Neem Coated Urea 45kg",
  "manufacturer": "IFFCO Ltd.",
  "batch": "B-9021",
  "type": "fertilizer",
  "status": "active",
  "manufactureDate": "2026-03-15T00:00:00.000Z",
  "expiryDate": "2028-03-14T23:59:59.000Z",
  "createdAt": "2026-03-16T10:00:00.000Z",
  "dosage": "45-50 kg per acre during first irrigation"
}
```

---

### 3.2 `users` Collection (`/users/{uid}`)

Stores farmer profile attributes and localization preferences.

#### Fields & Types
| Field | Type | Required | Description |
| :--- | :---: | :---: | :--- |
| `uid` | `string` | **Yes** | Firebase Auth UID. |
| `name` | `string` | **Yes** | Full display name (e.g., `"Gurpreet Singh"`). |
| `email` | `string` | *Optional* | Registered email address. |
| `phone` | `string` | **Yes** | Normalized phone number. |
| `language` | `string` | **Yes** | Language preference: `"en"` \| `"hi"` \| `"pa"`. Default `"en"`. |
| `district` | `string` | *Optional* | Region/Mandi (e.g., `"Ludhiana, Punjab"`). |
| `createdAt` | `timestamp` | **Yes** | Registration timestamp. |

#### Sample Document JSON
```json
// Path: /users/wK89xZ10aB72mN
{
  "uid": "wK89xZ10aB72mN",
  "name": "Gurpreet Singh",
  "email": "gurpreet.kisan@punjab.in",
  "phone": "+91 98765 43210",
  "language": "pa",
  "district": "Ludhiana",
  "createdAt": "2026-09-01T08:00:00.000Z"
}
```

---

### 3.3 `scans` Collection (`/scans/{scanId}`)

Append-only historical audit log of every product verification attempt.

#### Fields & Types
| Field | Type | Required | Description |
| :--- | :---: | :---: | :--- |
| `userId` | `string` | **Yes** | Auth UID of the verifying farmer. |
| `productCode` | `string` | **Yes** | Scanned product code string. |
| `productName` | `string` | *Optional* | Denormalized commercial name for zero-join offline history rendering. |
| `result` | `string` | **Yes** | Verification outcome: `"genuine"` \| `"fake"` \| `"recalled"` \| `"expired"` \| `"unrecognized"`. |
| `timestamp` | `timestamp` | **Yes** | Exact time of scan (`FieldValue.serverTimestamp()`). |

#### Sample Document JSON
```json
// Path: /scans/scn_88dFa29kL
{
  "userId": "wK89xZ10aB72mN",
  "productCode": "FD-FT-00101-GEN001",
  "productName": "IFFCO Neem Coated Urea 45kg",
  "result": "genuine",
  "timestamp": "2026-10-24T15:28:10.000Z"
}
```

---

### 3.4 `reports` Collection (`/reports/{reportId}`)

Farmer-submitted counterfeit, expired, or recalled product incident reports.

#### Fields & Types
| Field | Type | Required | Description |
| :--- | :---: | :---: | :--- |
| `productCode` | `string` | **Yes** | Scanned or manually entered fraudulent code. |
| `userId` | `string` | **Yes** | Submitting farmer's Auth UID. |
| `location` | `geopoint` | *Optional* | GPS coordinates (`GeoPoint(lat, lng)`) or `null`. |
| `note` | `string` | *Optional* | Field comments (max 100 characters). |
| `status` | `string` | **Yes** | Lifecycle: `"pending"` \| `"reviewed"` \| `"confirmed"`. Default `"pending"`. |
| `timestamp` | `timestamp` | **Yes** | Server timestamp of report submission. |

#### Sample Document JSON
```json
// Path: /reports/wK89xZ10aB72mN_FD-PS-99999-FAKE01
{
  "productCode": "FD-PS-99999-FAKE01",
  "userId": "wK89xZ10aB72mN",
  "location": {
    "_latitude": 30.9010,
    "_longitude": 75.8573
  },
  "note": "Purchased from unauthorized dealer in Khanna mandi. Liquid smells like kerosene.",
  "status": "pending",
  "timestamp": "2026-10-24T15:30:00.000Z"
}
```

---

## 4. Firestore Composite Indexes Specification

Firestore automatically builds single-field indexes for all fields. Only two composite indexes are required:

```json
{
  "indexes": [
    {
      "collectionGroup": "scans",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "reports",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    }
  ]
}
```

---

## 5. Offline Caching & Stale Data Implications

1. **Local Point Lookups ($O(1)$ Cache Hit)**:
   - When the device is offline, querying `products.doc(code).get()` checks the local SQLite cache created by Firestore offline persistence.
   - If the product was previously verified or seeded into local cache, verification succeeds with zero cellular signal.
2. **Denormalization for Zero-Join Offline History**:
   - `productName` is stored directly inside each `scans` document at verification time.
   - Reading scan history offline requires zero join queries to `products`, allowing instant rendering.
3. **The Stale-Data Risk**:
   - *Scenario*: Product `FD-FT-00777-RECALL` is marked `active` on Day 1. The farmer verifies it and caches it locally. On Day 3, the government recalls the batch in Cloud Firestore. If the farmer rescans on Day 4 in airplane mode, the local cache still says `active`!
   - *Technical Mitigation*: All offline verification results must display a prominent `"Verified Offline — Last synced [Timestamp]"` notice to alert the farmer that recall checks require cellular connectivity.
