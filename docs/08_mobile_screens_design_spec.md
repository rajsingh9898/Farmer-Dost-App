# Day 8 — Mobile Screen UI Design Specifications (375x812)

Design specification for **Screen 1 (Splash Screen)** and **Screen 2 (Home Screen)** of the **Farmer Dost App**, formatted for standard mobile frames (`375px × 812px`) and Figma auto-layout implementation.

---



## Design System Tokens & Guidelines

- **Frame Aspect Ratio**: `375 × 812` (Standard iPhone/Android mobile frame)
- **Primary Color**: `#2E7D32` (Agriculture Trust Green)
- **Alert Accent Color**: `#D32F2F` (Crimson Red)
- **Background**: `#FFFFFF` / Light Gray `#F8F9FA`
- **Typography**: Inter / Poppins (Sans-serif)
- **Weights Used**: Regular (`400`) & Medium (`500`) (strictly max 2 weights)



---

## Screen Specifications

### Screen 1 — Splash Screen
- **Background**: Plain white (`#FFFFFF`)
- **Logo**: Centered Green Shield icon with white checkmark (`48px × 48px`, color `#2E7D32`)
- **App Title**: `"Farmer Dost"` (22px, Medium weight, `#1A1C1E`)
- **Tagline**: `"Scan. Verify. Trust."` (14px, Regular weight, muted `#74777F`)
- **Layout**: Centered Vertical Auto-Layout

### Screen 2 — Home Screen
- **Top Bar**: `"Farmer Dost"` title on left (`20px Medium`), Circular profile avatar on right (`36px` diameter)
- **Center Hero Element**: Single large circular **Scan** button (`110px` diameter, `#2E7D32` fill, white QR scanner icon)
- **Sublabel**: `"Tap to scan"` (`16px Medium`)
- **Bottom Section**: `"Recent scans"` header (`16px Medium`), 3 reusable row components:
  1. `KRIBHCO Urea 50kg` — Genuine Green Checkmark Badge (`#2E7D32`)
  2. `Counterfeit Batch #456` — Fake Red Warning Badge (`#D32F2F`)
  3. `IFFCO NPK 12-32-16` — Genuine Green Checkmark Badge (`#2E7D32`)
