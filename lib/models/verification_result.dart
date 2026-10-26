import 'package:cloud_firestore/cloud_firestore.dart';

/// Day 19 — Verification Status Enum
/// Represents all possible outcomes of QR product code verification.
enum VerificationStatus {
  genuine,
  recalled,
  expired,
  notRecognized,
  invalidInput,
  networkError,
}

/// Day 19 — Product Domain Model
/// Directly maps to Firestore `products` collection document schema.
/// Document ID in Firestore is the product QR code string (e.g. FD-FT-00123-A7X9KM).
class Product {
  final String code;
  final String name;
  final String manufacturer;
  final String batch;
  final String type; // 'fertilizer' or 'pesticide'
  final String status; // 'active', 'recalled', 'expired', 'genuine'
  final DateTime? manufactureDate;
  final DateTime? expiryDate;
  final DateTime? createdAt;
  final String? dosage;

  const Product({
    required this.code,
    required this.name,
    required this.manufacturer,
    required this.batch,
    required this.type,
    required this.status,
    this.manufactureDate,
    this.expiryDate,
    this.createdAt,
    this.dosage,
  });

  /// Factory from Cloud Firestore DocumentSnapshot.
  /// Safely extracts data map and falls back to empty map if null.
  factory Product.fromFirestore(DocumentSnapshot snapshot) {
    final data = (snapshot.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
    return Product.fromMap(data, snapshot.id);
  }

  /// Safe parser handling missing fields, nulls, and Timestamp/String conversion.
  factory Product.fromMap(Map<String, dynamic> data, [String? docId]) {
    DateTime? parseDate(dynamic raw) {
      if (raw == null) return null;
      if (raw is Timestamp) return raw.toDate();
      if (raw is DateTime) return raw;
      if (raw is String) return DateTime.tryParse(raw);
      if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
      return null;
    }

    return Product(
      code: (data['code'] as String?)?.trim() ?? docId ?? '',
      name: (data['name'] as String?)?.trim() ?? 'Unknown Product',
      manufacturer: (data['manufacturer'] as String?)?.trim() ?? 'Unknown Manufacturer',
      batch: (data['batch'] as String?)?.trim() ?? 'Unknown Batch',
      type: (data['type'] as String?)?.trim() ?? 'fertilizer',
      status: (data['status'] as String?)?.trim() ?? 'active',
      manufactureDate: parseDate(data['manufactureDate']),
      expiryDate: parseDate(data['expiryDate']),
      createdAt: parseDate(data['createdAt']),
      dosage: data['dosage'] as String?,
    );
  }

  /// Helper getter to determine if product is actively genuine
  bool get isGenuine =>
      status.toLowerCase() == 'genuine' || status.toLowerCase() == 'active';

  /// Helper getter to determine if product is flagged as recalled
  bool get isRecalled => status.toLowerCase() == 'recalled';

  /// Helper getter to determine if product has expired
  bool get isExpired {
    if (status.toLowerCase() == 'expired') return true;
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  /// Converts product instance back to Firestore data map
  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'manufacturer': manufacturer,
      'batch': batch,
      'type': type,
      'status': status,
      if (manufactureDate != null) 'manufactureDate': Timestamp.fromDate(manufactureDate!),
      if (expiryDate != null) 'expiryDate': Timestamp.fromDate(expiryDate!),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      if (dosage != null) 'dosage': dosage,
    };
  }
}

/// Day 19 — Verification Result Model
/// Holds the final outcome of verifyProduct() for UI presentation and scan logging.
class VerificationResult {
  final VerificationStatus status;
  final String scannedCode;
  final String? name;
  final String? manufacturer;
  final String? batch;
  final String? type;
  final DateTime? manufactureDate;
  final DateTime? expiryDate;
  final String? message;
  final Product? product;

  const VerificationResult({
    required this.status,
    required this.scannedCode,
    this.name,
    this.manufacturer,
    this.batch,
    this.type,
    this.manufactureDate,
    this.expiryDate,
    this.message,
    this.product,
  });

  // --- Convenience Factory Constructors ---

  /// Verified genuine and safe product
  factory VerificationResult.genuine({
    required Product product,
    required String scannedCode,
    String? message,
  }) {
    return VerificationResult(
      status: VerificationStatus.genuine,
      scannedCode: scannedCode,
      name: product.name,
      manufacturer: product.manufacturer,
      batch: product.batch,
      type: product.type,
      manufactureDate: product.manufactureDate,
      expiryDate: product.expiryDate,
      message: message ?? 'Genuine registered agricultural product.',
      product: product,
    );
  }

  /// Registered product but flagged as recalled by the manufacturer
  factory VerificationResult.recalled({
    required Product product,
    required String scannedCode,
    String? message,
  }) {
    return VerificationResult(
      status: VerificationStatus.recalled,
      scannedCode: scannedCode,
      name: product.name,
      manufacturer: product.manufacturer,
      batch: product.batch,
      type: product.type,
      manufactureDate: product.manufactureDate,
      expiryDate: product.expiryDate,
      message: message ?? 'WARNING: This product batch has been RECALLED by the manufacturer.',
      product: product,
    );
  }

  /// Registered product but past its expiry date
  factory VerificationResult.expired({
    required Product product,
    required String scannedCode,
    String? message,
  }) {
    return VerificationResult(
      status: VerificationStatus.expired,
      scannedCode: scannedCode,
      name: product.name,
      manufacturer: product.manufacturer,
      batch: product.batch,
      type: product.type,
      manufactureDate: product.manufactureDate,
      expiryDate: product.expiryDate,
      message: message ?? 'WARNING: This product has expired. Chemical effectiveness may be compromised.',
      product: product,
    );
  }

  /// Code matched regex format but does not exist in Firestore "products" collection
  factory VerificationResult.notRecognized({
    required String scannedCode,
    String? message,
  }) {
    return VerificationResult(
      status: VerificationStatus.notRecognized,
      scannedCode: scannedCode,
      message: message ?? 'Warning: This code is not recognized in the official registry. Possible counterfeit product.',
    );
  }

  /// Code failed format check before hitting Firestore (e.g. empty, URL, illegal characters, wrong format)
  factory VerificationResult.invalidInput({
    required String scannedCode,
    String? message,
  }) {
    return VerificationResult(
      status: VerificationStatus.invalidInput,
      scannedCode: scannedCode,
      message: message ?? 'Invalid product code format. Ensure code follows standard FD-<TYPE>-<SERIAL>-<RANDOM> format.',
    );
  }

  /// Network error, timeout, or Firestore unavailable
  factory VerificationResult.networkError({
    required String scannedCode,
    required String message,
  }) {
    return VerificationResult(
      status: VerificationStatus.networkError,
      scannedCode: scannedCode,
      message: message,
    );
  }

  // --- Convenience Getters ---
  bool get isGenuine => status == VerificationStatus.genuine;
  bool get isRecalled => status == VerificationStatus.recalled;
  bool get isExpired => status == VerificationStatus.expired;
  bool get isNotRecognized => status == VerificationStatus.notRecognized;
  bool get isInvalidInput => status == VerificationStatus.invalidInput;
  bool get isNetworkError => status == VerificationStatus.networkError;

  /// Whether this result represents a valid verification outcome suitable for logging to scans
  bool get shouldLog =>
      status != VerificationStatus.invalidInput &&
      status != VerificationStatus.networkError;

  @override
  String toString() {
    return 'VerificationResult(status: ${status.name}, code: $scannedCode, name: $name, message: $message)';
  }
}
