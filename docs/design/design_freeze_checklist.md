# Phase 2: Design Freeze Checklist & Asset Export Specification

Authoritative sign-off document freezing the UI/UX design, visual tokens, accessibility contracts, and file naming standards for the **Farmer Dost App** before advancing to Phase 3 (Backend Core).

---

## 1. Asset Export & File Naming Conventions (`docs/design/`)

All mockups, exported frames, wireframes, and design documentation in `docs/design/` must adhere to this standardized naming convention:

| File Name | Screen / Asset | Dimensions | Format | Key Content |
| :--- | :--- | :---: | :---: | :--- |
| `01_splash.png` | Screen 1 — Splash | `375 × 812` | PNG | Centered shield logo, title, tagline, bottom progress indicator. |
| `02_home.png` | Screen 2 — Home | `375 × 812` | PNG | Top bar with avatar, $110\text{dp}$ circular scan hero, 3 recent scans. |
| `03_scan.png` | Screen 3 — Scanner Viewfinder | `375 × 812` | PNG | Full-screen camera, $260\text{dp}$ green corner reticle, torch toggle. |
| `04_result_genuine.png` | Screen 4 — Result: Genuine | `375 × 812` | PNG | Green checkmark ($72\text{dp}$), verified product details card, actions. |
| `05_result_fake.png` | Screen 5 — Result: Counterfeit | `375 × 812` | PNG | Crimson red alert octagon, fraud warning, "Report Product" button. |
| `05b_result_recalled.png` | Screen 5b — Result: Recalled | `375 × 812` | PNG | Amber warning triangle, recall advisory banner, report option. |
| `05c_result_expired.png` | Screen 5c — Result: Expired | `375 × 812` | PNG | Deep orange calendar X icon, chemical degradation alert. |
| `05d_result_offline.png` | Screen 5d — Result: Offline | `375 × 812` | PNG | Blue wifi-off icon, fail-safe retry button (never labeled fake). |
| `06_report.png` | Screen 6 — Report Fraud | `375 × 812` | PNG | Locked product code, GPS location card, 100-char note, submit lock. |
| `07_profile.png` | Screen 7 — Farmer Profile | `375 × 812` | PNG | Initials avatar, contact info, language selector, logout button. |
| `08_scan_history.png` | Screen 8 — Scan History | `375 × 812` | PNG | Paginated history list, pull-to-refresh, detail bottom sheet. |
| `Farmer_Dost_Screens.pdf`| Complete Screen Deck | Multi-page | PDF | Full presentation deck of all mobile screens. |
| `style_guide.md` | One-Page Style Guide | Markdown | MD | Color tokens, typography, radii, spacing, contrast metrics. |

---

## 2. Phase 2 Design Freeze Verification Matrix

| # | Verification Criteria | Target Specification | Status | Evidence / Implementation |
| :-: | :--- | :--- | :-: | :--- |
| **1** | **Screen Coverage** | All 7 core mobile screens specified with all states | **PASS** | Detailed in [docs/08_mobile_screens_design_spec.md](file:///c:/Users/Raj%20Singh/Desktop/Farmer-Dost-app/docs/08_mobile_screens_design_spec.md) |
| **2** | **Outdoor Sunlight Contrast** | WCAG AAA ($\ge 7.0:1$) for headings/body | **PASS** | Primary green $7.4:1$, text $16.5:1$; verified in [style_guide.md](file:///c:/Users/Raj%20Singh/Desktop/Farmer-Dost-app/docs/design/style_guide.md) |
| **3** | **Multi-Modal Accessibility** | Never color alone to convey meaning | **PASS** | Every status pairs icon shape + color + label (CircleCheck vs OctagonAlert vs Triangle) |
| **4** | **Minimum Touch Target** | $\ge 48\text{dp} \times 48\text{dp}$ on all interactive controls | **PASS** | Enforced via `AppDimensions.minTouchTarget` and widget button heights ($52\text{dp}$) |
| **5** | **1.3x Font Scale Survivability** | Layouts survive system font scaling without overflow | **PASS** | Verified via test `day38_report_screen_test.dart` and flexible scroll layouts |
| **6** | **Unified Result Screen** | Single template for all 6 outcomes | **PASS** | Implemented in `lib/screens/result_screen.dart` |
| **7** | **Fail-Safe Offline Contract** | Network errors NEVER shown as fake | **PASS** | Isolated `VerificationStatus.networkError` maps to retry state |
| **8** | **Centralized Design Tokens** | Single source of truth for styles | **PASS** | `lib/theme/app_theme.dart` governs all colors, styles, and radii |
| **9** | **Zero Hardcoded Hex Literals** | Codebase consistency audit | **PASS** | Audited; `CornerBracketsPainter` and `StatusBadge` cleaned |
| **10** | **Centralized String Catalog** | UI text decoupled from widgets | **PASS** | All customer copy stored in `lib/l10n/app_strings.dart` |

---

## 3. Design Freeze Sign-Off

- **Status**: **FROZEN & LOCKED**
- **Date**: Phase 2 Conclusion
- **Sign-off Lead**: Senior Mobile Engineer (Tech Lead)
- **Next Phase**: Phase 3 (Backend Core — Firestore Schema, Auth, Code Generation & Verification Service)
