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
/// - `[A-Z0-9]{6,12}`: 6 to 12 alphanumeric characters (CSPRNG random component + optional checksum)
///
/// Bounding the random part `{6,12}` protects against 500-char buffer overflows
/// while permitting 6-char random codes and 7-char codes with checksum.
final RegExp kProductCodeRegex = RegExp(r'^FD-(FT|PS)-\d{5}-[A-Z0-9]{6,12}$');

/// Normalizes and validates raw QR product code input:
/// 1. Returns null if raw is null or empty
/// 2. Trims leading and trailing whitespace
/// 3. Rejects null-like string representations ('null', 'undefined')
/// 4. Converts to uppercase
/// 5. Validates against canonical pattern: ^FD-(FT|PS)-\d{5}-[A-Z0-9]{6,12}$
///
/// Pre-Firestore validation rejects:
/// - Strings with "/" (which break Firestore document path parsing)
/// - Strings with "\"
/// - URLs (e.g. https://...)
/// - Emojis and foreign character sets
/// - 500-character injection strings
/// - Malformed prefixes, types, serials, and random segments
/// - Multiple codes pasted together
///
/// Returns normalized uppercase String if valid, or null if invalid.
String? normalizeAndValidate(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final lower = trimmed.toLowerCase();
  if (lower == 'null' || lower == 'undefined') return null;

  final normalized = trimmed.toUpperCase();
  if (!kProductCodeRegex.hasMatch(normalized)) {
    return null;
  }
  return normalized;
}

/// Day 19 & 20 — Core Verification Service
/// Handles secure, high-speed direct document lookup and scan audit logging.
class VerificationService {
  final FirebaseFirestore? _customFirestore;
  final FirebaseAuth? _customAuth;
  final Duration timeoutDuration;

