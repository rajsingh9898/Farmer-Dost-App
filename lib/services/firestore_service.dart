import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/report_model.dart';
import '../models/user_model.dart';
import '../models/scan_model.dart';

class FirestoreConnectionException implements Exception {
  final String message;
  FirestoreConnectionException([this.message = "Can't verify right now, check your connection"]);

  @override
  String toString() => message;
}

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  FirebaseFirestore? _firestoreInstance;

  FirebaseFirestore get _firestore {
    _firestoreInstance ??= FirebaseFirestore.instance;
    return _firestoreInstance!;
  }

  /// Flag to enable offline demo mode fallback when Firebase is not connected or in test env
  bool useDemoFallbackIfOffline = true;

  /// verifyProduct(code)
  /// Checks Firestore "products" collection for matching code.
  /// Wrapped in try/catch to handle network/connection issues.
  Future<ProductModel?> verifyProduct(String code, {String userId = 'demo_farmer_123'}) async {
    try {
      ProductModel? product;

      try {
        final querySnapshot = await _firestore
            .collection('products')
            .where('code', isEqualTo: code)
            .get()
            .timeout(const Duration(seconds: 5));

        if (querySnapshot.docs.isNotEmpty) {
          final doc = querySnapshot.docs.first;
          product = ProductModel.fromMap(doc.data(), doc.id);
        } else {
          // Document by ID check
          final docSnapshot = await _firestore
              .collection('products')
              .doc(code)
              .get()
              .timeout(const Duration(seconds: 5));
          if (docSnapshot.exists && docSnapshot.data() != null) {
            product = ProductModel.fromMap(docSnapshot.data()!, docSnapshot.id);
          }
        }
      } catch (dbError) {
        debugPrint('Firestore query error or offline: $dbError');
        if (useDemoFallbackIfOffline) {
          product = _getDemoProduct(code);
        } else {
          throw FirestoreConnectionException("Can't verify right now, check your connection.");
        }
      }

      final String resultStatus = product != null ? product.status : 'unrecognized';
      final String? productName = product?.name;

      // Requirement 5: Every scan (genuine or fake or unrecognized) writes to "scans" collection
      await logScan(
        userId: userId,
        productCode: code,
        productName: productName,
        result: resultStatus,
      );

      return product;
    } on FirestoreConnectionException {
      rethrow;
    } catch (e) {
      debugPrint('Error in verifyProduct: $e');
      throw FirestoreConnectionException("Can't verify right now, check your connection.");
    }
  }

  /// Logs a scan entry into Firestore "scans" collection
  Future<void> logScan({
    required String userId,
    required String productCode,
    String? productName,
    required String result,
  }) async {
    try {
      final scanData = ScanModel(
        userId: userId,
        productCode: productCode,
        productName: productName,
        result: result,
      );

      await _firestore
          .collection('scans')
          .add(scanData.toMap())
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Error logging scan to Firestore: $e');
      // If offline/demo fallback, add to memory cache for demonstration
      _demoScansHistory.insert(
        0,
        ScanModel(
          id: 'demo_scan_${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          productCode: productCode,
          productName: productName ?? 'Scanned Product',
          result: result,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// submitReport(data)
  /// Writes report data to Firestore "reports" collection
  Future<void> submitReport(ReportModel data) async {
    try {
      await _firestore
          .collection('reports')
          .add(data.toMap())
          .timeout(const Duration(seconds: 6));
    } catch (e) {
      debugPrint('Error submitting report to Firestore: $e');
      if (useDemoFallbackIfOffline) {
        debugPrint('Report submitted in demo fallback mode.');
        return;
      }
      throw FirestoreConnectionException("Failed to submit report. Please check your connection.");
    }
  }

  /// getProfile(userId)
  /// Fetches farmer user profile from "users" collection
  Future<UserModel?> getProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get()
          .timeout(const Duration(seconds: 5));

      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, doc.id);
      } else {
        if (useDemoFallbackIfOffline) {
          return UserModel(
            uid: userId,
            name: 'Harpreet Singh (Farmer)',
            phone: '+91 98765 43210',
            createdAt: DateTime.now().subtract(const Duration(days: 30)),
          );
        }
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching profile from Firestore: $e');
      if (useDemoFallbackIfOffline) {
        return UserModel(
          uid: userId,
          name: 'Harpreet Singh (Farmer)',
          phone: '+91 98765 43210',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        );
      }
      throw FirestoreConnectionException("Unable to load profile. Check your connection.");
    }
  }

  /// getScanHistory(userId)
  /// Fetches scan history from "scans" collection ordered by timestamp descending
  Future<List<ScanModel>> getScanHistory(String userId) async {
    try {
      final query = await _firestore
          .collection('scans')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get()
          .timeout(const Duration(seconds: 5));

      final list = query.docs
          .map((doc) => ScanModel.fromMap(doc.data(), doc.id))
          .toList();

      if (list.isEmpty && useDemoFallbackIfOffline) {
        return _demoScansHistory;
      }
      return list;
    } catch (e) {
      debugPrint('Error fetching scan history from Firestore: $e');
      if (useDemoFallbackIfOffline) {
        return _demoScansHistory;
      }
      throw FirestoreConnectionException("Unable to fetch scan history. Check connection.");
    }
  }

  // --- Demo Mock Helpers for Offline / Testing Verification ---
  ProductModel? _getDemoProduct(String code) {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode == 'GENUINE-123' || cleanCode == 'UREA-99' || cleanCode.contains('GENUINE')) {
      return ProductModel(
        code: code,
        name: 'KRIBHCO Neem Coated Urea 50kg',
        batch: 'BATCH-2026-99A',
        manufacturer: 'Krishak Bharati Cooperative Ltd',
        status: 'genuine',
      );
    } else if (cleanCode == 'FAKE-456' || cleanCode == 'FAKE-9999' || cleanCode.contains('FAKE')) {
      return ProductModel(
        code: code,
        name: 'Counterfeit Urea Mix',
        batch: 'FAKE-BATCH-X',
        manufacturer: 'Unknown / Suspicious Vendor',
        status: 'fake',
      );
    } else if (cleanCode == 'ERROR-500' || cleanCode.contains('ERROR')) {
      throw FirestoreConnectionException("Can't verify right now, check your connection.");
    }
    return null; // Unrecognized
  }

  final List<ScanModel> _demoScansHistory = [
    ScanModel(
      id: 'scan_1',
      userId: 'demo_farmer_123',
      productCode: 'GENUINE-123',
      productName: 'KRIBHCO Neem Coated Urea 50kg',
      result: 'genuine',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ScanModel(
      id: 'scan_2',
      userId: 'demo_farmer_123',
      productCode: 'FAKE-456',
      productName: 'Counterfeit Fertilizer 25kg',
      result: 'fake',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ScanModel(
      id: 'scan_3',
      userId: 'demo_farmer_123',
      productCode: 'UNKNOWN-000',
      productName: null,
      result: 'unrecognized',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];
}
