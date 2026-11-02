#!/usr/bin/env python3
"""
=============================================================================
Farmer Dost App — Firebase Emulator Suite Seeder (Day 27)
=============================================================================
This script populates the local Firebase Emulator Suite (Firestore & Auth)
with deterministic test datasets required for automated End-to-End verification.

Seeded Resources:
1. Test User:
   - UID: "test_farmer_uid_e2e"
   - Email: "testfarmer@dost.in"
   - Name: "Gurpreet Singh E2E"
   - Phone: "+919876543210"
   - Doc: users/test_farmer_uid_e2e
2. Standard Test Products:
   - Genuine Active: FD-FT-00101-GEN001 (IFFCO Neem Coated Urea 45kg)
   - Recalled Batch: FD-PS-00202-REC002 (Kisan Rakshak Chlorpyrifos 20% EC)
   - Expired Product: FD-FT-00303-EXP003 (Punjab Gold Zinc Sulfate 21%)
3. Industrial Catalog (from products_input.csv if available)
=============================================================================
"""

import os
import sys
import argparse
from datetime import datetime, timezone

# Setup UTF-8 for Windows Console
if sys.platform.startswith("win"):
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass


def init_emulator_environment(host="127.0.0.1:8080", auth_host="127.0.0.1:9099"):
    """Configures environment variables to route Google Cloud SDK to emulators."""
    os.environ["FIRESTORE_EMULATOR_HOST"] = host
    os.environ["FIREBASE_AUTH_EMULATOR_HOST"] = auth_host
    os.environ["GCLOUD_PROJECT"] = "farmer-dost-app"
    print(f"[*] Targeting Firestore Emulator at: {host}")
    print(f"[*] Targeting Auth Emulator at:      {auth_host}")


