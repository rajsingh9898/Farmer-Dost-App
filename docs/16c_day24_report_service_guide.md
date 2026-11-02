# Phase 4: Counterfeit Report Service (`report_service.dart`)

Authoritative specification for **Stage 12** of the **Farmer Dost App**: handling counterfeit incident submissions, pre-validation, authentication enforcement, 100-character note limits, duplicate report deduplication, and structured `ReportResult` status mapping.

---

## 1. Architectural Design & Security Constraints

The reporting pipeline allows verified farmers to alert state agricultural authorities about fraudulent seeds, fertilizers, or pesticides:

```text
[Farmer Taps "Report Product"]
              │
              ▼
[Tier 1: Pre-Firestore Input & Session Sanitization]
   ├── Product Code Pre-Validation: normalizeAndValidate(code)
   │     └── Invalid format ──► ReportStatus.invalidInput
   ├── Authentication Guard: FirebaseAuth.currentUser != null
   │     └── Not signed in  ──► ReportStatus.notSignedIn (Strict Auth Requirement)
   └── Note Sanitization: trim whitespace, empty -> null, length <= 100
         └── Length > 100   ──► ReportStatus.invalidInput
              │ (Valid session & inputs)
              ▼
[Tier 2: Idempotent Deterministic Document Lookup]
   ├── Target Document ID: `${uid}_${normalizedCode}`
   ├── doc(reportDocId).get() with 10-second rural timeout
   └── Document already exists? ──► ReportStatus.alreadyReported
              │ (New incident report)
              ▼
[Tier 3: Cloud Firestore Document Creation]
   ├── doc(reportDocId).set(reportData)
   ├── Payload: {productCode, userId, status: "pending", timestamp: serverTimestamp, note, location}
   └── Outcome ──► ReportStatus.success
```

---

## 2. Key Senior Engineering Decisions

### 2.1 Deterministic Compound ID `${uid}_${productCode}`
- **The Problem**: Farmers reporting fake products in busy mandis often double-tap the submit button or resubmit the same code after a delay, creating redundant records that clutter government review queues.
- **The Solution**: Constructing the Firestore document ID as `${uid}_${normalizedCode}` guarantees that any subsequent report by the same farmer targets the identical document path. The service checks `docRef.get().exists` and immediately returns `ReportStatus.alreadyReported` without creating duplicate records.

### 2.2 Strict Authentication Guard
- Anonymous or unauthenticated users are strictly barred from creating incident reports (`ReportStatus.notSignedIn`). This prevents malicious bots from flooding the regulatory database with fictitious complaints while preserving clear accountability through the farmer's verified Auth UID.

### 2.3 100-Character Note Limit
- Prevents database abuse, oversized payload costs, and spam injection. Enforced on both the client UI (live counter `0/100` and `maxLength: 100`) and the service layer (`if (note.length > 100) return invalidInput;`).

---

## 3. `ReportResult` Status Matrix

| Status | Trigger Condition | UI Presentation / Action |
| :--- | :--- | :--- |
| `ReportStatus.success` | Report written to `/reports/{uid}_{code}` | Green SnackBar thanking farmer $\rightarrow$ redirect Home. |
| `ReportStatus.alreadyReported` | Document `${uid}_{code}` already exists | Amber SnackBar explaining report is already pending review $\rightarrow$ redirect Home. |
| `ReportStatus.notSignedIn` | `FirebaseAuth.currentUser == null` | SnackBar prompting farmer to sign in before reporting. |
| `ReportStatus.invalidInput` | Code fails regex or note $> 100$ chars | Inline field error message; submission halted locally. |
| `ReportStatus.networkError` | Cellular drop, timeout, or SocketException | Red SnackBar; input form preserved so farmer can retry. |
| `ReportStatus.permissionDenied` | Firestore security rules rejection | Developer notice logged; friendly user retry notice. |

---

## 4. Test Verification Summary

All 6 test cases in [`test/report_service_test.dart`](file:///c:/Users/Raj%20Singh/Desktop/Farmer-Dost-app/test/report_service_test.dart) pass:
1. Rejects malformed product codes before database lookup (`invalidInput`).
2. Rejects notes exceeding 100 characters (`invalidInput`).
3. Rejects unauthenticated callers (`notSignedIn`).
4. Successfully writes valid report with deterministic ID `${uid}_${code}`.
5. Returns `alreadyReported` on second report for identical product by same farmer.
6. Treats whitespace-only notes as `null` without saving empty string fields.
