#!/usr/bin/env python3
"""
Farmer Dost App — Day 18: Product Code & QR Generator
Generates unique, cryptographically secure, hard-to-guess product codes,
creates high-res QR code PNGs with error correction, logs summaries to CSV,
and persists genuine product records to Cloud Firestore.

Format: FD-<TYPE>-<SERIAL>-<RANDOM>[CHECKSUM]
- TYPE: "FT" (Fertilizer) or "PS" (Pesticide)
- SERIAL: 5-digit zero-padded batch sequence number (e.g., 00123)
- RANDOM: 6 characters from unambiguous 32-char alphabet (excludes 0, O, 1, I, L)
- Optional Checksum: 1 character for instant client-side typo detection
"""

import os
import sys
import csv
import time
import secrets
import argparse
from datetime import datetime

# Windows Console UTF-8 compatibility
if sys.platform.startswith("win"):
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass


def load_dotenv(dotenv_filename: str = ".env"):
    """
    Zero-dependency .env loader that populates os.environ
    by searching parent and current directories.
    """
    candidates = [
        dotenv_filename,
        os.path.join("..", dotenv_filename),
        os.path.join(os.path.dirname(__file__), "..", dotenv_filename),
        os.path.join(os.path.dirname(__file__), dotenv_filename),
    ]
    for path in candidates:
        if os.path.isfile(path):
            try:
                with open(path, "r", encoding="utf-8") as f:
                    for line in f:
                        line = line.strip()
                        if line and not line.startswith("#") and "=" in line:
                            k, v = line.split("=", 1)
                            k, v = k.strip(), v.strip().strip("\"'")
                            if k and k not in os.environ:
                                os.environ[k] = v
                break
            except Exception:
                pass

# Automatically load .env on script import/start
load_dotenv()

# ---------------------------------------------------------------------------
# Cryptographic & Formatting Constants
# ---------------------------------------------------------------------------
# 32-character alphabet excluding easily confused glyphs: 0, O, 1, I, L
UNAMBIGUOUS_ALPHABET = "23456789ABCDEFGHJKMNPQRSTUVWXYZ"
ALPHABET_SET = set(UNAMBIGUOUS_ALPHABET)
ALPHABET_MAP = {char: idx for idx, char in enumerate(UNAMBIGUOUS_ALPHABET)}
ALPHABET_LEN = len(UNAMBIGUOUS_ALPHABET)

# Fallback character map for prefix letters like 'F', 'D'
def char_to_val(c: str) -> int:
    c = c.upper()
    if c in ALPHABET_MAP:
        return ALPHABET_MAP[c]
    return ord(c) % ALPHABET_LEN


def calculate_checksum(code_payload: str) -> str:
    """
    Computes a 1-character weighted polynomial checksum (mod len(alphabet))
    over alphanumeric characters in the code.
    Detects single-character substitution errors and adjacent transpositions.
    """
    clean_chars = [c for c in code_payload.upper() if c.isalnum()]
    weighted_sum = sum((idx + 1) * char_to_val(ch) for idx, ch in enumerate(clean_chars))
    return UNAMBIGUOUS_ALPHABET[weighted_sum % ALPHABET_LEN]


def verify_checksum(full_code: str) -> bool:
    """Validates the 1-character checksum of a code."""
    clean = full_code.replace("-", "").strip().upper()
    if len(clean) < 2:
        return False
    payload, expected_chk = clean[:-1], clean[-1]
    return calculate_checksum(payload) == expected_chk


def generate_random_part(length: int = 6) -> str:
    """
    Uses Python's secrets module (CSPRNG) to generate unpredictable characters.
    32^6 = 1,073,741,824 (~1.07 Billion) combinations per serial number.
    """
    return "".join(secrets.choice(UNAMBIGUOUS_ALPHABET) for _ in range(length))


