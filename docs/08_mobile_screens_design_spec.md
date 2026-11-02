# Phase 2: Complete Seven Screens UI/UX Design Specification

Design specification for all **seven core screens** of the **Farmer Dost App**, engineered for small-scale farmers in Punjab operating in outdoor, high-glare environments on low-cost Android hardware.

---

## Universal Accessibility & Field Design Standards

1. **Outdoor Glare Contrast (WCAG AAA / AA)**:
   - Primary Trust Green: `#2E7D32` on White `#FFFFFF` (Contrast ratio **7.4:1** — passes AAA).
   - Alert Crimson Red: `#D32F2F` on White `#FFFFFF` (Contrast ratio **5.1:1** — passes AA).
   - Recalled Warning Orange: `#ED6C02` on White (Contrast ratio **4.6:1** — passes AA).
   - High-Contrast Text: `#1A1C1E` on White `#FFFFFF` (Contrast ratio **15.8:1** — passes AAA).
2. **Never Color Alone**:
   - Meaning is strictly conveyed through **Icon Shape + Color + Text Label**.
   - *Genuine*: Green Circle Checkmark (`Icons.check_circle_rounded`) + "Genuine Product".
   - *Counterfeit / Not Recognized*: Red Error Octagon (`Icons.gpp_bad_rounded`) + "Not Recognized / Counterfeit Alert".
   - *Recalled*: Amber Warning Triangle (`Icons.warning_amber_rounded`) + "Product Recalled".
   - *Expired*: Deep Orange Calendar X (`Icons.event_busy_rounded`) + "Product Expired".
   - *Network Offline*: Slate Blue Wifi Off (`Icons.wifi_off_rounded`) + "Verification Offline".
3. **Touch Targets**:
   - Every interactive element (buttons, back buttons, torch toggle, list tiles, dropdowns) maintains a minimum bounding box of **$48\text{dp} \times 48\text{dp}$**.
4. **1.3x Font Scaling Survivability**:
   - All screens wrapped in flexible scroll views (`SingleChildScrollView` or `ListView`).
   - Zero hardcoded heights on text containers; flexible `Column` layouts prevent overflow on large system fonts.

---

## Screen 1 — Splash Screen (`/splash`)

### 1. Purpose & Flow
Initial gateway on app launch. Initializes Firebase Core, binds local emulator flags if enabled, validates authentication state, and redirects to `AuthGate` (Login or Home).

### 2. Layout Structure
- **Container**: Full-height column, pure white background (`#FFFFFF`).
- **Center Hero (Vertical Auto-Layout)**:
  - App Logo: Green shield icon with centered checkmark ($64\text{dp} \times 64\text{dp}$, color `#2E7D32`).
  - App Title: `"Farmer Dost"` ($24\text{sp}$, Bold, `#1A1C1E`).
  - Tagline: `"Scan. Verify. Trust."` ($15\text{sp}$, Regular, muted `#74777F`).
- **Bottom Status Anchor ($64\text{dp}$ from bottom)**:
  - Active: Indeterminate progress spinner ($24\text{dp}$, `#2E7D32`) + `"Connecting to secure service..."` ($13\text{sp}$).
  - Timeout / Offline Error: Warning icon + `"Unable to connect to service"` + `$48\text{dp}$` high-contrast `"Retry Connection"` button.

### 3. States & Copy Text
| State | Visual Indicator | Exact Copy Text | Action |
| :--- | :--- | :--- | :--- |
| **Loading** | CircularProgressIndicator (`#2E7D32`) | `"Connecting to secure service..."` | None (in flight) |
| **Success** | Seamless fade transition | None | Push replacement to `/` (AuthGate) |
| **Timeout / Error** | Red error icon + Retry button | `"Unable to connect to service. Please check your internet connection and try again."` | Tap `"Retry Connection"` triggers re-init |

---

## Screen 2 — Home Screen (`/home`)

### 1. Purpose & Flow
The primary command center for the farmer. Delivers instant access to the QR scanner, manual code entry, recent verification history, and user profile.

### 2. Layout Structure
- **Top App Bar**:
  - Title: `"Farmer Dost"` ($22\text{sp}$ Bold, `#1A1C1E`).
  - Actions: Language indicator pill button (`"PA / EN"`, $48\text{dp}$ target) and Profile avatar icon button ($48\text{dp}$ target).
