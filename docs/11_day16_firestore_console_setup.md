# Day 16 — Firestore Console Setup, Test Data & Verification Guide

This guide provides the complete click-by-click instructions for setting up Cloud Firestore in the Firebase Console, inputting test documents with strict data types, creating composite indexes, and executing the verification script for the **Farmer Dost App**.

---

## PART 1 — Click-by-Click Firebase Console Setup

### Step 1.1: Create the Cloud Firestore Database
1. Open the [Firebase Console](https://console.firebase.google.com/) and select your project (`Farmer Dost App` / `rajsingh9898/Farmer-Dost-App`).
2. In the left navigation menu, navigate to **Build** -> **Firestore Database**.
3. Click the **Create database** button.
4. **Choose Security Mode**:
   - Select **Start in test mode** for initial Day 16 verification (this enables reads and writes during development).
   - *(Note: We will configure the precise 30-day expiration rules in Step 1.3).*
5. **Select Cloud Firestore Location (CRITICAL)**:
   - **Recommended Region for India**: **`asia-south1` (Mumbai)** or **`asia-south2` (Delhi)**.
   - ⚠️ **Permanent Decision Warning**: Once you select a region and create the database, **the location CANNOT be changed later**. Selecting `asia-south1` (Mumbai) or `asia-south2` (Delhi) guarantees lowest latency (~15–35ms) across rural Punjab, Haryana, UP, and northern agricultural belts.
6. Click **Enable** and wait 15–30 seconds while Firebase provisions your Firestore instance.

---

### Step 1.2: Create the 4 Collections & Add First Documents
In Firestore, a collection only exists when it contains at least one document. Create the 4 collections using the **Start collection** button:

#### 1. `products` Collection (QR Code as Document ID)
- Click **+ Start collection**.
- Collection ID: `products` -> Click **Next**.
- **Document ID**: Do NOT click "Auto-ID". Enter exact string: `FD-PB-00123-A7X9`.
- Add the fields (see [Section 2.1](#21-products-collection) for values):
  - `code` (Type: `string`)
  - `name` (Type: `string`)
  - `manufacturer` (Type: `string`)
  - `batch` (Type: `string`)
  - `type` (Type: `string`)
  - `status` (Type: `string`)
  - `manufactureDate` (Type: `timestamp`)
  - `expiryDate` (Type: `timestamp`)
  - `createdAt` (Type: `timestamp`)
  - `dosage` (Type: `string`)
- Click **Save**.

#### 2. `users` Collection (Auth UID as Document ID)
- Click **+ Start collection**.
- Collection ID: `users` -> Click **Next**.
- **Document ID**: Enter test UID: `usr_punjab_farmer_01`.
- Add fields (see [Section 2.2](#22-users-collection) for values):
  - `name` (Type: `string`)
  - `phone` (Type: `string`)
  - `language` (Type: `string`)
  - `district` (Type: `string`)
  - `createdAt` (Type: `timestamp`)
- Click **Save**.

#### 3. `scans` Collection (Auto-generated Document ID)
- Click **+ Start collection**.
- Collection ID: `scans` -> Click **Next**.
- **Document ID**: Click **Auto-ID**.
- Add fields (see [Section 2.3](#23-scans-collection) for values):
  - `userId` (Type: `string`)
  - `productCode` (Type: `string`)
  - `productName` (Type: `string`)
  - `result` (Type: `string`)
  - `timestamp` (Type: `timestamp`)
- Click **Save**.

#### 4. `reports` Collection (Auto-generated Document ID)
- Click **+ Start collection**.
- Collection ID: `reports` -> Click **Next**.
- **Document ID**: Click **Auto-ID**.
- Add fields (see [Section 2.4](#24-reports-collection) for values):
  - `productCode` (Type: `string`)
  - `userId` (Type: `string`)
  - `location` (Type: `geopoint` or `null`)
  - `note` (Type: `string` or `null`)
  - `status` (Type: `string`)
  - `timestamp` (Type: `timestamp`)
- Click **Save**.

---

### Step 1.3: Set Temporary Development Rules & Expiration
1. In the Firestore tab, click the **Rules** tab at the top.
2. Replace existing rules with the following development rules (valid for 30 days during active building):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // TEMPORARY DEVELOPMENT RULES - Day 16 testing
    // WARNING: Replace with production rules (firestore.rules) on Day 25 before release!
    match /{document=**} {
      allow read, write: if request.time < timestamp.date(2026, 11, 24);
    }
  }
}
```

3. Click **Publish**.
4. ⚠️ **Expiry Notice**: These development rules will automatically block all access on **November 24, 2026**. On **Day 25**, you will deploy the hardened production rules already prepared in [`firestore.rules`](file:///c:/Users/Raj%20Singh/Desktop/Farmer-Dost-app/firestore.rules).

---

## PART 2 — Ready-to-Copy Test Documents

Use fictional Punjab agricultural context (fictional manufacturers, realistic wheat/paddy crop inputs):

### 2.1 `products` Collection

#### Document 1 (Active Genuine Fertilizer)
- **Path**: `/products/FD-PB-00123-A7X9`
- **Document ID**: `FD-PB-00123-A7X9`

| Field Name | Type | Value | Notes |
| :--- | :--- | :--- | :--- |
| `code` | `string` | `FD-PB-00123-A7X9` | Matches Document ID |
| `name` | `string` | `Punjab Kisan Gold Neem Coated Urea 45kg` | Fictional brand |
| `manufacturer` | `string` | `Punjab Krishi Rasayan Cooperative Ltd` | Fictional manufacturer |
| `batch` | `string` | `PKR-UREA-2026-B12` | Batch identifier |
| `type` | `string` | `fertilizer` | Enum: `fertilizer` \| `pesticide` |
| `status` | `string` | `active` | Enum: `active` \| `recalled` \| `expired` |
| `manufactureDate` | `timestamp` | `March 10, 2026 at 00:00:00 UTC` | Production date |
| `expiryDate` | `timestamp` | `March 09, 2028 at 23:59:59 UTC` | Shelf life expiry |
| `createdAt` | `timestamp` | `March 12, 2026 at 10:30:00 UTC` | Server creation date |
| `dosage` | `string` | `45 kg per acre during first canal irrigation` | Farmer application guideline |

#### Document 2 (Recalled Pesticide Batch)
- **Path**: `/products/FD-PB-99441-REC1`
- **Document ID**: `FD-PB-99441-REC1`

| Field Name | Type | Value | Notes |
| :--- | :--- | :--- | :--- |
| `code` | `string` | `FD-PB-99441-REC1` | Matches Document ID |
| `name` | `string` | `Malwa Shield Chlorpyrifos 20% EC 1L` | Fictional pesticide |
| `manufacturer` | `string` | `Majha Agro Chemicals Pvt Ltd` | Fictional manufacturer |
| `batch` | `string` | `MAC-RCL-2026-X` | Recalled lot |
| `type` | `string` | `pesticide` | Enum: `fertilizer` \| `pesticide` |
| `status` | `string` | `recalled` | Tested by ResultScreen |
| `manufactureDate` | `timestamp` | `January 15, 2026 at 00:00:00 UTC` | Production date |
| `expiryDate` | `timestamp` | `January 14, 2028 at 23:59:59 UTC` | Shelf life |
| `createdAt` | `timestamp` | `January 18, 2026 at 09:00:00 UTC` | Registration date |
| `dosage` | `string` | `RECALLED: Defective concentration. Return to dealer.` | Warning notice |

---

### 2.2 `users` Collection

#### Document 1 (Test Farmer Profile)
- **Path**: `/users/usr_punjab_farmer_01`
- **Document ID**: `usr_punjab_farmer_01`

| Field Name | Type | Value |
| :--- | :--- | :--- |
| `name` | `string` | `Gurpreet Singh Sandhu` |
| `phone` | `string` | `+919876543210` |
| `language` | `string` | `pa` *(Punjabi)* |
| `district` | `string` | `Ludhiana, Punjab` |
| `createdAt` | `timestamp` | `September 01, 2026 at 08:30:00 UTC` |

---

### 2.3 `scans` Collection

#### Document 1 (Genuine Scan Record)
- **Path**: `/scans/{autoId}`
- **Document ID**: *(Auto-ID)*

| Field Name | Type | Value |
| :--- | :--- | :--- |
| `userId` | `string` | `usr_punjab_farmer_01` |
| `productCode` | `string` | `FD-PB-00123-A7X9` |
| `productName` | `string` | `Punjab Kisan Gold Neem Coated Urea 45kg` |
| `result` | `string` | `genuine` |
| `timestamp` | `timestamp` | `October 24, 2026 at 10:00:00 UTC` |

#### Document 2 (Fake / Counterfeit Scan Record)
- **Path**: `/scans/{autoId}`
- **Document ID**: *(Auto-ID)*

| Field Name | Type | Value |
| :--- | :--- | :--- |
| `userId` | `string` | `usr_punjab_farmer_01` |
| `productCode` | `string` | `FAKE-SUSPECT-8899` |
| `productName` | `null` | `null` *(leave empty or select null type)* |
| `result` | `string` | `fake` |
| `timestamp` | `timestamp` | `October 24, 2026 at 11:30:00 UTC` |

---

### 2.4 `reports` Collection

#### Document 1 (With GPS GeoPoint & Farmer Note)
- **Path**: `/reports/{autoId}`
- **Document ID**: *(Auto-ID)*

| Field Name | Type | Value | Notes |
| :--- | :--- | :--- | :--- |
| `productCode` | `string` | `FAKE-SUSPECT-8899` | Scanned barcode |
| `userId` | `string` | `usr_punjab_farmer_01` | Submitting farmer |
| `location` | `geopoint` | `Latitude: 30.9010, Longitude: 75.8573` | Ludhiana coordinates |
| `note` | `string` | `Bag seal was torn and granular texture looked like crushed river sand.` | $\le 100$ characters |
| `status` | `string` | `pending` | Review queue state |
| `timestamp` | `timestamp` | `October 24, 2026 at 11:35:00 UTC` | Submission time |

#### Document 2 (Location Null & No Note)
- **Path**: `/reports/{autoId}`
- **Document ID**: *(Auto-ID)*

| Field Name | Type | Value | Notes |
| :--- | :--- | :--- | :--- |
| `productCode` | `string` | `UNKNOWN-QR-9900` | Unrecognized barcode |
| `userId` | `string` | `usr_punjab_farmer_01` | Submitting farmer |
| `location` | `null` | `null` | Farmer skipped GPS permission |
| `note` | `null` | `null` | No optional note provided |
| `status` | `string` | `pending` | Default review state |
| `timestamp` | `timestamp` | `October 24, 2026 at 14:15:00 UTC` | Submission time |

---

## PART 3 — Verification Script & Execution

The verification script has been implemented in [`lib/services/firestore_verifier.dart`](file:///c:/Users/Raj%20Singh/Desktop/Farmer-Dost-app/lib/services/firestore_verifier.dart).

### How to Run:
In [`lib/main.dart`](file:///c:/Users/Raj%20Singh/Desktop/Farmer-Dost-app/lib/main.dart), uncomment the two lines:
```dart
import 'services/firestore_verifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    // RUN VERIFICATION SCRIPT:
    await runDay16FirestoreVerification();
  } catch (e) { ... }
}
```

### Expected Output:
```text
======================================================
🚀 RUNNING DAY 16 FIRESTORE STRUCTURE VERIFICATION
======================================================

--- [CHECK 1] Direct Product Lookup by Document ID ---
Found Product: FD-PB-00123-A7X9
   • code (String): FD-PB-00123-A7X9
   • name (String): Punjab Kisan Gold Neem Coated Urea 45kg
   • manufacturer (String): Punjab Krishi Rasayan Cooperative Ltd
   • batch (String): PKR-UREA-2026-B12
   • type (String): fertilizer
   • status (String): active
   • manufactureDate (Timestamp): Timestamp(seconds=1773091200, nanoseconds=0)
   • expiryDate (Timestamp): Timestamp(seconds=1836172799, nanoseconds=0)
   • dosage (String): 45 kg per acre during first canal irrigation
✅ [PASS] Check 1: Product document "FD-PB-00123-A7X9" fetched successfully.

--- [CHECK 2] Non-Existent Product ID (Fake Detection) ---
Target ID: "NON-EXISTENT-CODE-999" -> exists == false
✅ [PASS] Check 2: Non-existent product ID correctly returned exists == false.

--- [CHECK 3] User Scan History Query (Indexed) ---
Found 2 scan records for user: usr_punjab_farmer_01
   [Scan 1] ID: scn_02
      Code: FAKE-SUSPECT-8899 | Result: fake | Name: null
      Timestamp: Timestamp(seconds=1792841400, nanoseconds=0)
   [Scan 2] ID: scn_01
      Code: FD-PB-00123-A7X9 | Result: genuine | Name: Punjab Kisan Gold Neem Coated Urea 45kg
      Timestamp: Timestamp(seconds=1792836000, nanoseconds=0)
✅ [PASS] Check 3: Scans query executed and returned 2 record(s).

======================================================
📊 DAY 16 VERIFICATION SUMMARY: ALL PASSED ✅
======================================================
```

### What if Check 3 Fails with "Index Required"?
If the terminal prints:
`FAILED_PRECONDITION: The query requires an index. You can create it here: https://console.firebase.google.com/v1/r/project/.../firestore/indexes?create_composite=...`

#### Why it Happens:
Firestore automatically indexes single fields, but when you combine an **equality filter** (`where('userId', isEqualTo: ...)`) with a **range/sort clause on a different field** (`orderBy('timestamp', descending: true)`), Firestore requires a **Composite Index**.

#### How to Fix:
1. Simply **click the URL** printed in your Flutter debug console.
2. The Firebase Console opens with the collection (`scans`), fields (`userId` ASC, `timestamp` DESC), and query scope pre-filled.
3. Click **Create index** button.
4. Wait 1–2 minutes while Firestore builds the index (status changes from *Building* to *Enabled*).
5. Re-run your app. Check 3 will immediately pass.

---

## PART 4 — Structure Review Checklist

Before moving to Day 17, audit your documents in the Firebase console against this checklist:

| Common Mistake | Symptom | How to Fix in Console |
| :--- | :--- | :--- |
| **Timestamp stored as String** | Sorting fails or shows lexicographical errors (`"2026-10-24"`). | In the console, delete the field and re-add with **Type = timestamp** (select date/time picker). |
| **Document ID generated randomly for products** | Check 1 fails with 404/not found. | The document ID for `/products` must be the **exact QR string** (e.g. `FD-PB-00123-A7X9`), not an auto-generated push ID. |
| **Case-sensitive field names** | `userId` vs `userid` vs `userId ` (trailing space). Query returns 0 records. | Ensure camelCase naming across all documents: `userId`, `productCode`, `productName`, `manufactureDate`, `expiryDate`. |
| **Number stored as String** | Math or range queries fail. | For GPS, always select type **geopoint** (lat, lng), never strings. |
| **Missing nullable fields** | Crash on `map['location']` or `map['note']`. | In Firestore, you can either omit the field or set value to `null`. Our models safely handle both. |
