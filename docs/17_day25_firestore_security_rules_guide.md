# Day 25 — Cloud Firestore Security Rules Guide

> **Farmer Dost App** — Production Database Security & Least Privilege Specification  
> Target File: `firestore.rules`

---

## 1. Plain-English Explanation of Each Rule

| Collection | Rule Logic | Plain-English Reason |
| :--- | :--- | :--- |
| **`products/{code}`** | `allow get: if isAuthenticated();`<br/>`allow list: if false;`<br/>`allow write: if false;` | **No Scraping & No Client Tampering**: Signed-in farmers can verify single packages via direct QR lookup (`get`). Listing the entire database (`list`) is blocked so competitors/counterfeiters cannot scrape product codes. Writes from client devices are strictly denied. |
| **`users/{userId}`** | `allow read: if isOwner(userId);`<br/>`allow create: if isOwner(...) && name.size() > 0 && createdAt == request.time;`<br/>`allow update: if isOwner(...) && createdAt == resource.data.createdAt;`<br/>`allow delete: if false;` | **Privacy & Immutability**: Farmers can only access their own profile. Creation enforces server timestamps and valid names. Updates prevent users from tampering with account creation dates or overwriting other accounts. |
| **`scans/{scanId}`** | `allow create: if isAuthenticated() && userId == auth.uid && timestamp == request.time;`<br/>`allow read: if isAuthenticated() && resource.userId == auth.uid;`<br/>`allow update, delete: if false;` | **Immutable Audit Trail**: Farmers can view their own scan history. Once created, scans cannot be edited or deleted by the user, preserving evidentiary integrity for counterfeit investigations. |
| **`reports/{reportId}`** | `allow create: if isAuthenticated() && userId == auth.uid && status == 'pending' && timestamp == request.time && note.size() <= 100;`<br/>`allow read: if isAuthenticated() && resource.userId == auth.uid;`<br/>`allow update, delete: if false;` | **Protected Whistleblower Pipeline**: Reports must start with status `"pending"` and a timestamp set by the server. Notes are capped at 100 characters to prevent database bloat. Other farmers cannot spy on submitted reports. |
| **Default** | `match /{document=**} { allow read, write: if false; }` | **Zero Trust**: Any unmentioned collection or path is closed by default. |

---

## 2. Warnings for Planned App Features

> [!WARNING]
> 1. **Anonymous / Pre-Login Product Scanning**:
>    Because `products` requires `isAuthenticated()`, unauthenticated guest users cannot verify QR codes until they sign in (or an anonymous auth session is started via `FirebaseAuth.instance.signInAnonymously()`).
> 2. **Listing Scans Requires an Index**:
>    Querying `scans.where('userId', '==', uid).orderBy('timestamp', descending: true)` requires a composite index in Firestore. We define this in Day 26.
> 3. **Admin Resolution of Reports**:
>    Because mobile clients cannot update `status` on `reports`, marking a report as `"reviewed"` or `"confirmed"` must be done via the Firebase Admin SDK / Admin Console.

---

## 3. Rules Playground & Test Matrix

### Test Scenarios
```javascript
// Test 1: Signed-in user reading a genuine product -> ALLOWED
auth = { uid: "farmer_1" };
get("/databases/(default)/documents/products/FD-FT-00101-A7X9KM") -> ALLOW

// Test 2: User listing all products -> DENIED
auth = { uid: "farmer_1" };
list("/databases/(default)/documents/products") -> DENY

// Test 3: Client attempting to insert a product -> DENIED
auth = { uid: "farmer_1" };
create("/databases/(default)/documents/products/NEW_CODE", { ... }) -> DENY

// Test 4: Farmer creating their own profile -> ALLOWED
auth = { uid: "farmer_1" };
create("/databases/(default)/documents/users/farmer_1", { name: "Raj Singh", createdAt: request.time }) -> ALLOW

// Test 5: Farmer modifying someone else's profile -> DENIED
auth = { uid: "farmer_1" };
update("/databases/(default)/documents/users/farmer_2", { ... }) -> DENY
```

---

## 4. Exact Client Error on Denial & App Handling

When a security rule rejects a request, Cloud Firestore throws:
```text
FirebaseException: [cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
```
In `VerificationService` and `ReportService`, we catch `fe.code == 'permission-denied'` and translate it into a developer-visible message rather than displaying `"fake"` or crashing the app.

---

## 5. Deployment Commands

```bash
# 1. Login to Firebase CLI
firebase login

# 2. Deploy only Firestore Security Rules
firebase deploy --only firestore:rules
```