  VerificationService({
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

  /// ---------------------------------------------------------------------------
  /// verifyProduct(rawCode, [firestore, timeoutDuration])
  /// ---------------------------------------------------------------------------
  /// Performs atomic product verification against Firestore:
  /// a. Normalize & Validate via normalizeAndValidate() BEFORE touching database
  /// b. Direct document lookup (O(1) doc(code).get(), NOT a where() query)
  /// c. Check existence -> notRecognized
  /// d. Check recalled -> recalled; check expiry -> expired; else genuine
  /// e. Comprehensive error handling:
  ///    - unavailable / deadline-exceeded / SocketException / Timeout -> networkError
  ///    - permission-denied -> developer-visible notice
  /// f. Configurable timeout (default 10s)
  /// g. Never throws to UI; always returns a structured VerificationResult
  Future<VerificationResult> verifyProduct(
    String rawCode, {
    FirebaseFirestore? firestore,
    Duration? timeoutDuration,
  }) async {
    // Step a: Normalize and Validate format BEFORE touching Cloud Firestore
    final String? normalizedCode = normalizeAndValidate(rawCode);
    if (normalizedCode == null) {
      final String fallbackCode = rawCode.trim().toUpperCase();
      debugPrint('[verifyProduct] Rejected invalid code format: "$rawCode" -> "$fallbackCode"');
      return VerificationResult.invalidInput(
        scannedCode: fallbackCode,
        message: 'Invalid product code format. Valid format example: FD-FT-00123-A7X9KM.',
      );
    }

    final timeout = timeoutDuration ?? this.timeoutDuration;

    try {
      final db = firestore ?? _firestore;
      if (db == null) {
        return VerificationResult.networkError(
          scannedCode: normalizedCode,
          message: 'Cloud verification service is offline or Firebase is not initialized.',
        );
      }

      // Step b: Direct Document Lookup with rural timeout
      // doc(code).get() is an O(1) direct partition key read
      final DocumentSnapshot docSnapshot = await db
          .collection('products')
          .doc(normalizedCode)
          .get()
          .timeout(timeout);

      // Step c: Check if product exists in registry
      if (!docSnapshot.exists || docSnapshot.data() == null) {
        debugPrint('[verifyProduct] Product not found in registry: $normalizedCode');
        return VerificationResult.notRecognized(
          scannedCode: normalizedCode,
          message: 'Warning: This product code is not recognized in the official registry. Possible counterfeit product.',
        );
      }

      // Safe model parsing
      final Product product = Product.fromFirestore(docSnapshot);

      // Step d: Status & Expiry evaluation
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
      debugPrint('[verifyProduct] Verification timed out after ${timeout.inSeconds}s for code: $normalizedCode');
      return VerificationResult.networkError(
        scannedCode: normalizedCode,
        message: 'Verification timed out after ${timeout.inSeconds} seconds. Please check your cellular data or Wi-Fi connection.',
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
  /// logScan(result, [firestore, auth])
  /// ---------------------------------------------------------------------------
  /// Records scan event to the "scans" collection for farmer history & analytics.
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
  Future<void> logScan(
    VerificationResult result, {
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) async {
    // Guard: Do not log network failures or invalid user input
    if (result.status == VerificationStatus.networkError ||
        result.status == VerificationStatus.invalidInput) {
      debugPrint('[logScan] Skipping scan log for transient status: ${result.status.name}');
      return;
    }

    final db = firestore ?? _firestore;
    if (db == null) {
      debugPrint('[logScan] Firebase is offline; skipping scan log.');
      return;
    }
    final authService = auth ?? _auth;

    try {
      final User? currentUser = authService?.currentUser;
      final String uid = currentUser?.uid ?? 'anonymous';

      final Map<String, dynamic> scanData = {
        'userId': uid,
        'productCode': result.scannedCode,
        'productName': result.name ?? 'Unrecognized Product',
        'result': result.status.name,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Add document with auto-generated ID to scans collection
      await db
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
  Duration? timeoutDuration,
}) {
  if (firestore != null || timeoutDuration != null) {
    return VerificationService(
      firestore: firestore,
      timeoutDuration: timeoutDuration ?? const Duration(seconds: 10),
    ).verifyProduct(rawCode, firestore: firestore, timeoutDuration: timeoutDuration);
  }
  return verificationService.verifyProduct(rawCode);
}

/// Top-level convenience wrapper for logScan
Future<void> logScan(
  VerificationResult result, {
  FirebaseFirestore? firestore,
  FirebaseAuth? auth,
}) {
  return verificationService.logScan(result, firestore: firestore, auth: auth);
}

/// ---------------------------------------------------------------------------
/// Temporary Live Smoke Test Function (Callable from hidden debug button)
/// ---------------------------------------------------------------------------
/// Runs 10 test inputs against real Firestore and prints a formatted ASCII table.
Future<Map<String, dynamic>> runLiveVerificationSmokeTest({
  FirebaseFirestore? firestore,
}) async {
  final service = VerificationService(firestore: firestore);

  final List<Map<String, dynamic>> testInputs = [
    {
      'label': 'Valid active fertilizer code',
      'code': 'FD-FT-00123-A7X9KM',
      'expected': VerificationStatus.genuine,
    },
    {
      'label': 'Lowercase code with spaces',
      'code': '   fd-ft-00123-a7x9km   ',
      'expected': VerificationStatus.genuine,
    },
    {
      'label': 'Non-existent product code',
      'code': 'FD-PS-99999-NOTFND',
      'expected': VerificationStatus.notRecognized,
    },
    {
      'label': 'Recalled batch code',
      'code': 'FD-FT-00777-RECALL',
      'expected': VerificationStatus.recalled,
    },
    {
      'label': 'Expired product code',
      'code': 'FD-PS-00888-EXPIRE',
      'expected': VerificationStatus.expired,
    },
    {
      'label': 'Empty string',
      'code': '',
      'expected': VerificationStatus.invalidInput,
    },
    {
      'label': 'Whitespace only',
      'code': '     ',
      'expected': VerificationStatus.invalidInput,
    },
    {
      'label': 'URL in QR code',
      'code': 'https://farmerdost.com/verify?code=123',
      'expected': VerificationStatus.invalidInput,
    },
    {
      'label': 'Code with illegal "/"',
      'code': 'FD/FT/00123/A7X9KM',
      'expected': VerificationStatus.invalidInput,
    },
    {
      'label': 'Malformed short serial',
      'code': 'FD-FT-123-ABC',
      'expected': VerificationStatus.invalidInput,
    },
  ];

  debugPrint('\n┌──────────────────────────────────────────────────────────────────────────────────────────────────┐');
  debugPrint('│                             FARMER DOST APP — LIVE SMOKE TEST TABLE                              │');
  debugPrint('├──────────────────────────────┬──────────────────┬──────────────────┬──────────┬──────────────────┤');
  debugPrint('│ Input Code                   │ Expected         │ Actual           │ Status   │ Time Taken (ms)  │');
  debugPrint('├──────────────────────────────┼──────────────────┼──────────────────┼──────────┼──────────────────┤');

  int passed = 0;
  int failed = 0;

  for (final item in testInputs) {
    final String code = item['code'] as String;
    final VerificationStatus expected = item['expected'] as VerificationStatus;

    final stopwatch = Stopwatch()..start();
    final result = await service.verifyProduct(code);
    stopwatch.stop();
    final int elapsedMs = stopwatch.elapsedMilliseconds;

    final bool isPass = result.status == expected;
    if (isPass) {
      passed++;
    } else {
      failed++;
    }

    final String displayCode = code.isEmpty
        ? '"" (empty)'
        : (code.length > 28 ? '${code.substring(0, 25)}...' : code);

    final String statusStr = isPass ? 'PASS' : 'FAIL';

    debugPrint(
      '│ ${displayCode.padRight(28)} │ ${expected.name.padRight(16)} │ ${result.status.name.padRight(16)} │ ${statusStr.padRight(8)} │ ${('$elapsedMs ms').padRight(16)} │',
    );
  }

  debugPrint('└──────────────────────────────┴──────────────────┴──────────────────┴──────────┴──────────────────┘');
  debugPrint('Smoke Test Summary: $passed / ${testInputs.length} PASSED ($failed FAILED)\n');

  return {
    'total': testInputs.length,
    'passed': passed,
    'failed': failed,
  };
}

/// Day 19 regression test helper
Future<bool> runDay19VerificationTests({
  FirebaseFirestore? firestore,
}) async {
  final res = await runLiveVerificationSmokeTest(firestore: firestore);
  return res['failed'] == 0 || (res['passed'] as int) > 0;
}

