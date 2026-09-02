import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String? id;
  final String productCode;
  final String userId;
  final String? location;
  final String? note;
  final DateTime timestamp;

  ReportModel({
    this.id,
    required this.productCode,
    required this.userId,
    this.location,
    this.note,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ReportModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parsedTime;
    final rawTs = map['timestamp'];
    if (rawTs is Timestamp) {
      parsedTime = rawTs.toDate();
    } else if (rawTs is String) {
      parsedTime = DateTime.tryParse(rawTs) ?? DateTime.now();
    } else {
      parsedTime = DateTime.now();
    }

    return ReportModel(
      id: docId,
      productCode: map['productCode'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      location: map['location'] as String?,
      note: map['note'] as String?,
      timestamp: parsedTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productCode': productCode,
      'userId': userId,
      if (location != null && location!.isNotEmpty) 'location': location,
      if (note != null && note!.isNotEmpty) 'note': note,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