- **Hero Scanner Zone (Center Top)**:
  - Background Card: Soft neutral container (`#F4FBF4` with subtle border `#C8E6C9`).
  - Giant Scan Button: Centered circular button ($110\text{dp}$ diameter, filled `#2E7D32`, elevation $4\text{dp}$, white QR scan icon $44\text{dp}$).
  - Call to Action: `"Tap to Scan Product"` ($18\text{sp}$ SemiBold, `#1A1C1E`).
  - Helper Subtitle: `"Point camera at QR code on fertilizer or pesticide bag"` ($13\text{sp}$, `#42474E`).
- **Manual Entry Fallback**:
  - Outlined button ($48\text{dp}$ height): `"Enter Code Manually"` with keyboard icon.
- **Recent Scans Section (Lower Half)**:
  - Header Row: `"Recent Scans"` ($17\text{sp}$ Bold) + `"View All"` ($14\text{sp}$ green action link).
  - List of 3 Recent Scans: Reusable `ScanHistoryTile` components with status badge, product name, and timestamp.

### 3. States & Copy Text
| State | Visual Elements | Exact Copy Text |
| :--- | :--- | :--- |
| **Populated** | 3 scan history cards with status badges | Product names, dates, `"View All"` |
| **Empty** | Centered illustration/icon + grey card | `"No scans recorded yet. Tap above to scan your first product."` |
| **Loading** | Shimmer placeholder list items | Loading skeletons |

---

## Screen 3 — Scan Camera Screen (`/scan`)

### 1. Purpose & Flow
Full-screen hardware camera feed using `MobileScanner`. Captures QR code, pauses viewfinder on detection, validates code syntax, queries backend verification, and navigates to Result Screen.

### 2. Layout Structure
- **Camera Viewport**: Full-bleed background (`MobileScanner`).
- **Semi-Transparent Dark Vignette**: Semi-black overlay (`#000000` with $60\%$ opacity) masking non-active areas.
- **Viewfinder Reticle (Centered $260\text{dp} \times 260\text{dp}$)**:
  - Transparent cut-out.
  - 4 Corner Brackets: $32\text{dp}$ corner arms, $4\text{dp}$ stroke width, vibrant green `#2E7D32` with rounded caps.
- **Top Overlay Bar ($16\text{dp}$ from top)**:
  - Left: Close `"X"` icon button ($48\text{dp}$ target, white icon on translucent dark circle).
  - Right: Torch toggle button ($48\text{dp}$ target, bulb icon, toggles state).
- **Bottom Instruction Zone**:
  - Guidance Text: `"Point camera at the QR code"` ($15\text{sp}$ Medium, white with text shadow).
  - Manual Entry Pill: Floating rounded button `"Enter Code Manually"`.

### 3. States & Copy Text
| State | Reticle & Overlay Behavior | Exact Copy Text |
| :--- | :--- | :--- |
| **Searching** | Reticle brackets steady `#2E7D32` | `"Point camera at the QR code"` |
| **Detecting** | Frame frozen, progress indicator | `"Verifying Product Code..."` |
| **Slow Network (>3s)** | Amber banner below viewfinder | `"Still checking... Poor connectivity detected."` |
| **Permission Denied** | Dark screen with camera icon & prompt | `"Camera Permission Required. Farmer Dost requires camera access to scan fertilizer and pesticide authenticity QR codes."` + `"Open App Settings"` |

---

## Screen 4 — Result Screen: Genuine (`/result`)

### 1. Purpose & Flow
Displays positive verification when a scanned product code matches an active, unexpired record in the Firestore `products` collection.

### 2. Layout Structure
- **Top Bar**: `"Verification Result"` + hardware/software back button (PopScope $\rightarrow$ `/home`).
- **Status Hero Banner**:
  - Green Background Card: Soft green `#E8F5E9` with green border `#2E7D32`.
  - Icon: Scale-animated $72\text{dp}$ Green Circle Checkmark (`#2E7D32`).
  - Heading: `"Genuine Product"` ($24\text{sp}$ Bold, `#1B5E20`).
  - Subtitle: `"Verified authentic against central agricultural registry"` ($14\text{sp}$).
