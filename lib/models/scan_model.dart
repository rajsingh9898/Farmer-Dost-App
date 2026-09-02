import 'package:cloud_firestore/cloud_firestore.dart';

class ScanModel {
  final String? id;
  final String userId;
  final String productCode;
  final String? productName;
  final String result; // 'genuine', 'fake', or 'unrecognized'
  final DateTime timestamp;

  ScanModel({
    this.id,
    required this.userId,
    required this.productCode,
    this.productName,
    required this.result,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ScanModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parsedTime;
    final rawTs = map['timestamp'];
    if (rawTs is Timestamp) {
      parsedTime = rawTs.toDate();
    } else if (rawTs is String) {
      parsedTime = DateTime.tryParse(rawTs) ?? DateTime.now();
    } else {
      parsedTime = DateTime.now();
    }

    return ScanModel(
      id: docId,
      userId: map['userId'] as String? ?? '',
      productCode: map['productCode'] as String? ?? '',
      productName: map['productName'] as String?,
      result: map['result'] as String? ?? 'unrecognized',
      timestamp: parsedTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'productCode': productCode,
      if (productName != null) 'productName': productName,
      'result': result,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
