# Day 18 — Cryptographic Product Code & QR Generator

This guide documents the implementation and operational instructions for [`backend/generate_codes.py`](file:///c:/Users/Raj%20Singh/Desktop/Farmer-Dost-app/backend/generate_codes.py), a production utility for generating unique, tamper-resistant agricultural product verification codes, syncing them to Cloud Firestore, and producing scannable QR images with Error Correction.

---

## 1. Code Architecture & Design

### Format: `FD-<TYPE>-<SERIAL>-<RANDOM>[CHECKSUM]`
Example: `FD-FT-00123-A7X9KM` (or `FD-FT-00123-A7X9KMW` with 1-character checksum)

- **`FD`**: Farmer Dost platform namespace prefix.
- **`<TYPE>`**: Category code — `"FT"` (Fertilizer) or `"PS"` (Pesticide).
- **`<SERIAL>`**: 5-digit zero-padded batch serial number (`00001` through `99999`).
- **`<RANDOM>`**: 6-character cryptographic token from a 31-character unambiguous alphabet.
- **`[CHECKSUM]`** *(Optional)*: 1-character weighted polynomial checksum for instant client-side typo detection.

---

## 2. Senior Developer Design Decisions

### 2.1 Why Python's `secrets` Module Over `random`
Python's built-in `random` module uses the **Mersenne Twister** pseudo-random number generator (PRNG).
- **The Vulnerability**: The Mersenne Twister is **not cryptographically secure**. After observing just 624 consecutive outputs (approx. 100 codes), an attacker can mathematically reconstruct the internal state of the generator.
- **The Threat to Farmers**: Counterfeiters could predict the exact codes for upcoming genuine batches, printing fake labels that pass scanner verification before the real fertilizer even reaches rural retail points.
- **The Solution**: The `secrets` module accesses the operating system's kernel-level cryptographically secure pseudo-random number generator (CSPRNG — `CryptGenRandom` on Windows, `/dev/urandom` / `getrandom()` on Linux/macOS). Every random character is non-deterministic and cryptographically unpredictable.

### 2.2 Unambiguous Alphabet (Excluding Confusing Glyphs)
Rural farmers often type codes manually on cracked screens or in dusty field conditions. The generator uses:
```text
Alphabet: 23456789ABCDEFGHJKMNPQRSTUVWXYZ (31 characters)
```
- **Excluded**: `0` and `O` (zero vs letter O), `1`, `I`, and `L` (digit 1 vs capital I vs lowercase/capital L).
- **Entropy**: $31^6 = 887,503,681$ (~887.5 million) random combinations for every single serial counter. Even within a batch of 100,000 bags, the collision probability is statistically zero ($< 0.005\%$).

### 2.3 Optional 1-Character Checksum for Local Validation
- **The Approach**: A weighted polynomial sum of character positions mod 31:
  $$\text{Checksum} = \left(\sum_{i=1}^{N} i \times \text{char\_val}(c_i)\right) \pmod{31}$$
- **The Benefit**: Allows the Flutter mobile app to immediately reject mistyped codes in **$O(1)$ locally** before sending any Firestore request. If a farmer mistypes a letter or transposes two adjacent digits, the checksum fails with zero network latency.
- **Toggle**: Use `--checksum` flag when desired, or omit it to generate pure 6-character random tokens.

### 2.4 QR Code Error Correction (Level M: 15%)
Fertilizer and pesticide bags endure harsh handling: dragging across dirt, rain splashes, and label scratching.
- Setting QR Error Correction to **Level M** (or Q) allows the scanner to decode the barcode even if up to **15% to 25% of the QR pattern is torn, scratched, or soiled**.

---

## 3. CSV Input Template (`backend/products_input.csv`)

Located in [`backend/products_input.csv`](file:///c:/Users/Raj%20Singh/Desktop/Farmer-Dost-app/backend/products_input.csv):

```csv
name,manufacturer,batch,type,manufactureDate,expiryDate,dosage,count
Punjab Shaktiman Neem Coated Urea 45kg,Malwa Kisan Agro Fertilizers Ltd,MKA-UREA-2026-B1,fertilizer,2026-03-01,2028-02-28,45 kg per acre during first canal watering for wheat and paddy,5
Majha Gold DAP 18:46:0 50kg,Doaba Agri Nutrients Cooperative,DAN-DAP-2026-D4,fertilizer,2026-02-15,2028-02-14,50 kg per acre as basal dose at sowing time,5
Kisan Kavach Chlorpyrifos 20% EC 1L,Sutlej Crop Protection Solutions,SCP-CPS-2026-09,pesticide,2026-04-10,2028-04-09,1 liter per acre diluted in 200 liters of water for termite control,5
```

---

## 4. How to Run the Script Step-by-Step

### Step 1: Install Dependencies
```powershell
pip install -r backend/requirements.txt
```
*(Installs `firebase-admin`, `qrcode[pil]`, and `pillow`).*

### Step 2: Run 10,000-Code Cryptographic Self-Test
Validates in-memory uniqueness, speed, and checksum validation:
```powershell
python backend/generate_codes.py --test --checksum
```
*Expected Output:*
```text
=======================================================
[*] RUNNING DAY 18 SELF-TEST: Generating 10,000 Codes
=======================================================
Generated:    10,000 codes in 0.145 seconds (69,192 codes/sec)
Unique Codes: 10,000
Duplicates:   0
Checksum Checks: 10,000 tested | Failures: 0
[PASS] Self-Test Succeeded: 0 collisions, 100% checksum accuracy.
=======================================================
```

### Step 3: Download `serviceAccountKey.json` from Firebase (For Live Sync)
1. Open [Firebase Console](https://console.firebase.google.com/) -> Select your project.
2. Click **Project Settings** (gear icon) -> **Service accounts** tab.
3. Click **Generate new private key** -> Click **Generate key**.
4. Save the downloaded JSON file to `backend/serviceAccountKey.json`.
5. *(Note: This file is ignored by `.gitignore` and must never be committed).*

### Step 4: Run Batch Generation from CSV
To generate codes, upload them to Firestore, and save QR PNGs:
```powershell
python backend/generate_codes.py --csv backend/products_input.csv
```
*(If you want to test locally without connecting to Firestore, add `--dry-run`).*

### Step 5: Run Single-Batch via Command-Line
To quickly generate $N$ codes for one batch:
```powershell
python backend/generate_codes.py --type FT --batch PKR-2026-B1 --count 10 --name "Kisan Urea 45kg" --manufacturer "Punjab Agro Ltd"
```

---

## 5. Output Artifacts

1. **QR Code PNGs**: Saved to `backend/qr_output/` (e.g. `FD-FT-00001-SC38Z8.png`).
2. **Audit Log CSV**: Saved to `backend/codes_generated.csv`:
   ```csv
   code,name,batch,type,manufacturer,generated_at
   FD-FT-00001-GKK8MY,Punjab Shaktiman Neem Coated Urea 45kg,MKA-UREA-2026-B1,fertilizer,Malwa Kisan Agro Fertilizers Ltd,2026-10-25T22:08:56.805148
   ```
3. **Cloud Firestore**: Documents written to collection `/products/{code}` matching the Day 15 schema.
