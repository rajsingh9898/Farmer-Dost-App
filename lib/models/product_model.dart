import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String code;
  final String name;
  final String batch;
  final String manufacturer;
  final String status; // 'active', 'genuine', 'fake', 'recalled', or 'expired'
  final String type; // 'fertilizer' or 'pesticide'
  final DateTime? manufactureDate;
  final DateTime? expiryDate;
  final DateTime? createdAt;
  final String? dosage;

  ProductModel({
    required this.code,
    required this.name,
    required this.batch,
    required this.manufacturer,
    required this.status,
    this.type = 'fertilizer',
    this.manufactureDate,
    this.expiryDate,
    this.createdAt,
    this.dosage,
  });

  /// Helper getter to determine if product is genuine and safe to use
  bool get isGenuine =>
      status.toLowerCase() == 'genuine' || status.toLowerCase() == 'active';

  /// Helper getter to determine if product has expired
  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime? parseDate(dynamic raw) {
      if (raw == null) return null;
      if (raw is Timestamp) return raw.toDate();
      if (raw is String) return DateTime.tryParse(raw);
      return null;
    }

    return ProductModel(
      code: map['code'] as String? ?? documentId,
      name: map['name'] as String? ?? 'Unknown Product',
      batch: map['batch'] as String? ?? 'N/A',
      manufacturer: map['manufacturer'] as String? ?? 'Unknown Manufacturer',
      status: map['status'] as String? ?? 'active',
      type: map['type'] as String? ?? 'fertilizer',
      manufactureDate: parseDate(map['manufactureDate']),
      expiryDate: parseDate(map['expiryDate']),
      createdAt: parseDate(map['createdAt']),
      dosage: map['dosage'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'batch': batch,
      'manufacturer': manufacturer,
      'status': status,
      'type': type,
      if (manufactureDate != null) 'manufactureDate': Timestamp.fromDate(manufactureDate!),
      if (expiryDate != null) 'expiryDate': Timestamp.fromDate(expiryDate!),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      if (dosage != null) 'dosage': dosage,
    };
  }
}