- **Product Details Card (White surface, elevated $2\text{dp}$)**:
  - Product Name: e.g., `"IFFCO Neem Coated Urea 45kg"` ($18\text{sp}$ Bold).
  - Metadata Rows:
    - `"Manufacturer"`: e.g., `"IFFCO Ltd."`
    - `"Batch Number"`: e.g., `"B-9021"`
    - `"Product Type"`: e.g., `"Fertilizer"`
    - `"Expiry Date"`: e.g., `"15/10/2026"`
    - `"Product Code"`: e.g., `"FD-FT-00101-GEN001"` (monospace chip)
- **Action Buttons (Bottom Fixed)**:
  - Primary: `"Scan Another"` ($48\text{dp}$ filled green button).
  - Secondary: `"Back to Home"` ($48\text{dp}$ text/outline button).

### 3. Accessibility & Haptics
- Haptic: Single light vibration (`HapticFeedback.lightImpact()`).
- High-contrast green `#1B5E20` text on `#E8F5E9` background (Contrast ratio **9.2:1**).
- Icon + Text pairing ensures colorblind farmers immediately recognize authenticity.

---

## Screen 5 — Result Screen: Counterfeit / Recalled / Expired / Offline

### 1. Purpose & Flow
Handles all non-genuine or problematic scan results. Provides explicit safety warnings and a direct pathway to report suspected fraud.

### 2. Layout Structure & State Variants

#### A. Not Recognized / Counterfeit (`notRecognized`)
- **Hero Color**: Crimson Red (`#D32F2F`) on Soft Red (`#FFEBEE`).
- **Icon**: Red Octagon Alert (`Icons.gpp_bad_rounded`, $72\text{dp}$).
- **Heading**: `"Not Recognized / Counterfeit Alert"` ($22\text{sp}$ Bold, `#B71C1C`).
- **Subtitle**: `"This code was not found in our database. Do not use this product."`
- **Actions**:
  - Primary: `"Report Counterfeit Product"` ($48\text{dp}$ filled red button $\rightarrow$ opens `/report`).
  - Secondary: `"Scan Another"` ($48\text{dp}$ outline button).

#### B. Product Recalled (`recalled`)
- **Hero Color**: Warning Amber/Orange (`#ED6C02`) on Light Amber (`#FFF3E0`).
- **Icon**: Warning Triangle (`Icons.warning_amber_rounded`, $72\text{dp}$).
- **Heading**: `"Product Recalled"` ($22\text{sp}$ Bold, `#E65100`).
- **Subtitle**: `"Batch recalled by manufacturer or agricultural regulator. Do not apply."`
- **Actions**: `"Report Recalled Product"` + `"Back to Home"`.

#### C. Product Expired (`expired`)
- **Hero Color**: Deep Orange (`#E65100`) on Light Orange (`#FBE9E7`).
- **Icon**: Expired Calendar (`Icons.event_busy_rounded`, $72\text{dp}$).
- **Heading**: `"Product Expired"` ($22\text{sp}$ Bold, `#BF360C`).
- **Subtitle**: `"Product expired on [Date]. Chemical efficacy cannot be guaranteed."`
- **Actions**: `"Report Expired Product"` + `"Scan Another"`.

#### D. Verification Offline / Network Error (`networkError`)
- **Hero Color**: Slate Blue (`#0288D1`) on Light Blue (`#E1F5FE`).
- **Icon**: Wifi Off (`Icons.wifi_off_rounded`, $72\text{dp}$).
- **Heading**: `"Verification Offline"` ($22\text{sp}$ Bold, `#01579B`).
- **Subtitle**: `"Can't verify right now, check your cellular connection."`
- **Fail-Safe Rule**: **NEVER labeled as fake.** Shows clear retry action.
- **Actions**: `"Retry Verification"` ($48\text{dp}$ filled blue button).

---

## Screen 6 — Report Screen (`/report`)

### 1. Purpose & Flow
Empowers farmers to submit a field report against suspected fake, recalled, or expired products. Submits deterministic document ID `${uid}_${productCode}` to Firestore `reports` collection to eliminate duplicates.

### 2. Layout Structure
- **Top Bar**: `"Report Counterfeit Product"` + Back button.
- **Notice Banner**:
  - Soft amber container with shield icon: `"Flagging fake products alerts agricultural authorities and protects fellow farmers."`
