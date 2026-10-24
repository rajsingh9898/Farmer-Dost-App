import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmer_dost_app/models/product_model.dart';
import 'package:farmer_dost_app/models/report_model.dart';
import 'package:farmer_dost_app/models/user_model.dart';
import 'package:farmer_dost_app/models/scan_model.dart';
import 'package:farmer_dost_app/data/sample_products.dart';
import 'package:farmer_dost_app/services/firestore_service.dart';

void main() {
  group('Day 15 — ProductModel Schema & Logic Tests', () {
    test('ProductModel serialization and deserialization preserves all schema fields', () {
      final now = DateTime.now();
      final mfgDate = DateTime(2026, 1, 1);
      final expDate = DateTime(2028, 1, 1);

      final product = ProductModel(
        code: 'KRIBHCO-UREA-2026',
        name: 'KRIBHCO Neem Coated Urea 45kg',
        batch: 'BATCH-2026-99A',
        manufacturer: 'Krishak Bharati Cooperative Ltd',
        status: 'active',
        type: 'fertilizer',
        manufactureDate: mfgDate,
        expiryDate: expDate,
        createdAt: now,
        dosage: '45-50 kg per acre during first irrigation',
      );

      final map = product.toMap();
      expect(map['code'], 'KRIBHCO-UREA-2026');
      expect(map['name'], 'KRIBHCO Neem Coated Urea 45kg');
      expect(map['batch'], 'BATCH-2026-99A');
      expect(map['manufacturer'], 'Krishak Bharati Cooperative Ltd');
      expect(map['status'], 'active');
      expect(map['type'], 'fertilizer');
      expect(map['dosage'], '45-50 kg per acre during first irrigation');
      expect(map['manufactureDate'], isA<Timestamp>());
      expect(map['expiryDate'], isA<Timestamp>());

      // Reconstruct from Map
      final reconstructed = ProductModel.fromMap(map, 'KRIBHCO-UREA-2026');
      expect(reconstructed.code, 'KRIBHCO-UREA-2026');
      expect(reconstructed.name, 'KRIBHCO Neem Coated Urea 45kg');
      expect(reconstructed.isGenuine, isTrue);
      expect(reconstructed.isExpired, isFalse);
    });

    test('ProductModel isGenuine returns true for active and genuine status, false otherwise', () {
      final activeProduct = ProductModel(
        code: 'TEST-1',
        name: 'Active Product',
        batch: 'B1',
        manufacturer: 'Mfg',
        status: 'active',
      );
      final genuineProduct = ProductModel(
        code: 'TEST-2',
        name: 'Genuine Product',
        batch: 'B2',
        manufacturer: 'Mfg',
        status: 'genuine',
      );
      final fakeProduct = ProductModel(
        code: 'TEST-3',
        name: 'Fake Product',
        batch: 'B3',
        manufacturer: 'Mfg',
        status: 'fake',
      );

      expect(activeProduct.isGenuine, isTrue);
      expect(genuineProduct.isGenuine, isTrue);
      expect(fakeProduct.isGenuine, isFalse);
    });

    test('ProductModel isExpired calculates past expiry date correctly', () {
      final pastDate = DateTime(2020, 1, 1);
      final futureDate = DateTime(2030, 1, 1);

      final expiredProduct = ProductModel(
        code: 'EXP-1',
        name: 'Expired Chemical',
        batch: 'B-OLD',
        manufacturer: 'Mfg',
        status: 'active',
        expiryDate: pastDate,
      );

      final validProduct = ProductModel(
        code: 'VAL-1',
        name: 'Fresh Chemical',
        batch: 'B-NEW',
        manufacturer: 'Mfg',
        status: 'active',
        expiryDate: futureDate,
      );

      expect(expiredProduct.isExpired, isTrue);
      expect(validProduct.isExpired, isFalse);
    });
  });

  group('Day 15 — ReportModel Schema Tests', () {
    test('ReportModel handles GeoPoint, note, and status correctly', () {
      final geoPoint = const GeoPoint(30.9010, 75.8573);
      final report = ReportModel(
        productCode: 'FAKE-999',
        userId: 'farmer_usr_123',
        geoPoint: geoPoint,
        note: 'Faded packaging bought from village shop',
        status: 'pending',
      );

      final map = report.toMap();
      expect(map['productCode'], 'FAKE-999');
      expect(map['userId'], 'farmer_usr_123');
      expect(map['location'], geoPoint);
      expect(map['note'], 'Faded packaging bought from village shop');
      expect(map['status'], 'pending');

      final reconstructed = ReportModel.fromMap(map, 'doc_rpt_456');
      expect(reconstructed.id, 'doc_rpt_456');
      expect(reconstructed.productCode, 'FAKE-999');
      expect(reconstructed.geoPoint?.latitude, closeTo(30.90, 0.01));
      expect(reconstructed.geoPoint?.longitude, closeTo(75.85, 0.01));
      expect(reconstructed.status, 'pending');
    });
  });

  group('Day 15 — UserModel Schema Tests', () {
    test('UserModel supports language preference and district fields', () {
      final user = UserModel(
        uid: 'user_harpreet',
        name: 'Harpreet Singh',
        phone: '+919876543210',
        language: 'pa',
        district: 'Ludhiana, Punjab',
      );

      final map = user.toMap();
      expect(map['uid'], 'user_harpreet');
      expect(map['name'], 'Harpreet Singh');
      expect(map['phone'], '+919876543210');
      expect(map['language'], 'pa');
      expect(map['district'], 'Ludhiana, Punjab');

      final reconstructed = UserModel.fromMap(map, 'user_harpreet');
      expect(reconstructed.language, 'pa');
      expect(reconstructed.district, 'Ludhiana, Punjab');
    });
  });

  group('Day 15 — ScanModel Schema Tests', () {
    test('ScanModel serialization and deserialization', () {
      final scan = ScanModel(
        userId: 'usr_789',
        productCode: 'IFFCO-DAP-50KG',
        productName: 'IFFCO DAP 50kg',
        result: 'genuine',
      );

      final map = scan.toMap();
      expect(map['userId'], 'usr_789');
      expect(map['productCode'], 'IFFCO-DAP-50KG');
      expect(map['productName'], 'IFFCO DAP 50kg');
      expect(map['result'], 'genuine');

      final reconstructed = ScanModel.fromMap(map, 'scan_101');
      expect(reconstructed.id, 'scan_101');
      expect(reconstructed.result, 'genuine');
    });
  });

  group('Day 15 — Sample Products Catalog & FirestoreService Verification', () {
    test('sampleProductsCatalog contains exactly 20 realistic agricultural products', () {
      expect(sampleProductsCatalog.length, 20);

      for (final p in sampleProductsCatalog) {
        expect(p.code.isNotEmpty, isTrue);
        expect(p.name.isNotEmpty, isTrue);
        expect(p.manufacturer.isNotEmpty, isTrue);
        expect(p.batch.isNotEmpty, isTrue);
        expect(['fertilizer', 'pesticide'].contains(p.type), isTrue);
        expect(['active', 'expired', 'recalled'].contains(p.status), isTrue);
        expect(p.manufactureDate, isNotNull);
        expect(p.expiryDate, isNotNull);
      }
    });

    test('FirestoreService offline fallback verifies sample catalog products', () async {
      final service = FirestoreService();
      service.useDemoFallbackIfOffline = true;

      // 1. Verify genuine sample product from catalog
      final dapProduct = await service.verifyProduct('IFFCO-DAP-50KG');
      expect(dapProduct, isNotNull);
      expect(dapProduct!.name, contains('IFFCO'));
      expect(dapProduct.type, 'fertilizer');
      expect(dapProduct.isGenuine, isTrue);

      // 2. Verify pesticide product
      final coragen = await service.verifyProduct('BAYER-CORAGEN');
      expect(coragen, isNotNull);
      expect(coragen!.name, contains('Coragen'));
      expect(coragen.type, 'pesticide');

      // 3. Verify expired product
      final expired = await service.verifyProduct('EXPIRED-CHLORPYRIFOS');
      expect(expired, isNotNull);
      expect(expired!.isExpired, isTrue);

      // 4. Verify fake product
      final fake = await service.verifyProduct('FAKE-456');
      expect(fake, isNotNull);
      expect(fake!.isGenuine, isFalse);

      // 5. Verify unrecognized code
      final unrecognized = await service.verifyProduct('TOTALLY-RANDOM-CODE-999');
      expect(unrecognized, isNull);
    });
  });
}
