import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String language; // 'en', 'hi', 'pa'
  final String? district;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    this.language = 'en',
    this.district,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    DateTime parsedTime;
    final rawTs = map['createdAt'];
    if (rawTs is Timestamp) {
      parsedTime = rawTs.toDate();
    } else if (rawTs is String) {
      parsedTime = DateTime.tryParse(rawTs) ?? DateTime.now();
    } else {
      parsedTime = DateTime.now();
    }

    return UserModel(
      uid: uid,
      name: map['name'] as String? ?? 'Farmer',
      phone: map['phone'] as String? ?? '',
      language: map['language'] as String? ?? 'en',
      district: map['district'] as String?,
      createdAt: parsedTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'language': language,
      if (district != null) 'district': district,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
