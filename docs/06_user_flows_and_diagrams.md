# Day 6 — User Flows & System Sequence Diagrams

## Flow 1 — Scan, Verify, Report

```mermaid
sequenceDiagram
    autonumber
    actor Farmer
    participant App as Flutter App
    participant Scanner as MobileScanner
    participant DB as Cloud Firestore (products)
    participant Scans as Cloud Firestore (scans)
    participant Reports as Cloud Firestore (reports)

    Farmer->>App: Opens Home Screen & taps "Open Camera Scanner"
    App->>Scanner: Initializes Camera Feed
    Scanner-->>App: QR Code Detected ("GENUINE-123")
    App->>DB: verifyProduct("GENUINE-123")
    alt Connection Success
        DB-->>App: Product Document (Name, Batch, Status)
        App->>Scans: logScan(userId, productCode, result)
        App->>Farmer: ResultScreen (Green Genuine Checkmark)
    else Product Fake or Unrecognized
        DB-->>App: Null or Fake Status
        App->>Scans: logScan(userId, productCode, result)
        App->>Farmer: ResultScreen (Red Warning + "Report This Product")
        Farmer->>App: Taps "Report This Product"
        App->>Farmer: ReportScreen (Code auto-filled)
        Farmer->>App: Submits Note & Location
        App->>Reports: submitReport(ReportModel)
        Reports-->>App: Confirmation
        App->>Farmer: SnackBar Confirmation -> Returns to Home
    else Network / Connection Offline
        DB-->>App: FirestoreConnectionException
        App->>Farmer: ResultScreen (ErrorCard: "Can't verify right now, check your connection")
    end
```

---

## Flow 2 — Auth & Farmer Profile

```mermaid
sequenceDiagram
    autonumber
    actor Farmer
    participant App as Flutter App
    participant Auth as Firebase Auth
    participant UsersDB as Firestore (users)
    participant ScansDB as Firestore (scans)

    Farmer->>App: Launches App
    App->>Auth: check authStateChanges()
    alt Not Logged In
        Auth-->>App: null
        App->>Farmer: LoginScreen (Phone OTP / Email fallback)
        Farmer->>App: Enters Phone Number & OTP
        App->>Auth: signInWithCredential()
        Auth-->>App: User Logged In
    end
    App->>Farmer: HomeScreen
    Farmer->>App: Taps Profile Icon
    App->>UsersDB: getProfile(userId)
    App->>ScansDB: getScanHistory(userId)
    ScansDB-->>App: List of Scans (Timestamp Descending)
    App->>Farmer: ProfileScreen (Info Card + Scrollable Scan History Badges)
```

---

## Flutter Screen & Route Mapping Table

| Screen Name | File Path | Trigger / Action | Target Screen |
|---|---|---|---|
| `SplashScreen` | `lib/screens/splash_screen.dart` | Auth Check complete | `HomeScreen` or `LoginScreen` |
| `LoginScreen` | `lib/screens/login_screen.dart` | Auth Success / Guest | `HomeScreen` |
| `HomeScreen` | `lib/screens/home_screen.dart` | Tap "Scan Camera" | `ScanScreen` |
| `HomeScreen` | `lib/screens/home_screen.dart` | Tap "Profile" | `ProfileScreen` |
| `ScanScreen` | `lib/screens/scan_screen.dart` | QR Code Detected | `ResultScreen` |
| `ResultScreen` | `lib/screens/result_screen.dart` | Tap "Report Product" | `ReportScreen` |
| `ReportScreen` | `lib/screens/report_screen.dart` | Tap "Submit Report" | `HomeScreen` |
| `ProfileScreen` | `lib/screens/profile_screen.dart` | Tap Back | `HomeScreen` |
