import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:farmer_dost_app/models/report_result.dart';
import 'package:farmer_dost_app/services/report_service.dart';

// ignore_for_file: subtype_of_sealed_class

class TestUser implements User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final String? displayName;

  TestUser({
    required this.uid,
    this.email = 'farmer@punjab.com',
    this.displayName = 'Gurpreet Singh',
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestFirebaseAuth implements FirebaseAuth {
  User? _user;
  TestFirebaseAuth([this._user]);

  @override
  User? get currentUser => _user;

  void setUser(User? user) => _user = user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Day 24 — ReportService Unit Tests', () {
    late FakeFirebaseFirestore fakeDb;
    late TestFirebaseAuth mockAuth;
    late ReportService service;

    setUp(() {
      fakeDb = FakeFirebaseFirestore();
      mockAuth = TestFirebaseAuth(TestUser(uid: 'farmer_uid_123'));
      service = ReportService(firestore: fakeDb, auth: mockAuth);
    });

    test('rejects malformed product code with invalidInput before touching database', () async {
      final result = await service.submitReport(productCode: 'BAD_CODE_123');
      expect(result.status, equals(ReportStatus.invalidInput));
      expect(result.isInvalidInput, isTrue);

      final reports = await fakeDb.collection('reports').get();
      expect(reports.docs.isEmpty, isTrue);
    });

    test('rejects note longer than 100 characters with invalidInput', () async {
      final longNote = 'A' * 101;
      final result = await service.submitReport(
        productCode: 'FD-FT-00123-A7X9KM',
        note: longNote,
      );
      expect(result.status, equals(ReportStatus.invalidInput));
      expect(result.message, contains('100 characters'));
    });

    test('rejects unauthenticated user with notSignedIn', () async {
      mockAuth.setUser(null); // Sign out
      final result = await service.submitReport(
        productCode: 'FD-FT-00123-A7X9KM',
        note: 'Counterfeit urea package',
      );
      expect(result.status, equals(ReportStatus.notSignedIn));
      expect(result.isNotSignedIn, isTrue);
    });

    test('successfully creates report with deterministic ID {uid}_{code}', () async {
      final result = await service.submitReport(
        productCode: 'FD-FT-00123-A7X9KM',
        note: 'Smells like chemical adulteration',
        location: const GeoPoint(31.6340, 74.8723), // Amritsar, Punjab
      );

      expect(result.status, equals(ReportStatus.success));
      expect(result.isSuccess, isTrue);
      expect(result.reportId, equals('farmer_uid_123_FD-FT-00123-A7X9KM'));

      // Check Firestore document
      final docSnapshot = await fakeDb
          .collection('reports')
          .doc('farmer_uid_123_FD-FT-00123-A7X9KM')
          .get();

      expect(docSnapshot.exists, isTrue);
      final data = docSnapshot.data()!;
      expect(data['productCode'], equals('FD-FT-00123-A7X9KM'));
      expect(data['userId'], equals('farmer_uid_123'));
      expect(data['status'], equals('pending'));
      expect(data['note'], equals('Smells like chemical adulteration'));
      expect(data['location'], equals(const GeoPoint(31.6340, 74.8723)));
    });

    test('returns alreadyReported when user reports same code a second time', () async {
      // First submission
      final firstResult = await service.submitReport(
        productCode: 'FD-FT-00123-A7X9KM',
        note: 'First report',
      );
      expect(firstResult.status, equals(ReportStatus.success));

      // Second submission for same product code by same user
      final secondResult = await service.submitReport(
        productCode: 'FD-FT-00123-A7X9KM',
        note: 'Second duplicate report attempt',
      );
      expect(secondResult.status, equals(ReportStatus.alreadyReported));
      expect(secondResult.isAlreadyReported, isTrue);
      expect(secondResult.message, contains('already submitted a report'));

      // Verify still only 1 document in database
      final reports = await fakeDb.collection('reports').get();
      expect(reports.docs.length, equals(1));
    });

    test('empty string note is treated as null', () async {
      final result = await service.submitReport(
        productCode: 'FD-PS-00555-M8N9K2',
        note: '   ',
      );
      expect(result.status, equals(ReportStatus.success));

      final doc = await fakeDb.collection('reports').doc('farmer_uid_123_FD-PS-00555-M8N9K2').get();
      expect(doc.data()!.containsKey('note'), isFalse);
    });
  });
}
