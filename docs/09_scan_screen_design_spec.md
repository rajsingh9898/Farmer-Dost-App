# Day 9 — Scan Screen Camera UI Design Specifications (375x812)

Design specification for the full-screen **Scan Camera Screen** of the **Farmer Dost App**, detailing layout, state variants, and universal camera UX patterns.

---

## Layout Structure (Top to Bottom)

1. **Top Bar (Overlay on Camera View)**:
   - Left: Close/Back `"X"` icon (`24px`, `#FFFFFF`) to exit scanner.
   - Right: Torch/Flashlight toggle icon (`24px`, `#FFFFFF`).
2. **Viewfinder Backdrop**:
   - Full-frame (`375px × 812px`) dark camera feed rectangle.
3. **Scan Target**:
   - Centered `200px × 200px` square target made strictly of **4 corner brackets only** (`3.5px` stroke green `#2E7D32`, rounded tips).
4. **Instruction Text**:
   - Centered below frame: `"Point camera at the QR code"` (`15px Medium`, `#FFFFFF`).

---

## State Variants

- **Default / Searching State**: 4 corner brackets in `#2E7D32` Green.
- **Detecting State**: Corner brackets turn glowing vibrant neon green (`#00E676`) with active reading feedback.
- **Low-Light Hint State**: Camera feed darkens, pill badge `"Tap for light"` appears near torch icon.
