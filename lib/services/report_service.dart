import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/report_result.dart';
import 'verification_service.dart';

/// Day 24 — Farmer Report Service
/// Handles submitting reports of counterfeit, suspicious, or unrecognized packages
/// to Cloud Firestore with deterministic deduplication and strict validation.
class ReportService {
  final FirebaseFirestore? _customFirestore;
  final FirebaseAuth? _customAuth;
  final Duration timeoutDuration;

  ReportService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    this.timeoutDuration = const Duration(seconds: 10),
  })  : _customFirestore = firestore,
        _customAuth = auth;

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseAuth? get _auth {
    if (_customAuth != null) return _customAuth;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  /// Submits a fake product report to Cloud Firestore 'reports' collection:
  /// - Normalizes and validates product code (same validation as verifyProduct)
  /// - Enforces authentication (userId comes strictly from FirebaseAuth.currentUser)
  /// - Enforces deterministic document ID: `${uid}_${validCode}` to prevent duplicate spam
  /// - Sanitizes optional note (trimmed, empty treated as null, max 100 chars)
  /// - Safe timeout and network exception handling; NEVER throws to UI.
  Future<ReportResult> submitReport({
    required String productCode,
    GeoPoint? location,
    String? note,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    Duration? timeoutDuration,
  }) async {
    // 1. Normalize and validate product code BEFORE touching Firestore
    final String? normalizedCode = normalizeAndValidate(productCode);
    if (normalizedCode == null) {
      debugPrint('[ReportService] Rejected invalid product code format: "$productCode"');
      return ReportResult(
        status: ReportStatus.invalidInput,
        productCode: productCode,
        message: 'Invalid product code format. Valid format example: FD-FT-00123-A7X9KM.',
      );
    }

    // 2. Authentication check: userId comes strictly from authenticated session
    final authInstance = auth ?? _auth;
    final User? currentUser = authInstance?.currentUser;
    if (currentUser == null) {
      debugPrint('[ReportService] User not signed in. Report rejected.');
      return ReportResult(
        status: ReportStatus.notSignedIn,
        productCode: normalizedCode,
        message: 'You must be signed in to submit a product report.',
      );
    }
    final String uid = currentUser.uid;

    // 3. Sanitize and validate note (max 100 characters)
    String? cleanNote;
    if (note != null) {
      final trimmed = note.trim();
      if (trimmed.isNotEmpty) {
        if (trimmed.length > 100) {
          return ReportResult(
            status: ReportStatus.invalidInput,
            productCode: normalizedCode,
            message: 'Report note must not exceed 100 characters.',
          );
        }
        cleanNote = trimmed;
      }
    }

    // 4. Resolve Firestore instance and timeout
    final db = firestore ?? _firestore;
    if (db == null) {
      return ReportResult(
        status: ReportStatus.networkError,
        productCode: normalizedCode,
        message: 'Database is offline or uninitialized.',
      );
    }

    final timeout = timeoutDuration ?? this.timeoutDuration;
    // Deterministic Document ID: {uid}_{code}
    final String reportDocId = '${uid}_$normalizedCode';

    try {
      final docRef = db.collection('reports').doc(reportDocId);

      // Check if report already submitted by this user for this product
      final docSnapshot = await docRef.get().timeout(timeout);
      if (docSnapshot.exists) {
        debugPrint('[ReportService] Duplicate report detected: $reportDocId');
        return ReportResult(
          status: ReportStatus.alreadyReported,
          reportId: reportDocId,
          productCode: normalizedCode,
          message: 'You have already submitted a report for this product. Our agriculture team is reviewing it.',
        );
      }

      // Payload matching Day 15 schema and Day 25 security rules
      final Map<String, dynamic> reportData = {
        'productCode': normalizedCode,
        'userId': uid,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      };

      if (cleanNote != null) {
        reportData['note'] = cleanNote;
      }
      if (location != null) {
        reportData['location'] = location;
      }

      // Write report with deterministic ID
      await docRef.set(reportData).timeout(timeout);

      debugPrint('[ReportService] Report successfully recorded: $reportDocId');
      return ReportResult(
        status: ReportStatus.success,
        reportId: reportDocId,
        productCode: normalizedCode,
        message: 'Thank you! Your report has been submitted to Punjab Agricultural Department for investigation.',
      );
    } on TimeoutException {
      debugPrint('[ReportService] Submission timed out after ${timeout.inSeconds}s');
      return ReportResult(
        status: ReportStatus.networkError,
        productCode: normalizedCode,
        message: 'Report submission timed out. Please check your internet connection.',
      );
    } on SocketException catch (se) {
      debugPrint('[ReportService] SocketException: ${se.message}');
      return ReportResult(
        status: ReportStatus.networkError,
        productCode: normalizedCode,
        message: 'Network connection error. Please reconnect and retry.',
      );
    } on FirebaseException catch (fe) {
      debugPrint('[ReportService] FirebaseException [${fe.code}]: ${fe.message}');
      if (fe.code == 'permission-denied') {
        return ReportResult(
          status: ReportStatus.permissionDenied,
          productCode: normalizedCode,
          message: 'Permission denied. Ensure your account is verified.',
        );
      }
      if (fe.code == 'unavailable' || fe.code == 'deadline-exceeded') {
        return ReportResult(
          status: ReportStatus.networkError,
          productCode: normalizedCode,
          message: 'Cloud service is temporarily unavailable. Please retry in a moment.',
        );
      }
      return ReportResult(
        status: ReportStatus.networkError,
        productCode: normalizedCode,
        message: 'Submission failed (${fe.code}): ${fe.message ?? "Unknown error"}',
      );
    } catch (e) {
      debugPrint('[ReportService] Unexpected error: $e');
      return ReportResult(
        status: ReportStatus.networkError,
        productCode: normalizedCode,
        message: 'An unexpected error occurred: $e',
      );
    }
  }
}

/// Global default instance
final ReportService reportService = ReportService();

/// Top-level convenience wrapper
Future<ReportResult> submitReport({
  required String productCode,
  GeoPoint? location,
  String? note,
  FirebaseFirestore? firestore,
  FirebaseAuth? auth,
  Duration? timeoutDuration,
}) {
  return reportService.submitReport(
    productCode: productCode,
    location: location,
    note: note,
    firestore: firestore,
    auth: auth,
    timeoutDuration: timeoutDuration,
  );
}