def generate_single_code(
    product_type: str,
    serial: int,
    with_checksum: bool = False,
) -> str:
    """
    Generates a single product code in the standard format:
    FD-<TYPE>-<SERIAL>-<RANDOM>[CHECKSUM]
    e.g.: FD-FT-00123-A7X9KM
    """
    norm_type = product_type.upper().strip()
    if norm_type in ("FERTILIZER", "FT"):
        t_code = "FT"
    elif norm_type in ("PESTICIDE", "PS"):
        t_code = "PS"
    else:
        t_code = norm_type[:2]

    serial_str = f"{serial:05d}"
    random_str = generate_random_part(6)
    base_code = f"FD-{t_code}-{serial_str}-{random_str}"

    if with_checksum:
        chk = calculate_checksum(base_code)
        return f"{base_code}{chk}"
    return base_code


# ---------------------------------------------------------------------------
# QR Code Generator
# ---------------------------------------------------------------------------
def generate_qr_image(code: str, output_dir: str, error_level: str = "M") -> str:
    """
    Generates high-contrast QR code PNG with Error Correction Level M (15%) or Q (25%).
    Ensures QR codes can still be decoded when printed fertilizer bags suffer
    minor surface tears, scratches, or dust in the field.
    """
    try:
        import qrcode
        from qrcode.constants import ERROR_CORRECT_M, ERROR_CORRECT_Q, ERROR_CORRECT_H
    except ImportError:
        print("[-] Notice: 'qrcode' or 'pillow' is not installed. Run: pip install qrcode[pil]")
        return ""

    ec_map = {
        "M": ERROR_CORRECT_M,
        "Q": ERROR_CORRECT_Q,
        "H": ERROR_CORRECT_H,
    }
    correction = ec_map.get(error_level.upper(), ERROR_CORRECT_M)

    os.makedirs(output_dir, exist_ok=True)
    safe_filename = code.replace("/", "_").replace("\\", "_") + ".png"
    file_path = os.path.join(output_dir, safe_filename)

    qr = qrcode.QRCode(
        version=None,
        error_correction=correction,
        box_size=10,
        border=4,
    )
    qr.add_data(code)
    qr.make(fit=True)

    img = qr.make_image(fill_color="black", back_color="white")
    img.save(file_path)
    return file_path


# ---------------------------------------------------------------------------
# Firestore Database Connection & Persistence
# ---------------------------------------------------------------------------
def initialize_firestore(service_account_path: str = "serviceAccountKey.json"):
    """
    Initializes Firebase Admin SDK from serviceAccountKey.json.
    Never prints or logs private key credentials.
    """
    try:
        import firebase_admin
        from firebase_admin import credentials, firestore
    except ImportError:
        print("[-] Notice: 'firebase-admin' is not installed. Run: pip install firebase-admin")
        return None

    # Search common credential paths
    candidates = [
        service_account_path,
        os.path.join("backend", service_account_path),
        os.path.join(os.path.dirname(__file__), "serviceAccountKey.json"),
        os.path.join(os.path.dirname(__file__), service_account_path),
    ]

    resolved_path = None
    for cand in candidates:
        if os.path.isfile(cand):
            resolved_path = cand
            break

    if not resolved_path:
        print(f"[-] Credentials file not found at: {service_account_path}")
        print("    Please place serviceAccountKey.json in the backend/ folder.")
        return None

    try:
        if not firebase_admin._apps:
            cred = credentials.Certificate(resolved_path)
            firebase_admin.initialize_app(cred)
        return firestore.client()
    except Exception as e:
        print(f"[-] Error initializing Firebase Admin: {e}")
        return None


