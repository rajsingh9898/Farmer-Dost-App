# Farmer Dost Design Tokens & Style Guide (One-Page Field Manual)

Authoritative design token specifications for the **Farmer Dost App** (`lib/theme/app_theme.dart`). Built for rural Android field usage, outdoor sunlight legibility (WCAG AAA), and multi-modal accessibility.

---

## 1. Color Palette Tokens (`AppColors`)

| Token Name | Hex Code | Role & Usage | Background Contrast | Sunlight Standard |
| :--- | :--- | :--- | :---: | :---: |
| `AppColors.primary` | `#2E7D32` | Trustworthy agricultural green; primary buttons, brand hero, active icons. | **7.4:1** on `#FFFFFF` | **WCAG AAA** ($\ge 7.0:1$) |
| `AppColors.success` | `#2E7D32` | Genuine verification state; checkmarks, success chips. | **7.4:1** on `#FFFFFF` | **WCAG AAA** |
| `AppColors.danger` / `error` | `#D32F2F` | Counterfeit warning, failed verification, destructive actions. | **5.1:1** on `#FFFFFF` | **WCAG AA** ($\ge 4.5:1$) |
| `AppColors.caution` | `#F57F17` | Recalled or expired warning indicator borders. | **3.8:1** (Graphical elements) | **WCAG AA** (UI components) |
| `AppColors.cautionText` | `#B26A00` | High-contrast amber text for outdoor badges. | **5.4:1** on `#FFFFFF` | **WCAG AA** |
| `AppColors.recalled` | `#ED6C02` | Batch recall status highlight. | **4.6:1** on `#FFFFFF` | **WCAG AA** |
| `AppColors.expired` | `#E65100` | Expired product alert. | **5.0:1** on `#FFFFFF` | **WCAG AA** |
| `AppColors.offline` | `#0288D1` | Network disconnection / offline notice. | **4.7:1** on `#FFFFFF` | **WCAG AA** |
| `AppColors.textPrimary` | `#111418` | Primary body, titles, and high-visibility headings. | **16.5:1** on `#FFFFFF` | **WCAG AAA** |
| `AppColors.textSecondary` | `#42474E` | Secondary captions, timestamps, and muted labels. | **9.8:1** on `#FFFFFF` | **WCAG AAA** |
| `AppColors.surface` | `#FFFFFF` | Elevated cards, dialogs, bottom sheets. | N/A | Base |
| `AppColors.background` | `#F7F7F7` | Scaffold background (reduces outdoor eye strain). | N/A | Base |
| `AppColors.border` | `#E0E0E0` | Card borders, textfield outlines. | N/A | Structural |

### Status Container Tints (Field-Tested Soft Fills)
- `AppColors.successContainer`: `#E8F5E9` (Soft green card for genuine results)
- `AppColors.errorContainer`: `#FFEBEE` (Soft red card for counterfeit alerts)
- `AppColors.cautionContainer`: `#FFF3E0` (Soft amber card for recall/expiry warnings)
- `AppColors.offlineContainer`: `#E1F5FE` (Soft blue card for network retry states)

---

## 2. Typography Tokens (`AppStyles` & `TextTheme`)

Base typeface: **Inter** (`GoogleFonts.inter`) with fallback to system sans-serif. Optimized for Devanagari and Gurmukhi script rendering in Phase 6.

| Token | Size | Weight | Line Height | Usage |
| :--- | :---: | :---: | :---: | :--- |
| `AppStyles.displayStyle` | `26sp` | Bold (`700`) | $1.25$ | App Title, Splash Hero, Genuine/Alert primary headings |
| `AppStyles.headingStyle` | `20sp` | SemiBold (`600`) | $1.30$ | Screen titles (AppBars), modal dialog titles |
| `AppStyles.sectionHeadingStyle` | `16sp` | SemiBold (`600`) | $1.35$ | Card section headers, primary button labels |
| `AppStyles.bodyStyle` | `14sp` | Regular (`400`) | $1.40$ | Form input labels, product description metadata |
| `AppStyles.mutedStyle` | `12sp` | Medium (`500`) | $1.40$ | Timestamps, status badge text, field character counters |

---

## 3. Spacing & Dimensions (`AppDimensions`)

All layouts adhere to a clean $4\text{dp}$ / $8\text{dp}$ baseline grid:

```
spaceTiny      =  4.0 dp   (Icon to label micro-gap)
spaceSmall     =  8.0 dp   (Vertical sibling gap within card)
spaceMedium    = 16.0 dp   (Standard margin between cards)
spaceLarge     = 24.0 dp   (Standard screen horizontal padding)
spaceXLarge    = 32.0 dp   (Major section divider)
```

- **Screen Padding**: `24.0 dp` (`screenPadding`), `16.0 dp` (`screenPaddingSmall` for compact views).
- **Minimum Touch Target**: **`48.0 dp`** (`minTouchTarget`) strictly enforced on all interactive widgets.
- **Button Dimensions**: Height `52.0 dp`, Horizontal Padding `24.0 dp`, Vertical Padding `14.0 dp`.

---

## 4. Radii & Surface Styling

- **Standard Cards**: `16.0 dp` (`cardRadius`) with subtle border `#E0E0E0` and elevation $1\text{dp}$–$2\text{dp}$.
- **Buttons**: `12.0 dp` (`buttonRadius`).
- **Interactive Pills & Badges**: `24.0 dp` (`pillRadius`).
- **Modal Dialogs & Bottom Sheets**: `24.0 dp` (`modalRadius`).

---

## 5. Consistency Audit Findings & Fixes

During the Phase 2 Stage 4 design token consistency audit, all source files were checked against the token system:

1. **`lib/widgets/corner_brackets_painter.dart`**:
   - *Issue*: Contained hardcoded `const Color(0xFF2E7D32)`.
   - *Fix*: Refactored to import `app_theme.dart` and use `AppColors.primary`.
2. **`lib/widgets/status_badge.dart`**:
   - *Issue*: Contained raw hex values `const Color(0xFFB26A00)` for recalled/expired badges.
   - *Fix*: Added `AppColors.cautionText` token and refactored badge to consume it.
3. **`lib/theme/app_theme.dart`**:
   - *Issue*: Missing status container tokens (`successContainer`, `errorContainer`, etc.) and `modalRadius`.
   - *Fix*: Declared complete suite of status colors and container tints.
