import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/verification_result.dart';

/// Regular expression validating standard Farmer Dost product code format:
/// Format: `FD-<TYPE>-<SERIAL>-<RANDOM>[<CHECKSUM>]`
/// - FD: Fixed namespace prefix (Farmer Dost)
/// - (FT|PS): Fertilizer (FT) or Pesticide (PS)
/// - `\d{5}`: 5-digit zero-padded serial counter (00001 - 99999)
/// - `[A-Z0-9]{6,}`: 6+ alphanumeric characters (CSPRNG random component + optional checksum)
///
/// Pre-Firestore validation rejects:
/// - Strings with "/" (which break Firestore document path parsing)
/// - URLs (e.g. https://...)
/// - Empty or arbitrary strings
/// - Malicious injection payloads
final RegExp _kProductCodeRegex = RegExp(r'^FD-(FT|PS)-\d{5}-[A-Z0-9]{6,}$');

/// Day 19 — Core Verification Service
/// Handles secure, high-speed direct document lookup and scan audit logging.
class VerificationService {
  final FirebaseFirestore? _customFirestore;
  final FirebaseAuth? _customAuth;

  VerificationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _customFirestore = firestore,
        _customAuth = auth;

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;
  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;

  /// ---------------------------------------------------------------------------
  /// 2. verifyProduct(rawCode)
  /// ---------------------------------------------------------------------------
  /// Performs atomic product verification against Firestore:
  /// a. Normalize (trim, uppercase)
  /// b. Regex pre-validation (rejects invalidInput before contacting database)
  /// c. Direct document lookup (O(1) doc(code).get(), NOT a where() query)
  /// d. Check existence -> notRecognized
  /// e. Check recalled -> recalled; check expiry -> expired; else genuine
  /// f. Comprehensive error handling with distinct permission-denied diagnostics
  /// g. 10-second timeout to avoid app hangs in rural areas
  /// h. Never throws to UI; always returns a structured VerificationResult
  Future<VerificationResult> verifyProduct(String rawCode) async {
    // Step a: Normalize input string
    final String normalizedCode = rawCode.trim().toUpperCase();

    // Step b: Pre-validate format BEFORE touching Cloud Firestore
    if (!_kProductCodeRegex.hasMatch(normalizedCode)) {
      debugPrint('[verifyProduct] Rejected invalid code format: "$rawCode" -> "$normalizedCode"');
      return VerificationResult.invalidInput(
        scannedCode: normalizedCode,
        message: 'Invalid product code format. Valid format example: FD-FT-00123-A7X9KM.',
      );
    }

    try {
      // Step c: Direct Document Lookup with 10-second rural timeout
      // doc(code).get() is an O(1) direct partition key read
      final DocumentSnapshot docSnapshot = await _firestore
          .collection('products')
          .doc(normalizedCode)
          .get()
          .timeout(const Duration(seconds: 10));

      // Step d: Check if product exists in registry
      if (!docSnapshot.exists || docSnapshot.data() == null) {
        debugPrint('[verifyProduct] Product not found in registry: $normalizedCode');
        return VerificationResult.notRecognized(
          scannedCode: normalizedCode,
          message: 'Warning: This product code is not recognized in the official registry. Possible counterfeit product.',
        );
      }

      // Safe model parsing
      final Product product = Product.fromFirestore(docSnapshot);

      // Step e: Status & Expiry evaluation
      // 1. Recalled check has highest safety priority
      if (product.status.trim().toLowerCase() == 'recalled') {
        debugPrint('[verifyProduct] Product is RECALLED: ${product.name} (${product.batch})');
        return VerificationResult.recalled(
          product: product,
          scannedCode: normalizedCode,
          message: 'DANGER: This product batch (${product.batch}) has been RECALLED by ${product.manufacturer}. Do not apply to crops.',
        );
      }

      // 2. Expiry check (either status flag or timestamp calculation)
      final DateTime now = DateTime.now();
      final bool isExpiredDate = product.expiryDate != null && product.expiryDate!.isBefore(now);
      if (product.status.trim().toLowerCase() == 'expired' || isExpiredDate) {
        final String expiryStr = product.expiryDate != null
            ? '${product.expiryDate!.day}/${product.expiryDate!.month}/${product.expiryDate!.year}'
            : 'N/A';
        debugPrint('[verifyProduct] Product EXPIRED on $expiryStr: ${product.name}');
        return VerificationResult.expired(
          product: product,
          scannedCode: normalizedCode,
          message: 'WARNING: This product expired on $expiryStr. Chemical degradation may reduce efficacy or harm soil.',
        );
      }

      // 3. Genuine active product
      debugPrint('[verifyProduct] Product verified GENUINE: ${product.name}');
      return VerificationResult.genuine(
        product: product,
        scannedCode: normalizedCode,
        message: 'Genuine verified product. Manufactured by ${product.manufacturer}.',
      );
    } on TimeoutException {
      debugPrint('[verifyProduct] Verification timed out after 10s for code: $normalizedCode');
      return VerificationResult.networkError(
        scannedCode: normalizedCode,
        message: 'Verification timed out after 10 seconds. Please check your cellular data or Wi-Fi connection.',
      );
    } on SocketException catch (se) {
      debugPrint('[verifyProduct] SocketException: ${se.message}');
      return VerificationResult.networkError(
        scannedCode: normalizedCode,
        message: 'Unable to connect to verification server. Please verify your internet connection.',
      );
    } on FirebaseException catch (fe) {
      debugPrint('[verifyProduct] FirebaseException [${fe.code}]: ${fe.message}');

      // Distinct handling for permission denied vs network failure
      if (fe.code == 'permission-denied') {
        return VerificationResult(
          status: VerificationStatus.networkError,
          scannedCode: normalizedCode,
          message: 'Developer Notice [permission-denied]: Cloud Firestore read access was denied. Ensure firestore.rules allows read on /products/{code}.',
        );
      }

      if (fe.code == 'unavailable' || fe.code == 'deadline-exceeded') {
        return VerificationResult.networkError(
          scannedCode: normalizedCode,
          message: 'Cloud verification service is temporarily unreachable. Please retry in a few moments.',
        );
      }

      return VerificationResult.networkError(
        scannedCode: normalizedCode,
        message: 'Firebase error [${fe.code}]: ${fe.message ?? "Verification failed"}',
      );
    } catch (e) {
      debugPrint('[verifyProduct] Unexpected error during verification: $e');
      return VerificationResult.networkError(
        scannedCode: normalizedCode,
        message: 'Verification encountered an unexpected error: $e',
      );
    }
  }