def save_product_to_firestore(db, product_data: dict, max_retries: int = 5) -> str:
    """
    Writes product record to Firestore 'products' collection.
    Document ID = product code ($O(1) direct scanner lookup).
    Checks for collisions first and retries with a fresh random code if needed.
    """
    from google.cloud import firestore

    code = product_data["code"]
    type_code = product_data.get("type_code", "FT")
    serial = product_data.get("serial", 1)
    with_chk = product_data.get("with_checksum", False)

    for attempt in range(max_retries):
        doc_ref = db.collection("products").document(code)
        doc = doc_ref.get()

        if not doc.exists:
            # Code is unique! Persist to Firestore matching Day 15 schema
            payload = {
                "code": code,
                "name": product_data["name"],
                "manufacturer": product_data["manufacturer"],
                "batch": product_data["batch"],
                "type": product_data["type"],
                "status": "active",
                "manufactureDate": product_data.get("manufactureDate"),
                "expiryDate": product_data.get("expiryDate"),
                "createdAt": firestore.SERVER_TIMESTAMP,
            }
            if product_data.get("dosage"):
                payload["dosage"] = product_data["dosage"]

            doc_ref.set(payload)
            return code

        # Ultra-rare collision (1 in a billion): retry with a fresh code
        print(f"[!] Collision detected for {code}. Generating fresh random token...")
        code = generate_single_code(type_code, serial, with_checksum=with_chk)

    raise RuntimeError(f"Failed to generate a unique code after {max_retries} attempts.")


# ---------------------------------------------------------------------------
# Self-Test Mode: 10,000 Codes Collision & Performance Benchmark
# ---------------------------------------------------------------------------
def run_self_test(num_codes: int = 10000, with_checksum: bool = True):
    """
    Generates N codes in memory using secrets module,
    asserts 100% uniqueness, and verifies checksum integrity.
    """
    print("\n=======================================================")
    print(f"[*] RUNNING DAY 18 SELF-TEST: Generating {num_codes:,} Codes")
    print("=======================================================")

    codes = []
    start_time = time.perf_counter()

    for i in range(1, num_codes + 1):
        t = "FT" if i % 2 == 0 else "PS"
        code = generate_single_code(t, i, with_checksum=with_checksum)
        codes.append(code)

    elapsed = time.perf_counter() - start_time
    rate = num_codes / elapsed if elapsed > 0 else 0

    unique_count = len(set(codes))
    has_duplicates = unique_count != num_codes

    print(f"Generated:    {num_codes:,} codes in {elapsed:.3f} seconds ({rate:,.0f} codes/sec)")
    print(f"Unique Codes: {unique_count:,}")
    print(f"Duplicates:   {num_codes - unique_count}")

    # Checksum validation
    checksum_failures = 0
    if with_checksum:
        for c in codes:
            if not verify_checksum(c):
                checksum_failures += 1
        print(f"Checksum Checks: {num_codes:,} tested | Failures: {checksum_failures}")

    # Sample codes display
    print("\nSample Generated Codes:")
    for sample in codes[:5]:
        print(f"   - {sample}")

    print("-------------------------------------------------------")
    if not has_duplicates and checksum_failures == 0:
        print("[PASS] Self-Test Succeeded: 0 collisions, 100% checksum accuracy.")
    else:
        print("[FAIL] Self-Test Failed!")
    print("=======================================================\n")
    return not has_duplicates and checksum_failures == 0


