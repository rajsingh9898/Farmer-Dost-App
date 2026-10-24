import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String? id;
  final String productCode;
  final String userId;
  final String? location;
  final GeoPoint? geoPoint;
  final String? note;
  final String status; // 'pending', 'reviewed', 'confirmed'
  final DateTime timestamp;

  ReportModel({
    this.id,
    required this.productCode,
    required this.userId,
    this.location,
    this.geoPoint,
    this.note,
    this.status = 'pending',
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

    String? locationStr;
    GeoPoint? gp;
    final rawLoc = map['location'];
    if (rawLoc is GeoPoint) {
      gp = rawLoc;
      locationStr = 'Lat: ${rawLoc.latitude.toStringAsFixed(2)}, Lng: ${rawLoc.longitude.toStringAsFixed(2)}';
    } else if (rawLoc is String) {
      locationStr = rawLoc;
    }

    return ReportModel(
      id: docId,
      productCode: map['productCode'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      location: locationStr,
      geoPoint: gp,
      note: map['note'] as String?,
      status: map['status'] as String? ?? 'pending',
      timestamp: parsedTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productCode': productCode,
      'userId': userId,
      if (geoPoint != null)
        'location': geoPoint
      else if (location != null && location!.isNotEmpty)
        'location': location,
      if (note != null && note!.isNotEmpty) 'note': note,
      'status': status,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
