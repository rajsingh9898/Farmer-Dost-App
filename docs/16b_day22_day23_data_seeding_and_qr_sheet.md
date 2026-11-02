# Phase 4: Product Catalog Seeding, Counterfeit Generation & Printable QR Sheet

Authoritative guide for **Stage 11** of the **Farmer Dost App**: seeding 18 realistic agricultural product batches, generating well-formed fake and tampered verification codes, and compiling a printable demo QR sheet for real-world smartphone scanning.

---

## 1. 18 Seed Products (Fictional Punjabi Manufacturers)

Catalog configured in [`backend/products_input.csv`](file:///c:/Users/Raj%20Singh/Desktop/Farmer-Dost-app/backend/products_input.csv):

| # | Product Name | Manufacturer (Punjab) | Batch | Type | Status | Expiry Date |
| :-: | :--- | :--- | :--- | :---: | :---: | :---: |
| **1** | Doaba Shaktiman Neem Coated Urea 45kg | Doaba Agri-Tech Corp | `DAT-UR-2026-A1` | Fertilizer | **Active** | 2028-02-28 |
| **2** | Satluj Super DAP 18:46:0 50kg | Satluj Crop Science Ltd | `SCS-DAP-2026-03` | Fertilizer | **Active** | 2028-02-14 |
| **3** | Majha MOP Muriate of Potash 50kg | Majha Agro Solutions | `MAS-POT-2026-P2` | Fertilizer | **Active** | 2028-01-19 |
| **4** | Beas Zinc Sulphate 33% Monohydrate 5kg | Beas Bio-Fertilizers Ltd | `BBF-ZN-2026-Z7` | Fertilizer | **Active** | 2028-04-04 |
| **5** | Punjab Kisan NPK 12:32:16 Complex | Punjab Kisan Sahayta Udyog | `PKS-NPK-2026-N4` | Fertilizer | **Active** | 2028-02-27 |
| **6** | Malwa Single Super Phosphate (SSP) 50kg | Malwa Crop Protection Ltd | `MCP-SSP-2026-S1` | Fertilizer | **Active** | 2028-03-09 |
| **7** | Ravi Bio-Phosphate Rich Organic Manure | Ravi Agri Chem Cooperative | `RAC-PRM-2026-R8` | Fertilizer | **Active** | 2028-03-31 |
| **8** | Doaba Rakshak Chlorpyrifos 20% EC 1L | Doaba Agri-Tech Corp | `DAT-CPS-2026-C9` | Pesticide | **Active** | 2028-03-24 |
| **9** | Satluj Kavach Emamectin Benzoate 5% SG | Satluj Crop Science Ltd | `SCS-EMB-2026-E5` | Pesticide | **Active** | 2028-04-11 |
| **10** | Majha Prahar Pretilachlor 50% EC 1L | Majha Agro Solutions | `MAS-PRT-2026-M2` | Pesticide | **Active** | 2028-05-01 |
| **11** | Beas Teer Imidacloprid 17.8% SL 250ml | Beas Bio-Fertilizers Ltd | `BBF-IMI-2026-I3` | Pesticide | **Active** | 2028-03-17 |
| **12** | Punjab Kisan Agni Bispyribac Sodium 10% SC | Punjab Kisan Sahayta Udyog | `PKS-BPS-2026-B6` | Pesticide | **Active** | 2028-04-19 |
| **13** | Malwa Dhoom Atrazine 50% WP 500g | Malwa Crop Protection Ltd | `MCP-ATZ-2026-A8` | Pesticide | **Active** | 2028-05-09 |
| **14** | Ravi Amrit Soluble Sulphur 80% WDG 3kg | Ravi Agri Chem Cooperative | `RAC-SLF-2026-S4` | Fertilizer | **Active** | 2028-03-29 |
| **15** | Doaba Bio-Potash 20% SL (Contaminated Batch) | Doaba Agri-Tech Corp | `DAT-REC-2025-X9` | Fertilizer | **Recalled** | 2027-11-09 |
| **16** | Satluj Monocrotophos 36% SL (Safety Recall) | Satluj Crop Science Ltd | `SCS-RCL-2025-M7` | Pesticide | **Recalled** | 2027-10-04 |
| **17** | Majha Dimethoate 30% EC (Expired Stock) | Majha Agro Solutions | `MAS-EXP-2022-D1` | Pesticide | **Expired** | 2024-01-09 |
| **18** | Beas Ammonium Sulphate 20.6% N (Expired Batch) | Beas Bio-Fertilizers Ltd | `BBF-EXP-2022-A9` | Fertilizer | **Expired** | 2024-02-13 |

---

## 2. Fake & Tampered Codes (Absent from Database)

Generated via `python backend/generate_codes.py --fake-only`:

1. **5 Well-Formed Counterfeits**:
   - Syntactically valid under `^FD-(FT|PS)-\d{5}-[A-Z0-9]{6,12}$`, but absent from the database:
     - `FD-FT-99001-7E89JK`
     - `FD-PS-99002-ZJHWKK`
     - `FD-FT-99003-386FFR`
     - `FD-PS-99004-WW7TCH`
     - `FD-FT-99005-X7B6VH`
   - *Expected App Behavior*: Matches regex $\rightarrow$ queries Firestore $\rightarrow$ document not found $\rightarrow$ `VerificationStatus.notRecognized` (Alert Red Screen with "Report Product" CTA).
2. **1 Tampered Code**:
   - Mutated from valid base `FD-FT-12345-ZY83CQ` by altering one character to `FD-FT-12345-ZY88CQ`.
   - *Expected App Behavior*: Unregistered code $\rightarrow$ triggers counterfeit alert.

---

## 3. Printable Demo QR Sheet (`demo_qr_sheet.html`)

- **File Location**: [`backend/qr_output/demo_qr_sheet.html`](file:///c:/Users/Raj%20Singh/Desktop/Farmer-Dost-app/backend/qr_output/demo_qr_sheet.html)
- **Features**:
  - Embedded Base64 QR code PNG images with Error Correction Level M (15%).
  - 4 clearly labeled demonstration cards:
    1. **Genuine Product**: Green badge, full manufacturer & batch metadata.
    2. **Recalled Batch**: Amber badge, recall notice and dealer return advisory.
    3. **Expired Product**: Orange badge, chemical degradation warning.
    4. **Suspected Counterfeit**: Red badge, unrecognized security code alert.
  - Print-optimized CSS (`@media print`) formatted for standard A4 paper.
  - Test by opening in Google Chrome and pressing `Ctrl + P` to print or save as PDF.
