// ignore_for_file: subtype_of_sealed_class
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmer_dost_app/models/verification_result.dart';
import 'package:farmer_dost_app/services/verification_service.dart';

/// Lightweight custom Firestore mock to simulate network exceptions and server timeouts
class ThrowingFirestore implements FirebaseFirestore {
  final FirebaseException exception;
  ThrowingFirestore(this.exception);

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return _ThrowingCollectionReference(exception);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ThrowingCollectionReference implements CollectionReference<Map<String, dynamic>> {
  final FirebaseException exception;
  _ThrowingCollectionReference(this.exception);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    return _ThrowingDocumentReference(exception);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ThrowingDocumentReference implements DocumentReference<Map<String, dynamic>> {
  final FirebaseException exception;
  _ThrowingDocumentReference(this.exception);

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) {
    return Future.error(exception);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Lightweight Firestore mock to simulate network latency and timeouts
class HangingFirestore implements FirebaseFirestore {
  final Duration delay;
  HangingFirestore(this.delay);

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return _HangingCollectionReference(delay);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _HangingCollectionReference implements CollectionReference<Map<String, dynamic>> {
  final Duration delay;
  _HangingCollectionReference(this.delay);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    return _HangingDocumentReference(delay);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _HangingDocumentReference implements DocumentReference<Map<String, dynamic>> {
  final Duration delay;
  _HangingDocumentReference(this.delay);

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) {
    return Future.delayed(delay, () => throw StateError('Should have timed out'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Day 20 — Firestore Integration Tests (fake_cloud_firestore)', () {
    late FakeFirebaseFirestore fakeDb;
    late VerificationService service;

    setUp(() async {
      fakeDb = FakeFirebaseFirestore();
      service = VerificationService(firestore: fakeDb);

      // Seed 1: Active Genuine Product (future expiry)
      await fakeDb.collection('products').doc('FD-FT-00123-A7X9KM').set({
        'code': 'FD-FT-00123-A7X9KM',
        'name': 'IFFCO Neem Coated Urea 45kg',
        'manufacturer': 'Indian Farmers Fertiliser Cooperative Ltd',
        'batch': 'BATCH-2026-08',
        'type': 'fertilizer',
        'status': 'active',
        'manufactureDate': Timestamp.fromDate(DateTime(2026, 2, 1)),
        'expiryDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 365))),
        'createdAt': Timestamp.now(),
        'dosage': '45 kg per acre',
      });

      // Seed 2: Recalled Product Batch
      await fakeDb.collection('products').doc('FD-FT-00777-RECALL').set({
        'code': 'FD-FT-00777-RECALL',
        'name': 'Kisan Shakti DAP (Recalled Lot)',
        'manufacturer': 'Malwa Agri Chemicals',
        'batch': 'RCL-2026-99',
        'type': 'fertilizer',
        'status': 'recalled',
        'manufactureDate': Timestamp.fromDate(DateTime(2026, 1, 15)),
        'expiryDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 180))),
        'createdAt': Timestamp.now(),
      });

      // Seed 3: Expired Product (expiryDate in past)
      await fakeDb.collection('products').doc('FD-PS-00888-EXPIRE').set({
        'code': 'FD-PS-00888-EXPIRE',
        'name': 'Dursban Chlorpyrifos 20% EC',
        'manufacturer': 'Sutlej Crop Protection',
        'batch': 'EXP-2022-01',
        'type': 'pesticide',
        'status': 'active', // Status marked active in old DB entry, but past expiryDate
        'manufactureDate': Timestamp.fromDate(DateTime(2022, 1, 1)),
        'expiryDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 60))),
        'createdAt': Timestamp.now(),
      });
    });

    test('verifies active seeded product as genuine with full details', () async {
      final result = await service.verifyProduct('FD-FT-00123-A7X9KM');

      expect(result.status, equals(VerificationStatus.genuine));
      expect(result.isGenuine, isTrue);
      expect(result.scannedCode, equals('FD-FT-00123-A7X9KM'));
      expect(result.name, equals('IFFCO Neem Coated Urea 45kg'));
      expect(result.manufacturer, equals('Indian Farmers Fertiliser Cooperative Ltd'));
      expect(result.batch, equals('BATCH-2026-08'));
      expect(result.type, equals('fertilizer'));
    });

    test('verifies lowercase input matches uppercase document ID', () async {
      final result = await service.verifyProduct('   fd-ft-00123-a7x9km   ');

      expect(result.status, equals(VerificationStatus.genuine));
      expect(result.scannedCode, equals('FD-FT-00123-A7X9KM'));
      expect(result.name, equals('IFFCO Neem Coated Urea 45kg'));
    });

    test('flags recalled product batch accurately', () async {
      final result = await service.verifyProduct('FD-FT-00777-RECALL');

      expect(result.status, equals(VerificationStatus.recalled));
      expect(result.isRecalled, isTrue);
      expect(result.message, contains('RECALLED'));
    });

    test('flags expired product based on past expiryDate', () async {
      final result = await service.verifyProduct('FD-PS-00888-EXPIRE');

      expect(result.status, equals(VerificationStatus.expired));
      expect(result.isExpired, isTrue);
      expect(result.message, contains('expired'));
    });

    test('returns notRecognized when valid format is not found in database', () async {
      final result = await service.verifyProduct('FD-PS-99999-NOTFND');

      expect(result.status, equals(VerificationStatus.notRecognized));
      expect(result.isNotRecognized, isTrue);
      expect(result.scannedCode, equals('FD-PS-99999-NOTFND'));
    });

    test('simulates network failure (unavailable) -> networkError, NEVER notRecognized', () async {
      final throwingDb = ThrowingFirestore(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable', message: 'Network offline'),
      );

      final result = await service.verifyProduct('FD-FT-00123-A7X9KM', firestore: throwingDb);

      expect(result.status, equals(VerificationStatus.networkError));
      expect(result.isNetworkError, isTrue);
      expect(result.status, isNot(equals(VerificationStatus.notRecognized)));
      expect(result.message, contains('temporarily unreachable'));
    });

    test('surfaces permission-denied as distinct developer notice', () async {
      final throwingDb = ThrowingFirestore(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied', message: 'Rules denied'),
      );

      final result = await service.verifyProduct('FD-FT-00123-A7X9KM', firestore: throwingDb);

      expect(result.status, equals(VerificationStatus.networkError));
      expect(result.message, contains('Developer Notice [permission-denied]'));
      expect(result.status, isNot(equals(VerificationStatus.notRecognized)));
    });

    test('timeout actually fires when database hangs and returns networkError', () async {
      // Inject hanging future with 50ms test timeout
      final hangingDb = HangingFirestore(const Duration(milliseconds: 500));

      final result = await service.verifyProduct(
        'FD-FT-00123-A7X9KM',
        firestore: hangingDb,
        timeoutDuration: const Duration(milliseconds: 50),
      );

      expect(result.status, equals(VerificationStatus.networkError));
      expect(result.isNetworkError, isTrue);
      expect(result.message, contains('timed out'));
    });

    test('logScan writes genuine scans to Firestore, but skips transient results', () async {
      final genuineResult = VerificationResult.genuine(
        product: Product(
          code: 'FD-FT-00123-A7X9KM',
          name: 'IFFCO Urea',
          manufacturer: 'IFFCO',
          batch: 'B1',
          type: 'fertilizer',
          status: 'active',
        ),
        scannedCode: 'FD-FT-00123-A7X9KM',
      );

      final invalidResult = VerificationResult.invalidInput(scannedCode: 'BAD');
      final networkResult = VerificationResult.networkError(scannedCode: 'NET', message: 'Timeout');

      // Attempt to log all three
      await service.logScan(genuineResult, firestore: fakeDb);
      await service.logScan(invalidResult, firestore: fakeDb);
      await service.logScan(networkResult, firestore: fakeDb);

      // Verify only the genuine scan was saved to "scans"
      final scansSnapshot = await fakeDb.collection('scans').get();
      expect(scansSnapshot.docs.length, equals(1));

      final logged = scansSnapshot.docs.first.data();
      expect(logged['productCode'], equals('FD-FT-00123-A7X9KM'));
      expect(logged['productName'], equals('IFFCO Urea'));
      expect(logged['result'], equals('genuine'));
    });
  });
}