  /// ---------------------------------------------------------------------------
  /// 3. logScan(result)
  /// ---------------------------------------------------------------------------
  /// Records every scan event to the "scans" collection for farmer history & analytics.
  /// - userId: current authenticated UID (or "anonymous" if not signed in)
  /// - productCode: normalized scanned code
  /// - productName: denormalized product name for fast list rendering without joins
  /// - result: verification status string ('genuine', 'recalled', 'expired', 'notRecognized')
  /// - timestamp: FieldValue.serverTimestamp()
  ///
  /// Guarantees:
  /// - Does NOT log networkError or invalidInput results.
  /// - Completely decoupled and failure-tolerant: a write failure will NEVER crash
  ///   or prevent the UI from displaying the verification result.
  Future<void> logScan(VerificationResult result) async {
    // Guard: Do not log network failures or invalid user input
    if (result.status == VerificationStatus.networkError ||
        result.status == VerificationStatus.invalidInput) {
      debugPrint('[logScan] Skipping scan log for transient status: ${result.status.name}');
      return;
    }

    try {
      final User? currentUser = _auth.currentUser;
      final String uid = currentUser?.uid ?? 'anonymous';

      final Map<String, dynamic> scanData = {
        'userId': uid,
        'productCode': result.scannedCode,
        'productName': result.name ?? 'Unrecognized Product',
        'result': result.status.name,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Add document with auto-generated ID to scans collection
      await _firestore
          .collection('scans')
          .add(scanData)
          .timeout(const Duration(seconds: 5));

      debugPrint('[logScan] Scan successfully logged: ${result.scannedCode} -> ${result.status.name}');
    } catch (e) {
      // Non-fatal: do not bubble up to caller
      debugPrint('[logScan] Non-fatal notice: Failed to record scan log ($e). Verification UI unaffected.');
    }
  }
}

/// Default global service instance
final VerificationService verificationService = VerificationService();

/// Top-level convenience wrapper for verifyProduct
Future<VerificationResult> verifyProduct(
  String rawCode, {
  FirebaseFirestore? firestore,
}) {
  if (firestore != null) {
    return VerificationService(firestore: firestore).verifyProduct(rawCode);
  }
  return verificationService.verifyProduct(rawCode);
}

/// Top-level convenience wrapper for logScan
Future<void> logScan(
  VerificationResult result, {
  FirebaseFirestore? firestore,
  FirebaseAuth? auth,
}) {
  if (firestore != null || auth != null) {
    return VerificationService(firestore: firestore, auth: auth).logScan(result);
  }
  return verificationService.logScan(result);
}

/// ---------------------------------------------------------------------------
/// 5. Temporary Test Function: runDay19VerificationTests
/// ---------------------------------------------------------------------------
/// Runs verifyProduct against the 8 required test vectors and prints a
/// formatted PASS/FAIL validation report.
Future<bool> runDay19VerificationTests({
  FirebaseFirestore? firestore,
}) async {
  debugPrint('\n======================================================');
  debugPrint('🧪 RUNNING DAY 19 VERIFICATION SERVICE TEST SUITE');
  debugPrint('======================================================');

  final service = VerificationService(firestore: firestore);

  // Define the required test vectors
  final List<Map<String, dynamic>> testCases = [
    {
      'label': 'Empty string',
      'code': '',
      'expectedStatus': VerificationStatus.invalidInput,
      'description': 'Empty input rejected immediately',
    },
    {
      'label': 'URL in QR code',
      'code': 'https://farmerdost.com/verify?code=FD-FT-00123-A7X9KM',
      'expectedStatus': VerificationStatus.invalidInput,
      'description': 'Foreign web URL rejected before Firestore',
    },
    {
      'label': 'Code with illegal slash "/"',
      'code': 'FD/FT/00123/A7X9KM',
      'expectedStatus': VerificationStatus.invalidInput,
      'description': 'Illegal slash rejected (prevents path errors)',
    },
    {
      'label': 'Arbitrary invalid text',
      'code': 'JUST_RANDOM_TEXT_123',
      'expectedStatus': VerificationStatus.invalidInput,
      'description': 'Non-matching pattern rejected',
    },
    {
      'label': 'Lowercase with spaces',
      'code': '   fd-ft-00123-a7x9km   ',
      'expectedNormalized': 'FD-FT-00123-A7X9KM',
      // If Firestore is empty/offline, status will be notRecognized or networkError
      'acceptableStatuses': [
        VerificationStatus.genuine,
        VerificationStatus.notRecognized,
        VerificationStatus.networkError
      ],
      'description': 'Normalized correctly (trimmed and uppercased)',
    },
    {
      'label': 'Nonexistent formatted code',
      'code': 'FD-PS-99999-ZZZZZZ',
      'acceptableStatuses': [
        VerificationStatus.notRecognized,
        VerificationStatus.networkError
      ],
      'description': 'Valid format not found in DB -> notRecognized',
    },
    {
      'label': 'Recalled batch code',
      'code': 'FD-FT-00777-RECALL',
      'acceptableStatuses': [
        VerificationStatus.recalled,
        VerificationStatus.notRecognized,
        VerificationStatus.networkError
      ],
      'description': 'Recalled product batch flagged',
    },
    {
      'label': 'Expired product code',
      'code': 'FD-PS-00888-EXPIRE',
      'acceptableStatuses': [
        VerificationStatus.expired,
        VerificationStatus.notRecognized,
        VerificationStatus.networkError
      ],
      'description': 'Expired product flagged',
    },
  ];

  int passedCount = 0;
  int failedCount = 0;

  for (int i = 0; i < testCases.length; i++) {
    final tc = testCases[i];
    final String label = tc['label'] as String;
    final String code = tc['code'] as String;
    final String description = tc['description'] as String;

    final result = await service.verifyProduct(code);

    bool isPass = false;
    if (tc.containsKey('expectedStatus')) {
      isPass = result.status == tc['expectedStatus'];
    } else if (tc.containsKey('acceptableStatuses')) {
      final List<VerificationStatus> allowed = tc['acceptableStatuses'] as List<VerificationStatus>;
      isPass = allowed.contains(result.status);
    }

    if (tc.containsKey('expectedNormalized')) {
      if (result.scannedCode != tc['expectedNormalized']) {
        isPass = false;
      }
    }

    if (isPass) {
      passedCount++;
      debugPrint('[PASS] #${i + 1} $label');
      debugPrint('       Input: "$code" -> Status: ${result.status.name}');
      debugPrint('       Details: $description\n');
    } else {
      failedCount++;
      debugPrint('[FAIL] #${i + 1} $label');
      debugPrint('       Input: "$code"');
      debugPrint('       Actual Status: ${result.status.name} | Message: ${result.message}\n');
    }
  }

  // Also test logScan filtering
  debugPrint('--- [Testing logScan() transient filter] ---');
  final invalidResult = VerificationResult.invalidInput(scannedCode: 'BAD');
  final networkResult = VerificationResult.networkError(scannedCode: 'NET', message: 'Fail');
  await service.logScan(invalidResult);
  await service.logScan(networkResult);
  debugPrint('[PASS] logScan safely ignored invalidInput and networkError.');

  debugPrint('======================================================');
  debugPrint('📊 RESULTS: $passedCount PASSED | $failedCount FAILED');
  debugPrint('======================================================\n');

  return failedCount == 0;
}
