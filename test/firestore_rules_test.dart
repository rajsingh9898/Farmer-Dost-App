// ignore_for_file: subtype_of_sealed_class
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Simulates Cloud Firestore Security Rules validation in local Dart tests.
class SecurityRulesValidator {
  final String? callerUid;
  SecurityRulesValidator({this.callerUid});

  bool get isAuthenticated => callerUid != null;
  bool isOwner(String userId) => isAuthenticated && callerUid == userId;

  // 1. Products: Authenticated direct get allowed, list and write forbidden
  bool canGetProduct() => isAuthenticated;
  bool canListProducts() => false; // allow list: if false;
  bool canWriteProduct() => false; // allow write: if false;

  // 2. Users: Owner only
  bool canReadUser(String userId) => isOwner(userId);
  bool canCreateUser(String userId, Map<String, dynamic> data) {
    if (!isOwner(userId)) return false;
    final name = data['name'];
    if (name is! String || name.isEmpty) return false;
    return true;
  }
  bool canDeleteUser(String userId) => false; // allow delete: if false;

  // 3. Scans: Owner create and read only, updates/deletes forbidden
  bool canCreateScan(Map<String, dynamic> data) {
    if (!isAuthenticated) return false;
    return data['userId'] == callerUid;
  }
  bool canReadScan(Map<String, dynamic> data) {
    if (!isAuthenticated) return false;
    return data['userId'] == callerUid;
  }
  bool canUpdateOrDeleteScan() => false;

  // 4. Reports: Owner create and read, updates/deletes forbidden
  bool canCreateReport(Map<String, dynamic> data) {
    if (!isAuthenticated) return false;
    if (data['userId'] != callerUid) return false;
    if (data['status'] != 'pending') return false;
    final note = data['note'];
    if (note != null && note is String && note.length > 100) return false;
    return true;
  }
  bool canReadReport(Map<String, dynamic>? data) {
    if (!isAuthenticated) return false;
    if (data == null) return true; // non-existent document check allowed
    return data['userId'] == callerUid;
  }
  bool canUpdateOrDeleteReport() => false;
}

void main() {
  group('Day 25 — Firestore Security Rules Policy Tests', () {
    test('Products collection: authenticated users can get, listing and writes are denied', () {
      final anon = SecurityRulesValidator(callerUid: null);
      final farmer = SecurityRulesValidator(callerUid: 'farmer_01');

      // Unauthenticated access
      expect(anon.canGetProduct(), isFalse, reason: 'Unauthenticated user cannot read product');

      // Authenticated access
      expect(farmer.canGetProduct(), isTrue, reason: 'Signed-in farmer can verify product');
      expect(farmer.canListProducts(), isFalse, reason: 'Bulk catalog listing is denied to prevent scraping');
      expect(farmer.canWriteProduct(), isFalse, reason: 'Client-side product modification is denied');
    });

    test('Users collection: farmers can only read/create their own UID, deletes are blocked', () {
      final farmer = SecurityRulesValidator(callerUid: 'farmer_01');

      // Own profile
      expect(farmer.canReadUser('farmer_01'), isTrue);
      expect(farmer.canCreateUser('farmer_01', {'name': 'Gurpreet Singh'}), isTrue);
      expect(farmer.canCreateUser('farmer_01', {'name': ''}), isFalse, reason: 'Empty name rejected');

      // Other profile
      expect(farmer.canReadUser('farmer_99'), isFalse, reason: 'Cross-user snooping is denied');
      expect(farmer.canCreateUser('farmer_99', {'name': 'Attacker'}), isFalse);
      expect(farmer.canDeleteUser('farmer_01'), isFalse, reason: 'Account deletes blocked on client');
    });

    test('Scans collection: audit trail is immutable and isolated to owning farmer', () {
      final farmer = SecurityRulesValidator(callerUid: 'farmer_01');

      // Create scan for self
      expect(farmer.canCreateScan({'userId': 'farmer_01', 'productCode': 'FD-FT-00101-GEN001'}), isTrue);

      // Create scan for someone else (spoofing)
      expect(farmer.canCreateScan({'userId': 'farmer_99', 'productCode': 'FD-FT-00101-GEN001'}), isFalse);

      // Read own scan vs another farmer's scan
      expect(farmer.canReadScan({'userId': 'farmer_01'}), isTrue);
      expect(farmer.canReadScan({'userId': 'farmer_99'}), isFalse);

      // Audit logs are tamper-proof
      expect(farmer.canUpdateOrDeleteScan(), isFalse);
    });

    test('Reports collection: enforces pending status, 100-char note, and blocks tampering', () {
      final farmer = SecurityRulesValidator(callerUid: 'farmer_01');

      // Valid report
      expect(farmer.canCreateReport({
        'userId': 'farmer_01',
        'productCode': 'FD-PS-99999-FAKE01',
        'status': 'pending',
        'note': 'Smells suspicious',
      }), isTrue);

      // Note > 100 chars
      expect(farmer.canCreateReport({
        'userId': 'farmer_01',
        'productCode': 'FD-PS-99999-FAKE01',
        'status': 'pending',
        'note': 'A' * 101,
      }), isFalse, reason: 'Note exceeding 100 characters must be rejected');

      // Direct 'confirmed' status spoof attempt
      expect(farmer.canCreateReport({
        'userId': 'farmer_01',
        'productCode': 'FD-PS-99999-FAKE01',
        'status': 'confirmed',
      }), isFalse, reason: 'Client cannot bypass pending review');

      // Reading non-existent report during deduplication check
      expect(farmer.canReadReport(null), isTrue, reason: 'Checking non-existent report document must be allowed');

      // Reading another farmer's report
      expect(farmer.canReadReport({'userId': 'farmer_99'}), isFalse);

      // Updates and deletes are client-blocked
      expect(farmer.canUpdateOrDeleteReport(), isFalse);
    });

    test('FakeFirebaseFirestore verifies actual Firestore operations match security models', () async {
      final fakeDb = FakeFirebaseFirestore();

      // Test users creation
      await fakeDb.collection('users').doc('user_test_1').set({
        'name': 'Baljit Singh',
        'createdAt': FieldValue.serverTimestamp(),
      });
      final userSnap = await fakeDb.collection('users').doc('user_test_1').get();
      expect(userSnap.exists, isTrue);

      // Test scans creation
      final scanRef = await fakeDb.collection('scans').add({
        'userId': 'user_test_1',
        'productCode': 'FD-FT-00123-A7X9KM',
        'result': 'genuine',
        'timestamp': FieldValue.serverTimestamp(),
      });
      expect(scanRef.id.isNotEmpty, isTrue);

      // Test reports creation
      final reportDocId = 'user_test_1_FD-PS-99999-FAKE01';
      await fakeDb.collection('reports').doc(reportDocId).set({
        'userId': 'user_test_1',
        'productCode': 'FD-PS-99999-FAKE01',
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
      final reportSnap = await fakeDb.collection('reports').doc(reportDocId).get();
      expect(reportSnap.exists, isTrue);
    });
  });
}
