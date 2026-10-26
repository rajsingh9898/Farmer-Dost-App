import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmer_dost_app/models/verification_result.dart';
import 'package:farmer_dost_app/services/verification_service.dart';

void main() {
  group('Day 19 — VerificationResult & Product Model Tests', () {
    test('Product.fromMap correctly parses standard fields and Timestamps', () {
      final now = DateTime.now();
      final map = {
        'code': 'FD-FT-00123-A7X9KM',
        'name': 'Punjab Shaktiman Urea',
        'manufacturer': 'Malwa Kisan Fertilizers',
        'batch': 'MKA-2026-B1',
        'type': 'fertilizer',
        'status': 'active',
        'manufactureDate': Timestamp.fromDate(DateTime(2026, 1, 15)),
        'expiryDate': Timestamp.fromDate(now.add(const Duration(days: 365))),
        'dosage': '45 kg per acre',
      };

      final product = Product.fromMap(map, 'FD-FT-00123-A7X9KM');

      expect(product.code, equals('FD-FT-00123-A7X9KM'));
      expect(product.name, equals('Punjab Shaktiman Urea'));
      expect(product.manufacturer, equals('Malwa Kisan Fertilizers'));
      expect(product.type, equals('fertilizer'));
      expect(product.isGenuine, isTrue);
      expect(product.isRecalled, isFalse);
      expect(product.isExpired, isFalse);
      expect(product.dosage, equals('45 kg per acre'));
    });

    test('Product safely handles null/missing fields and string dates', () {
      final emptyMap = <String, dynamic>{};
      final product = Product.fromMap(emptyMap, 'FALLBACK-ID');

      expect(product.code, equals('FALLBACK-ID'));
      expect(product.name, equals('Unknown Product'));
      expect(product.manufacturer, equals('Unknown Manufacturer'));
      expect(product.type, equals('fertilizer'));
      expect(product.status, equals('active'));
      expect(product.manufactureDate, isNull);
      expect(product.expiryDate, isNull);
    });

    test('Product flags expired and recalled states accurately', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 10));
      final expiredProduct = Product(
        code: 'FD-PS-00001-EX1234',
        name: 'Expired Chlorpyrifos',
        manufacturer: 'Agro Labs',
        batch: 'B1',
        type: 'pesticide',
        status: 'active',
        expiryDate: pastDate,
      );
      expect(expiredProduct.isExpired, isTrue);

      final recalledProduct = Product(
        code: 'FD-FT-00002-RC1234',
        name: 'Recalled Urea',
        manufacturer: 'Agro Labs',
        batch: 'B2',
        type: 'fertilizer',
        status: 'recalled',
      );
      expect(recalledProduct.isRecalled, isTrue);
    });

    test('VerificationResult convenience factories populate properties accurately', () {
      final prod = Product(
        code: 'FD-FT-00123-A7X9KM',
        name: 'IFFCO Urea',
        manufacturer: 'IFFCO',
        batch: 'B-99',
        type: 'fertilizer',
        status: 'active',
        manufactureDate: DateTime(2026, 1, 1),
        expiryDate: DateTime(2028, 1, 1),
      );

      final genuine = VerificationResult.genuine(product: prod, scannedCode: 'FD-FT-00123-A7X9KM');
      expect(genuine.status, equals(VerificationStatus.genuine));
      expect(genuine.isGenuine, isTrue);
      expect(genuine.shouldLog, isTrue);
      expect(genuine.name, equals('IFFCO Urea'));

      final invalid = VerificationResult.invalidInput(scannedCode: 'BAD');
      expect(invalid.status, equals(VerificationStatus.invalidInput));
      expect(invalid.isInvalidInput, isTrue);
      expect(invalid.shouldLog, isFalse);

      final netErr = VerificationResult.networkError(scannedCode: 'NET', message: 'Timeout');
      expect(netErr.status, equals(VerificationStatus.networkError));
      expect(netErr.isNetworkError, isTrue);
      expect(netErr.shouldLog, isFalse);
    });
  });

  group('Day 19 — VerificationService Input Validation Tests', () {
    final service = VerificationService();

    test('verifyProduct rejects empty string with invalidInput before Firestore', () async {
      final res = await service.verifyProduct('');
      expect(res.status, equals(VerificationStatus.invalidInput));
      expect(res.scannedCode, isEmpty);
    });

    test('verifyProduct rejects foreign URL with invalidInput', () async {
      final res = await service.verifyProduct('https://example.com/qr?code=123');
      expect(res.status, equals(VerificationStatus.invalidInput));
    });

    test('verifyProduct rejects codes with illegal "/" character', () async {
      final res = await service.verifyProduct('FD/FT/00123/A7X9KM');
      expect(res.status, equals(VerificationStatus.invalidInput));
    });

    test('verifyProduct rejects invalid type or serial length', () async {
      final badType = await service.verifyProduct('FD-XX-00123-A7X9KM');
      expect(badType.status, equals(VerificationStatus.invalidInput));

      final shortSerial = await service.verifyProduct('FD-FT-123-A7X9KM');
      expect(shortSerial.status, equals(VerificationStatus.invalidInput));

      final shortRandom = await service.verifyProduct('FD-FT-00123-ABC');
      expect(shortRandom.status, equals(VerificationStatus.invalidInput));
    });

    test('runDay19VerificationTests executes all 8 vectors cleanly', () async {
      final success = await runDay19VerificationTests();
      expect(success, isTrue);
    });
  });
}