def seed_database():
    try:
        import firebase_admin
        from firebase_admin import credentials, firestore, auth
    except ImportError:
        print("[!] firebase_admin package is required. Install via: pip install firebase-admin")
        sys.exit(1)

    if not firebase_admin._apps:
        # Emulator accepts dummy or local credentials
        cred = credentials.AnonymousCredentials() if hasattr(credentials, 'AnonymousCredentials') else None
        try:
            firebase_admin.initialize_app(options={"projectId": "farmer-dost-app"})
        except Exception:
            # Fallback with empty credential
            firebase_admin.initialize_app(credentials.Certificate({
                "type": "service_account",
                "project_id": "farmer-dost-app",
                "private_key_id": "dummy",
                "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDIBUKI65wAC4Dj\n-----END PRIVATE KEY-----\n",
                "client_email": "emulator@farmer-dost-app.iam.gserviceaccount.com",
                "client_id": "dummy",
                "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                "token_uri": "https://oauth2.googleapis.com/token",
            }))

    db = firestore.client()

    print("\n[+] Seeding Test Users...")
    test_user_id = "test_farmer_uid_e2e"
    user_data = {
        "name": "Gurpreet Singh E2E",
        "phone": "+919876543210",
        "language": "en",
        "email": "testfarmer@dost.in",
        "district": "Ludhiana",
        "createdAt": datetime.now(timezone.utc),
    }
    db.collection("users").document(test_user_id).set(user_data)
    print(f"    ✓ users/{test_user_id} created")

    # Also seed test user in Auth Emulator if available
    try:
        try:
            auth.get_user(test_user_id)
            print(f"    ✓ Auth user {test_user_id} already exists in emulator")
        except auth.UserNotFoundError:
            auth.create_user(
                uid=test_user_id,
                email="testfarmer@dost.in",
                phone_number="+919876543210",
                display_name="Gurpreet Singh E2E",
                password="FarmerPassword123!",
            )
            print(f"    ✓ Auth user {test_user_id} created in emulator")
    except Exception as e:
        print(f"    ⚠ Auth emulator user creation note: {e}")

    print("\n[+] Seeding Standard Test Products...")
    test_products = [
        {
            "code": "FD-FT-00101-GEN001",
            "name": "IFFCO Neem Coated Urea 45kg",
            "manufacturer": "Indian Farmers Fertiliser Co-operative Ltd",
            "batch": "NCU-2026-B81",
            "type": "fertilizer",
            "status": "active",
            "manufactureDate": datetime(2026, 3, 15, tzinfo=timezone.utc),
            "expiryDate": datetime(2028, 12, 31, tzinfo=timezone.utc),
            "createdAt": datetime.now(timezone.utc),
        },
        {
            "code": "FD-PS-00202-REC002",
            "name": "Kisan Rakshak Chlorpyrifos 20% EC",
            "manufacturer": "Punjab Agro Chemical Industries Ltd",
            "batch": "RCL-2026-99",
            "type": "pesticide",
            "status": "recalled",
            "manufactureDate": datetime(2026, 1, 10, tzinfo=timezone.utc),
            "expiryDate": datetime(2027, 6, 30, tzinfo=timezone.utc),
            "createdAt": datetime.now(timezone.utc),
        },
        {
            "code": "FD-FT-00303-EXP003",
            "name": "Punjab Gold Zinc Sulfate 21%",
            "manufacturer": "Malwa Agri Minerals & Chemicals",
            "batch": "ZS-2023-A04",
            "type": "fertilizer",
            "status": "active",
            "manufactureDate": datetime(2022, 1, 1, tzinfo=timezone.utc),
            "expiryDate": datetime(2024, 1, 1, tzinfo=timezone.utc),  # IN THE PAST
            "createdAt": datetime.now(timezone.utc),
        },
    ]

    for p in test_products:
        db.collection("products").document(p["code"]).set(p)
        print(f"    ✓ products/{p['code']} [{p['status'].upper()}] - {p['name']}")

    # Optionally seed all 18 Punjabi products from products_input.csv
    csv_candidates = [
        "products_input.csv",
        os.path.join("backend", "products_input.csv"),
        os.path.join(os.path.dirname(__file__), "products_input.csv"),
    ]
    csv_path = next((p for p in csv_candidates if os.path.isfile(p)), None)
    if csv_path:
        import csv
        print("\n[+] Seeding 18 Industrial Products from products_input.csv...")
        with open(csv_path, mode="r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for idx, row in enumerate(reader, start=1):
                raw_type = row.get("type", "fertilizer").strip().lower()
                p_type = "fertilizer" if "fert" in raw_type or raw_type == "ft" else "pesticide"
                t_code = "FT" if p_type == "fertilizer" else "PS"
                p_code = f"FD-{t_code}-{idx*100+1:05d}-REG{idx:03d}"
                mfg_str = row.get("manufactureDate", "").strip()
                exp_str = row.get("expiryDate", "").strip()
                mfg_dt = datetime.strptime(mfg_str, "%Y-%m-%d").replace(tzinfo=timezone.utc) if mfg_str else datetime.now(timezone.utc)
                exp_dt = datetime.strptime(exp_str, "%Y-%m-%d").replace(tzinfo=timezone.utc) if exp_str else datetime.now(timezone.utc)

                doc_payload = {
                    "code": p_code,
                    "name": row.get("name", "").strip(),
                    "manufacturer": row.get("manufacturer", "").strip(),
                    "batch": row.get("batch", "").strip(),
                    "type": p_type,
                    "status": row.get("status", "active").strip().lower(),
                    "manufactureDate": mfg_dt,
                    "expiryDate": exp_dt,
                    "createdAt": datetime.now(timezone.utc),
                    "dosage": row.get("dosage", "").strip() or None,
                }
                db.collection("products").document(p_code).set(doc_payload)
                print(f"    ✓ products/{p_code} [{doc_payload['status'].upper()}] - {doc_payload['name']}")

    print("\n=======================================================")
    print("✅ Firebase Emulator Database Successfully Seeded!")
    print(f"   - Users: 1 (UID: {test_user_id})")
    print(f"   - Core Test Products: 3 + 18 Regional Punjabi Products")
    print("   Ready for Day 27 E2E Integration Suite.")
    print("=======================================================\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Seed Firebase Emulator for Farmer Dost")
    parser.add_argument("--host", default="127.0.0.1:8080", help="Firestore Emulator Host (default: 127.0.0.1:8080)")
    parser.add_argument("--auth-host", default="127.0.0.1:9099", help="Auth Emulator Host (default: 127.0.0.1:9099)")
    args = parser.parse_args()

    init_emulator_environment(host=args.host, auth_host=args.auth_host)
    seed_database()
