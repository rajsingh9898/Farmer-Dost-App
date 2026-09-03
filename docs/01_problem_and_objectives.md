# Day 1 — Problem Statement & MVP Objectives

## Problem Statement

Small-scale farmers in Punjab, India, rely heavily on fertilizers and pesticides to protect and grow their crops. However, a significant portion of the agricultural inputs sold in rural markets are counterfeit, adulterated, or mislabeled. Unscrupulous sellers exploit farmers' limited ability to verify product authenticity, selling fake or diluted fertilizers and pesticides at genuine prices. This leads to reduced crop yield, wasted investment, soil degradation, and, in severe cases, health hazards for both farmers and consumers.

Currently, there is no accessible, farmer-friendly system that allows a small-scale farmer to instantly verify whether a product they are purchasing is genuine before they use it on their land. Existing verification methods — checking manufacturer holograms manually or trusting the dealer's word — are unreliable and require literacy or expertise most small farmers do not have.

**Farmer Dost** addresses this gap with a simple, accessible mobile application that lets a farmer scan a security label on any agricultural product and instantly know whether it is genuine or counterfeit, empowering them to make safe purchasing decisions and report fraudulent sellers.

---

## Objectives

1. **Real-time Verification**: To design and develop a mobile application that allows farmers to scan security labels (QR/barcode) on fertilizers and pesticides and verify their authenticity in real time.
2. **Centralized Database**: To maintain a centralized, tamper-resistant database of genuine product batches that can be checked against scanned codes.
3. **Fraud Reporting**: To provide farmers with a simple mechanism to report suspected counterfeit products, helping identify fraudulent sellers and protect other farmers.
4. **Farmer Profile & Scan History**: To create a farmer profile system that stores scan history, enabling farmers to track products they have previously verified.
5. **Accessibility**: To design the application with accessibility in mind — simple navigation, minimal text dependency, and an interface usable by farmers with limited digital literacy.
6. **Scalability**: To build a scalable foundation that can later support additional features such as crop advisory, offline verification, and multi-language support.

---

## MVP Feature Scope (Week 1 Baseline)

| Feature | Description | Status |
|---|---|---|
| **Scan** | Farmer opens the app and scans a QR/barcode security label using camera feed. | ✅ Navigation & Scanner Skeleton Built |
| **Verify** | Scanned code checked against `products` collection returning Genuine, Fake, or Connection Error. | ✅ FirestoreService & ResultScreen Built |
| **Report Fake** | Form allowing farmer to report suspected fake products with pre-filled code & notes to `reports` collection. | ✅ ReportScreen & FirestoreService Built |
| **Farmer Profile** | Profile view showing basic farmer info and scrollable list of scan history from `scans` collection. | ✅ ProfileScreen & FirestoreService Built |
