# Farmer Dost App — MVP Full Flow Acceptance Test Report (Day 42)

**App Version**: v1.0.0+1  
**Build Target**: Flutter 3.x / Android (minSdk 21, targetSdk 34)  
**Firebase Stack**: Firebase Authentication, Cloud Firestore  
**Test Date**: November 2026  
**Audience**: Quality Assurance, Field Testing Officers, Punjab Agricultural Mandi Partners  

---

## 1. Executive Summary

The Farmer Dost mobile application build (Days 29 through 42) delivers an end-to-end QR code authenticity verification tool for agricultural fertilizers and pesticides. The app connects live camera scanning via `mobile_scanner` to Cloud Firestore verification (`products`, `users`, `scans`, `reports`), enforcing strict outdoor sunlight contrast (WCAG AAA >= 7.0:1), haptic feedback, 1.3x accessibility font scaling, and robust error resilience.

---

## 2. Acceptance Test Script & Results Matrix

| Step # | Flow / Step | Test Action | Expected Result | Pass / Fail |
|:---:|:---|:---|:---|:---:|
| **1** | **Fresh Install & Splash** | Launch app for the first time. | Splash screen displays for $\ge 1.0$s with logo & tagline while Firebase/Auth initializes. Routes to `LoginScreen` via `AuthGate`. | **PASS** |
| **2** | **New Farmer Sign Up** | Toggle to "Sign Up", enter name, email, and password ($\ge 6$ chars), and tap "Create Account". | Button enters loading state. Firebase user created; Firestore document `users/{uid}` created with server timestamp. Auto-routes to `HomeScreen`. | **PASS** |
| **3** | **Scan Genuine Product** | Tap "Tap to Scan Product", grant camera permission, scan `FD-FT-00101-GEN001`. | Loading overlay appears ("Verifying product..."). Camera halts. Result screen opens with Green Check, product name, batch, manufacturer, expiry date. Light haptic tap. Audit record logged in `scans`. | **PASS** |
| **4** | **Scan Recalled Product** | Scan known recalled batch code `FD-PS-00202-REC002`. | Amber warning header ("Product Recalled"), "Recalled, do not use", heavy haptic feedback, "Report Recalled Product" button available. | **PASS** |
| **5** | **Scan Expired Product** | Scan expired batch code `FD-PS-00888-EXPIRE`. | Amber warning header ("Product Expired"), "Expired", expiry date highlighted in red, "Report Expired Product" button available. | **PASS** |
| **6** | **Scan Fake / Counterfeit** | Scan unregistered code `FD-FT-99999-NOTFND`. | Red warning ("Not Recognized / Counterfeit Alert"), message: "This code was not found in our database", heavy haptic feedback, "Report Counterfeit Product" button displayed. | **PASS** |
| **7** | **Scan Garbage / URL QR** | Scan `https://example.com` or manual code `INVALID-XYZ`. | Neutral warning ("Invalid Code Format"), "This doesn't look like a Farmer Dost code", Scan Again button. **No** report button. | **PASS** |
| **8** | **Scan with Airplane Mode** | Enable Airplane mode (kill network), scan any code. | After 3.5s shows "Still checking...". At 10s timeout displays neutral offline card: "Can't verify right now, check your connection". **Never** flags product as fake. "Retry" button offered. | **PASS** |
| **9** | **Report Fake Product** | From Fake result screen, tap "Report Counterfeit". Capture GPS location and enter note (e.g. "Sold without bill"). Tap "Submit Report". | Submit button disables to prevent double-tap. Record saved to `reports` with deterministic ID `${uid}_${code}`. Green confirmation SnackBar shown. Returns to `HomeScreen`. | **PASS** |
| **10** | **Report Duplicate Code** | Navigate to Report screen for the same code and submit again. | Service recognizes existing report document. Displays amber SnackBar: "You have already reported this product code. Your report is pending review." Returns Home. | **PASS** |
| **11** | **Farmer Profile** | Tap Profile icon in AppBar. | Shows farmer initials avatar (e.g. "GS"), name, email, phone from `users/{uid}`. Language dropdown (Punjabi, Hindi, English). | **PASS** |
| **12** | **Scan History** | Tap "View All" on Recent Scans on Home screen. | Paginated list (20 per page) loaded newest first with date, product name, and status badge. Pull-to-refresh works. Tapping a row opens read-only audit detail bottom sheet. | **PASS** |
| **13** | **Logout Flow** | In Profile, tap "Log Out". In dialog, tap "Cancel" (verifies session intact). Tap "Log Out" again and tap "Log Out" in dialog. | Dialog prompts "Log Out?". Cancel keeps user on Profile. Confirm signs out via FirebaseAuth and immediately routes to `LoginScreen`. | **PASS** |
| **14** | **Login Again** | Enter registered email & password on `LoginScreen`. Tap "Sign In". | Logs in successfully; session persists across app kills. Top recent scans and profile details restored immediately. | **PASS** |

---

## 3. Firestore Composite Index Requirement

For paginated scan history queries (`ScanHistoryService.getScanHistory`):
- **Collection**: `scans`
- **Fields**:
  1. `userId` (Ascending)
  2. `timestamp` (Descending)
- **Query Scope**: Collection

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
    }
  ]
}
```

---

## 4. Top 5 Risks to Address Before Phase 5 (Offline Caching)

1. **Intermittent 2G Connectivity in Remote Mandis**:
   - *Risk*: Farmers frequently purchase fertilizer in rural mandis with zero or fluctuating cellular coverage where Firestore queries fail.
   - *Phase 5 Fix*: Implement a local SQLite/Isar cache containing encrypted bloom filters or signed public-key verification of genuine batch serial numbers so basic verification works 100% offline.

2. **Battery Drain from Prolonged Camera & Torch Use**:
   - *Risk*: Keeping the camera feed active in high-brightness outdoor sunlight rapidly drains smartphone battery in rural fields.
   - *Phase 5 Fix*: Add an automated 45-second camera inactivity sleep timer and auto-torch shutoff after 30 seconds of illumination.

3. **Dirty, Torn, or Scratched QR Code Labels**:
   - *Risk*: Fertilizer bags stored outdoors in rain or dragged across gravel develop smudged or scratched QR codes that optical scanners fail to decode.
   - *Phase 5 Fix*: Enhance manual code entry with OCR (Google ML Kit text recognition) so farmers can point the camera at the human-readable text code if the QR pattern is damaged.

4. **Network Flapping Duplicate Submissions**:
   - *Risk*: A farmer taps "Submit Report" on an unstable connection that drops right after sending data, causing the farmer to press retry repeatedly.
   - *Phase 5 Fix*: Client-side local request queuing with exponential backoff and idempotency tokens (backed by our existing `${uid}_${code}` deterministic document IDs).

5. **SMS OTP Quota Exhaustion for Rural Phone Sign-in**:
   - *Risk*: High cellular carrier SMS charges or network latency in villages can delay OTP delivery past timeout.
   - *Phase 5 Fix*: Add WhatsApp OTP delivery integration or biometric device-level authentication (Fingerprint / Face ID) for returning farmers once registered.