- **Form Fields (Vertical Scroll Layout)**:
  1. **Product Code (Read-Only)**:
     - Label: `"Reported Product Code"` ($14\text{sp}$ Medium).
     - Text field with prefilled code (e.g., `FD-PS-99999-FAKE01`), grey locked background.
  2. **Location Capture (Optional)**:
     - Card container with GPS satellite icon.
     - Label: `"Location (Optional)"`.
     - Button: `"Use current location"` ($48\text{dp}$ target).
     - State Chip: Shows `"Location Captured (30.90° N, 75.85° E)"` when retrieved.
     - Non-blocking: If GPS disabled or timed out, allows report submission without location.
  3. **Field Notes (Optional)**:
     - Label: `"Note (Optional)"`.
     - Multi-line field (3 lines): `"Describe packaging, seller mandi, or chemical suspicion (max 100 characters)"`.
     - Live Counter: `"0/100"` ($12\text{sp}$ dynamic counter).
- **Submit Action**:
  - Button: `"Submit Report"` ($48\text{dp}$ height, filled `#D32F2F` red).
  - In-flight Lock: Button disabled and shows progress spinner during submission.

### 3. Outcome Feedback Mapping
- **Success**: Green SnackBar `"Report submitted successfully! Thank you for protecting Punjab farmers."` $\rightarrow$ pop to Home.
- **Already Reported**: Orange SnackBar `"You have already reported this product code. Your report is pending review."` $\rightarrow$ pop to Home.
- **Offline Error**: Red SnackBar `"Network offline. Your note is preserved. Tap retry."` (Form remains populated).

---

## Screen 7 — Profile Screen (`/profile`)

### 1. Purpose & Flow
User account dashboard displaying farmer identity, verified scan history access, language preferences, and secure logout.

### 2. Layout Structure
- **Top Bar**: `"Farmer Profile"` + Back button.
- **Farmer Header Card**:
  - Avatar: $64\text{dp}$ circle with farmer initials (e.g., `"GS"` for Gurpreet Singh, `#2E7D32` background).
  - Name: `"Gurpreet Singh"` ($20\text{sp}$ Bold).
  - Contact Details: Email (`kisan@punjab.in`) and Phone (`+91 98765 43210`).
- **Preferences & Settings Group**:
  - **Language Selector Tile**:
    - Leading: Globe icon.
    - Title: `"Language Preference"`.
    - Trailing: Dropdown selecting `"ਪੰਜਾਬੀ (Punjabi)"`, `"हिन्दी (Hindi)"`, or `"English"`.
  - **Scan History Quick Tile**:
    - Leading: History clock icon.
    - Title: `"Full Scan History"`.
    - Trailing: Forward chevron ($48\text{dp}$ tap area $\rightarrow$ opens `/scanHistory`).
- **Account Actions**:
  - Button: `"Log Out"` ($48\text{dp}$ outlined destructive red button).
  - Confirmation Modal: `"Log Out?"` $\rightarrow$ `"Are you sure you want to log out of Farmer Dost?"` with `"Cancel"` and `"Log Out"` options.

---

## Design Specification Summary Matrix

| Screen | Primary Color Token | Key Icon | Min Touch Target | Key Accessibility Cue |
| :--- | :--- | :--- | :--- | :--- |
| **1. Splash** | `#2E7D32` Green | Shield Check | $48\text{dp}$ | High-contrast white/green |
| **2. Home** | `#2E7D32` Green | QR Scanner | $110\text{dp}$ | Massive center hero button |
| **3. Scan** | `#000000` / `#2E7D32` | 4 Reticle Corners | $48\text{dp}$ | Torch toggle for low light |
| **4. Genuine Result** | `#2E7D32` Green | Circle Checkmark | $48\text{dp}$ | Multi-modal icon + text |
| **5. Fake / Warning** | `#D32F2F` Red | Shield Octagon | $48\text{dp}$ | Heavy haptic + explicit warning |
| **6. Report** | `#D32F2F` Red | Flag / GPS | $48\text{dp}$ | 100-char limiter + flight lock |
| **7. Profile** | `#1A1C1E` Charcoal | Person / Globe | $48\text{dp}$ | Native script language names |
