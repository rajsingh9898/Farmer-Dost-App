# Day 21 — Farmer Dost App System Architecture Diagram

> **System Architecture Specification**  
> Covers Flutter Mobile Client, Firebase Authentication, Cloud Firestore Collections, and Python Backend QR Generator.

---

## 1. High-Level Mermaid Architecture Diagram

```mermaid
flowchart TB
    %% Subgraphs & Components
    subgraph BACKEND ["🐍 Python Backend & Industrial Packaging Pipeline"]
        direction TB
        CSV["📄 products_input.csv<br/>(Batch metadata: name, manufacturer, dates)"]
        GEN["⚙️ backend/generate_codes.py<br/>• CSPRNG: secrets.choice()<br/>• Alphabet: 31-char unambiguous<br/>• Format: FD-(FT|PS)-00001-A7X9KM<br/>• Optional weighted checksum"]
        QR_OUT["🖼️ backend/qr_output/<br/>(High-contrast PNG, Level M Error Correction)"]
        AUDIT_CSV["📋 backend/codes_generated.csv<br/>(Local cryptographic generation audit trail)"]
        ADMIN_SDK["🔐 Firebase Admin SDK<br/>(serviceAccountKey.json credentials)"]
        
        CSV --> GEN
        GEN --> QR_OUT
        GEN --> AUDIT_CSV
        GEN --> ADMIN_SDK
    end

    subgraph FIRESTORE ["🔥 Google Cloud Firestore Database (farmer-dost-app)"]
        direction TB
        COLL_PRODUCTS[("📦 products/{code}<br/>[ID = QR Code String]<br/>────────────────────────<br/>• code (string, key)<br/>• name (string)<br/>• manufacturer (string)<br/>• batch (string)<br/>• type (fertilizer | pesticide)<br/>• status (active | recalled | expired)<br/>• manufactureDate (Timestamp)<br/>• expiryDate (Timestamp)<br/>• createdAt (Timestamp)<br/>────────────────────────<br/>🔒 READ: Signed-in / Public get()<br/>🚫 WRITE: Denied to clients (Admin SDK only)")]

        COLL_USERS[("👤 users/{uid}<br/>[ID = Firebase Auth UID]<br/>────────────────────────<br/>• name (string)<br/>• email (string)<br/>• phone (string, nullable)<br/>• language (string: 'en' | 'pa')<br/>• createdAt (Timestamp)<br/>────────────────────────<br/>🔒 READ/WRITE: request.auth.uid == uid")]

        COLL_SCANS[("📜 scans/{autoId}<br/>[ID = Auto-generated]<br/>────────────────────────<br/>• userId (string = auth.uid)<br/>• productCode (string)<br/>• productName (string, denormalized)<br/>• result (genuine|recalled|expired|notRecognized)<br/>• timestamp (serverTimestamp)<br/>────────────────────────<br/>🔒 CREATE: auth.uid == userId<br/>🔒 READ: resource.userId == auth.uid<br/>🚫 UPDATE/DELETE: Blocked")]

        COLL_REPORTS[("🚨 reports/{uid_code}<br/>[ID = Deterministic or Auto]<br/>────────────────────────<br/>• productCode (string)<br/>• userId (string = auth.uid)<br/>• location (GeoPoint, nullable)<br/>• note (string, max 100 chars)<br/>• status ('pending')<br/>• timestamp (serverTimestamp)<br/>────────────────────────<br/>🔒 CREATE: Once per user per product<br/>🔒 READ: Submitting user only<br/>🚫 UPDATE/DELETE: Blocked for clients")]
    end

    subgraph AUTH ["🔑 Firebase Authentication"]
        AUTH_SERVICE["Firebase Auth Provider<br/>• Email / Password Authentication<br/>• Phone Number OTP (SMS)<br/>• User Session (request.auth.uid)"]
    end

    subgraph FLUTTER ["📱 Flutter Mobile Application (Farmer Dost App)"]
        direction TB
        subgraph UI ["Presentation Layer (Screens & Widgets)"]
            SPLASH["SplashScreen / AuthGate"]
            LOGIN["LoginScreen (Email / OTP)"]
            HOME["HomeScreen (Dashboard & Recents)"]
            SCAN_UI["ScanScreen (mobile_scanner Camera Viewfinder)"]
            MANUAL["ManualCodeEntryDialog"]
            RESULT_UI["ResultScreen (Genuine, Recalled, Expired, Fake)"]
            REPORT_UI["ReportScreen (Report Counterfeit Form)"]
            PROFILE_UI["ProfileScreen (Language, History)"]
        end

        subgraph SERVICES ["Service Layer (Pure Dart Logic)"]
            VAL_ENGINE["🔍 normalizeAndValidate(raw)<br/>• Trims whitespace & converts to uppercase<br/>• Rejects null/undefined strings<br/>• Regex: ^FD-(FT|PS)-\\d{5}-[A-Z0-9]{6,12}$<br/>• Rejects '/', '\\', URLs, Emojis, 500-char payloads"]
            VERIFY_SVC["⚡ VerificationService<br/>• Direct O(1) doc(code).get()<br/>• 10s timeout protection<br/>• Evaluates recalled & expired states<br/>• Maps unavailable -> networkError"]
            AUTH_SVC["🛡️ AuthService<br/>• signInWithEmail / signUpWithEmail<br/>• verifyPhoneNumber OTP flow<br/>• users/{uid} document self-healing"]
            SCAN_SVC["📝 logScan(result)<br/>• Writes to scans collection<br/>• Skips invalidInput & networkError<br/>• Failure-tolerant background write"]
            REPORT_SVC["📢 ReportService (Day 24)<br/>• Deterministic {uid}_{code} prevention<br/>• Max 100 chars note validation"]
        end

        subgraph MODELS ["Domain Models"]
            M_RES["VerificationResult<br/>(status, scannedCode, product details, message)"]
            M_PROD["Product<br/>(code, name, batch, dates, status)"]
            M_USER["UserModel<br/>(uid, name, email, phone, language)"]
            M_SCAN["ScanModel"]
            M_REP["ReportModel"]
        end
    end

    %% Connections & Data Flows
    ADMIN_SDK -- "Writes verified catalog documents" --> COLL_PRODUCTS

    SCAN_UI -- "1. Scans QR Code" --> VAL_ENGINE
    MANUAL -- "1. Manual Code Entry" --> VAL_ENGINE
    
    VAL_ENGINE -- "Format Invalid -> instant invalidInput" --> RESULT_UI
    VAL_ENGINE -- "2. Valid Code -> Normalized string" --> VERIFY_SVC

    VERIFY_SVC -- "3. Direct doc(code).get() lookup" --> COLL_PRODUCTS
    COLL_PRODUCTS -- "Returns DocumentSnapshot" --> VERIFY_SVC

    VERIFY_SVC -- "4. Generates VerificationResult" --> RESULT_UI
    VERIFY_SVC -- "5. Failure-tolerant logScan()" --> SCAN_SVC
    SCAN_SVC -- "Writes audit record" --> COLL_SCANS

    LOGIN --> AUTH_SVC
    AUTH_SVC <--> AUTH
    AUTH -- "Resolves user session UID" --> COLL_USERS

    REPORT_UI --> REPORT_SVC
    REPORT_SVC -- "Submits fake product report" --> COLL_REPORTS
    COLL_SCANS -.-> HOME
    COLL_USERS -.-> PROFILE_UI
```

---

## 2. Key Architectural Guarantees

1. **Client Isolation**: The Flutter app **never** has write permissions to `/products`. Product insertion occurs exclusively through the Python backend utilizing `serviceAccountKey.json`.
2. **Pre-Firestore Rejection**: All scanned strings are sanitized by `normalizeAndValidate()` before hitting network sockets. URLs, empty strings, illegal `/` paths, and garbage inputs cost 0 billable Firestore operations and execute in $< 1\text{ms}$.
3. **Deterministic Identity**:
   - `products`: Keyed by normalized uppercase QR string (`FD-FT-00123-A7X9KM`).
   - `users`: Keyed by Firebase Auth UID.
   - `reports`: Keyed deterministically by `{uid}_{productCode}` to prevent duplicate reporting spam.
   - `scans`: Auto-generated IDs representing an append-only audit log.
4. **Resilience & Rural Tolerance**: Every network call is guarded by a 10-second timeout. `logScan()` execution is fully decoupled so logging failures never delay displaying authenticity verdicts to farmers.