# ---------------------------------------------------------------------------
# Batch CSV Processor
# ---------------------------------------------------------------------------
def process_csv_file(
    csv_path: str,
    output_dir: str,
    qr_dir: str,
    db=None,
    with_checksum: bool = False,
    dry_run: bool = False,
):
    """
    Reads products_input.csv and processes each batch row.
    """
    if not os.path.isfile(csv_path):
        print(f"[-] CSV file not found: {csv_path}")
        return

    generated_summary_path = os.path.join(output_dir, "codes_generated.csv")
    file_exists = os.path.isfile(generated_summary_path)

    os.makedirs(qr_dir, exist_ok=True)

    summary_records = []
    total_generated = 0

    with open(csv_path, mode="r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row_idx, row in enumerate(reader, start=1):
            name = row.get("name", "Unknown Product").strip()
            manufacturer = row.get("manufacturer", "Unknown").strip()
            batch = row.get("batch", f"BATCH-{row_idx}").strip()
            raw_type = row.get("type", "fertilizer").strip().lower()
            product_type = "fertilizer" if "fert" in raw_type or raw_type == "ft" else "pesticide"
            type_code = "FT" if product_type == "fertilizer" else "PS"

            count = int(row.get("count", 5))
            dosage = row.get("dosage", "").strip() or None

            # Dates
            mfg_str = row.get("manufactureDate", "").strip()
            exp_str = row.get("expiryDate", "").strip()

            mfg_date = datetime.strptime(mfg_str, "%Y-%m-%d") if mfg_str else datetime.now()
            exp_date = datetime.strptime(exp_str, "%Y-%m-%d") if exp_str else datetime.now()

            print(f"\n[+] Processing Batch: {name} ({batch}) | Count: {count}")

            for i in range(1, count + 1):
                code = generate_single_code(type_code, i, with_checksum=with_checksum)

                prod_dict = {
                    "code": code,
                    "name": name,
                    "manufacturer": manufacturer,
                    "batch": batch,
                    "type": product_type,
                    "type_code": type_code,
                    "serial": i,
                    "with_checksum": with_checksum,
                    "manufactureDate": mfg_date,
                    "expiryDate": exp_date,
                    "dosage": dosage,
                }

                # 1. Firestore Write
                if db and not dry_run:
                    try:
                        save_product_to_firestore(db, prod_dict)
                        status_str = "Firestore: OK"
                    except Exception as e:
                        status_str = f"Firestore: Failed ({e})"
                else:
                    status_str = "Firestore: Skipped (dry-run)"

                # 2. QR Code Generation
                qr_path = generate_qr_image(code, qr_dir, error_level="M")
                qr_status = "QR: OK" if qr_path else "QR: Skipped"

                print(f"   [{i}/{count}] {code} -> {status_str} | {qr_status}")

                summary_records.append({
                    "code": code,
                    "name": name,
                    "batch": batch,
                    "type": product_type,
                    "manufacturer": manufacturer,
                    "generated_at": datetime.now().isoformat(),
                })
                total_generated += 1

    # Write summary CSV
    with open(generated_summary_path, mode="a", newline="", encoding="utf-8") as out_f:
        fieldnames = ["code", "name", "batch", "type", "manufacturer", "generated_at"]
        writer = csv.DictWriter(out_f, fieldnames=fieldnames)
        if not file_exists:
            writer.writeheader()
        writer.writerows(summary_records)

    print(f"\n=======================================================")
    print(f"[+] Generated {total_generated} product codes successfully!")
    print(f"[+] QR Code PNGs: {qr_dir}")
    print(f"[+] Summary Log:  {generated_summary_path}")
    print("=======================================================\n")


# ---------------------------------------------------------------------------
# CLI Argument Parsing & Main Entry Point
# ---------------------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser(
        description="Farmer Dost App — Secure Product Code & QR Generator",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--test", action="store_true", help="Run 10,000 codes in-memory collision self-test")
    parser.add_argument("--csv", type=str, default="products_input.csv", help="Input CSV file with product details")
    parser.add_argument("--dry-run", action="store_true", help="Run locally without writing to Cloud Firestore")
    parser.add_argument("--checksum", action="store_true", default=os.environ.get("GENERATE_CHECKSUM", "false").lower() in ("true", "1", "yes"), help="Append 1-character verification checksum to codes")
    parser.add_argument("--credentials", type=str, default=os.environ.get("FIREBASE_SERVICE_ACCOUNT_KEY", "serviceAccountKey.json"), help="Path to serviceAccountKey.json")
    parser.add_argument("--qr-dir", type=str, default=os.environ.get("QR_OUTPUT_DIR", "backend/qr_output"), help="Directory to save QR PNG images")

    # Single-batch generation options
    parser.add_argument("--type", type=str, choices=["FT", "PS", "fertilizer", "pesticide"], help="Product type (FT/PS)")
    parser.add_argument("--batch", type=str, help="Batch identifier (e.g. BATCH-2026-X1)")
    parser.add_argument("--count", type=int, default=5, help="Number of codes to generate")
    parser.add_argument("--name", type=str, default="Kisan Gold Urea 45kg", help="Product name")
    parser.add_argument("--manufacturer", type=str, default="Punjab Agro Chemicals Ltd", help="Manufacturer name")
    parser.add_argument("--dosage", type=str, default="", help="Dosage recommendation")

    args = parser.parse_args()

    # Mode 1: Self-Test
    if args.test:
        success = run_self_test(num_codes=10000, with_checksum=args.checksum)
        sys.exit(0 if success else 1)

    # Initialize Firestore unless dry-run is specified
    db = None
    if not args.dry_run:
        db = initialize_firestore(args.credentials)
        if not db:
            print("[!] Running in DRY-RUN mode because Firestore credentials were not found.")
            print("    Codes and QR images will be generated locally.\n")

    # Mode 2: Single batch direct CLI parameters
    if args.type and args.batch:
        p_type = "fertilizer" if args.type.upper() in ("FT", "FERTILIZER") else "pesticide"
        t_code = "FT" if p_type == "fertilizer" else "PS"
        print(f"\n[+] Generating {args.count} codes for single batch: {args.name} ({args.batch})")

        summary_records = []
        os.makedirs(args.qr_dir, exist_ok=True)
        summary_path = os.path.join(os.path.dirname(args.qr_dir), "codes_generated.csv")

        for i in range(1, args.count + 1):
            code = generate_single_code(t_code, i, with_checksum=args.checksum)
            prod_dict = {
                "code": code,
                "name": args.name,
                "manufacturer": args.manufacturer,
                "batch": args.batch,
                "type": p_type,
                "type_code": t_code,
                "serial": i,
                "with_checksum": args.checksum,
                "manufactureDate": datetime.now(),
                "expiryDate": datetime.now(),
                "dosage": args.dosage or None,
            }

            if db:
                try:
                    save_product_to_firestore(db, prod_dict)
                    st = "Firestore: OK"
                except Exception as e:
                    st = f"Firestore: Failed ({e})"
            else:
                st = "Firestore: Skipped"

            qr_p = generate_qr_image(code, args.qr_dir, error_level="M")
            print(f"   [{i}/{args.count}] {code} -> {st} | QR: {'OK' if qr_p else 'Skipped'}")

            summary_records.append({
                "code": code,
                "name": args.name,
                "batch": args.batch,
                "type": p_type,
                "manufacturer": args.manufacturer,
                "generated_at": datetime.now().isoformat(),
            })

        # Append to CSV
        file_exists = os.path.isfile(summary_path)
        with open(summary_path, mode="a", newline="", encoding="utf-8") as out_f:
            writer = csv.DictWriter(out_f, fieldnames=["code", "name", "batch", "type", "manufacturer", "generated_at"])
            if not file_exists:
                writer.writeheader()
            writer.writerows(summary_records)

        print(f"\n[+] Single batch complete: {args.count} codes generated.")
        return

    # Mode 3: Batch CSV mode
    csv_target = args.csv
    if not os.path.isfile(csv_target):
        cand = os.path.join("backend", args.csv)
        if os.path.isfile(cand):
            csv_target = cand

    output_dir = os.path.dirname(csv_target) or "backend"
    process_csv_file(
        csv_path=csv_target,
        output_dir=output_dir,
        qr_dir=args.qr_dir,
        db=db,
        with_checksum=args.checksum,
        dry_run=args.dry_run,
    )


if __name__ == "__main__":
    main()
