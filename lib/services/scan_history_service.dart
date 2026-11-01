import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/scan_model.dart';
import 'service_helper.dart';

/// Status outcomes for scan history queries.
enum ScanHistoryStatus {
  success,
  notSignedIn,
  networkError,
  permissionDenied,
  error,
}

/// Structured, non-throwing scan history response.
class ScanHistoryResult {
  final ScanHistoryStatus status;
  final List<ScanModel> scans;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
  final String? errorMessage;

  const ScanHistoryResult({
    required this.status,
    this.scans = const [],
    this.lastDocument,
    this.hasMore = false,
    this.errorMessage,
  });

  bool get isSuccess => status == ScanHistoryStatus.success;

  factory ScanHistoryResult.success({
    required List<ScanModel> scans,
    DocumentSnapshot? lastDocument,
    bool hasMore = false,
  }) =>
      ScanHistoryResult(
        status: ScanHistoryStatus.success,
        scans: scans,
        lastDocument: lastDocument,
        hasMore: hasMore,
      );

  factory ScanHistoryResult.notSignedIn([String? msg]) => ScanHistoryResult(
        status: ScanHistoryStatus.notSignedIn,
        errorMessage: msg ?? 'User must be signed in to view scan history.',
      );

  factory ScanHistoryResult.networkError([String? msg]) => ScanHistoryResult(
        status: ScanHistoryStatus.networkError,
        errorMessage: msg ?? 'Network unavailable. Could not fetch scan history.',
      );

  factory ScanHistoryResult.permissionDenied([String? msg]) => ScanHistoryResult(
        status: ScanHistoryStatus.permissionDenied,
        errorMessage: msg ?? 'Security rules denied access to scan records.',
      );

  factory ScanHistoryResult.error(String message) => ScanHistoryResult(
        status: ScanHistoryStatus.error,
        errorMessage: message,
      );

  @override
  String toString() =>
      'ScanHistoryResult(status: $status, count: ${scans.length}, hasMore: $hasMore)';
}

/// Service managing farmer scan logs and history retrieval.
///
/// ============================================================================
/// FIRESTORE COMPOSITE INDEX REQUIREMENT:
/// ============================================================================
/// Collection ID: scans
/// Fields indexed:
///   1. userId     (Ascending)
///   2. timestamp  (Descending)
/// Query scope: Collection
///
/// In Cloud Firestore Console:
/// Firestore Database -> Indexes -> Composite Indexes -> Create Index
/// Collection: "scans" | userId: ASC | timestamp: DESC
/// Or deploy via firestore.indexes.json:
/// {
///   "indexes": [
///     {
///       "collectionGroup": "scans",
///       "queryScope": "COLLECTION",
///       "fields": [
///         { "fieldPath": "userId", "order": "ASCENDING" },
///         { "fieldPath": "timestamp", "order": "DESCENDING" }
///       ]
///     }
///   ]
/// }
/// ============================================================================
class ScanHistoryService {
  final FirebaseFirestore? _firestoreOverride;
  final FirebaseAuth? _authOverride;
  final Duration timeoutDuration;

  ScanHistoryService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    this.timeoutDuration = kDefaultServiceTimeout,
  })  : _firestoreOverride = firestore,
        _authOverride = auth;

  FirebaseFirestore get _firestore {
    if (_firestoreOverride != null) return _firestoreOverride!;
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('[ScanHistoryService] FirebaseFirestore.instance unavailable: $e');
      rethrow;
    }
  }

  FirebaseAuth? get _auth {
    if (_authOverride != null) return _authOverride;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  /// Fetches a paginated batch of scans for the authenticated user, ordered newest first.
  ///
  /// [limit]: Max items to return per page (default: 20).
  /// [startAfter]: Last [DocumentSnapshot] from previous page for cursor pagination.
  Future<ScanHistoryResult> getScanHistory({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    final uid = _auth?.currentUser?.uid;
    if (uid == null || uid.trim().isEmpty) {
      return ScanHistoryResult.notSignedIn();
    }

    try {
      Query query = _firestore
          .collection('scans')
          .where('userId', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get().timeout(timeoutDuration);

      final scans = querySnapshot.docs.map((doc) {
        return ScanModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      final lastDoc = querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;
      final hasMore = querySnapshot.docs.length == limit;

      return ScanHistoryResult.success(
        scans: scans,
        lastDocument: lastDoc,
        hasMore: hasMore,
      );
    } on TimeoutException {
      return ScanHistoryResult.networkError(
        'Scan history request timed out after ${timeoutDuration.inSeconds}s.',
      );
    } catch (e) {
      debugPrint('[ScanHistoryService] getScanHistory error: $e');
      if (ServiceHelper.isPermissionDenied(e)) {
        return ScanHistoryResult.permissionDenied();
      }
      if (ServiceHelper.isNetworkError(e)) {
        return ScanHistoryResult.networkError(ServiceHelper.mapErrorToUserMessage(e));
      }
      return ScanHistoryResult.error(ServiceHelper.mapErrorToUserMessage(e));
    }
  }

  /// Real-time stream of the authenticated user's recent scans (e.g. For HomeScreen dashboard).
  Stream<List<ScanModel>> streamScanHistory({int limit = 10}) {
    final uid = _auth?.currentUser?.uid;
    if (uid == null || uid.trim().isEmpty) {
      return const Stream.empty();
    }

    try {
      return _firestore
          .collection('scans')
          .where('userId', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return ScanModel.fromMap(doc.data(), doc.id);
        }).toList();
      });
    } catch (e) {
      debugPrint('[ScanHistoryService] streamScanHistory error: $e');
      return const Stream.empty();
    }
  }
}
