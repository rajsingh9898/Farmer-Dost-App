// ignore_for_file: subtype_of_sealed_class

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmer_dost_app/services/services.dart';

class TestUser implements User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final String? displayName;
  @override
  final String? phoneNumber;

  TestUser({
    required this.uid,
    this.email = 'farmer@punjab.com',
    this.displayName = 'Gurpreet Singh',
    this.phoneNumber = '+919876543210',
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
  group('Day 26 — ServiceHelper Unit Tests', () {
    test('maps TimeoutException to user-friendly message', () {
      final timeoutErr = TimeoutException('Timeout');
      final msg = ServiceHelper.mapErrorToUserMessage(timeoutErr);
      expect(msg.toLowerCase(), contains('too long'));
      expect(ServiceHelper.isNetworkError(timeoutErr), isTrue);
      expect(ServiceHelper.isPermissionDenied(timeoutErr), isFalse);
    });

    test('maps FirebaseException error codes appropriately', () {
      final unavailErr = FirebaseException(plugin: 'firestore', code: 'unavailable');
      expect(ServiceHelper.isNetworkError(unavailErr), isTrue);
      expect(ServiceHelper.mapErrorToUserMessage(unavailErr).toLowerCase(), contains('offline'));

      final permErr = FirebaseException(plugin: 'firestore', code: 'permission-denied');
      expect(ServiceHelper.isPermissionDenied(permErr), isTrue);
      expect(ServiceHelper.mapErrorToUserMessage(permErr).toLowerCase(), contains('restricted'));
    });
  });

  group('Day 26 — ProfileService Unit Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late TestFirebaseAuth mockAuth;
    late TestUser mockUser;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockUser = TestUser(
        uid: 'farmer_raj_101',
        email: 'raj@punjabkisan.in',
        displayName: 'Rajinder Singh',
        phoneNumber: '+919876543210',
      );
      mockAuth = TestFirebaseAuth(mockUser);
    });

    test('getProfile returns notSignedIn when no user is logged in', () async {
      final signedOutAuth = TestFirebaseAuth(null);
      final service = ProfileService(
        firestore: fakeFirestore,
        auth: signedOutAuth,
      );

      final result = await service.getProfile();
      expect(result.status, equals(ProfileStatus.notSignedIn));
      expect(result.isSuccess, isFalse);
    });

    test('getProfile auto-creates profile with server timestamp if missing', () async {
      final service = ProfileService(
        firestore: fakeFirestore,
        auth: mockAuth,
      );

      final result = await service.getProfile();
      expect(result.status, equals(ProfileStatus.success));
      expect(result.user, isNotNull);
      expect(result.user!.uid, equals('farmer_raj_101'));
      expect(result.user!.name, equals('Rajinder Singh'));

      // Verify Firestore has the document
      final docSnap = await fakeFirestore.collection('users').doc('farmer_raj_101').get();
      expect(docSnap.exists, isTrue);
      expect(docSnap.data()!['name'], equals('Rajinder Singh'));
      expect(docSnap.data()!['phone'], equals('+919876543210'));
      expect(docSnap.data()!['language'], equals('en'));
    });

    test('getProfile retrieves existing profile without overwriting it', () async {
      // Pre-seed an existing profile
      await fakeFirestore.collection('users').doc('farmer_raj_101').set({
        'name': 'Sardar Gurpreet',
        'phone': '+919812345678',
        'language': 'pa',
        'district': 'Ludhiana',
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 15)),
      });

      final service = ProfileService(
        firestore: fakeFirestore,
        auth: mockAuth,
      );

      final result = await service.getProfile();
      expect(result.status, equals(ProfileStatus.success));
      expect(result.user!.name, equals('Sardar Gurpreet'));
      expect(result.user!.language, equals('pa'));
      expect(result.user!.district, equals('Ludhiana'));
    });

    test('updateProfile updates fields without corrupting createdAt', () async {
      final initialDate = DateTime(2026, 2, 10);
      await fakeFirestore.collection('users').doc('farmer_raj_101').set({
        'name': 'Rajinder Singh',
        'phone': '+919876543210',
        'language': 'en',
        'district': 'Amritsar',
        'createdAt': Timestamp.fromDate(initialDate),
      });

      final service = ProfileService(
        firestore: fakeFirestore,
        auth: mockAuth,
      );

      final updateResult = await service.updateProfile(
        name: 'Rajinder Singh Sandhu',
        language: 'pa',
        district: 'Jalandhar',
      );

      expect(updateResult.status, equals(ProfileStatus.success));
      expect(updateResult.user!.name, equals('Rajinder Singh Sandhu'));
      expect(updateResult.user!.language, equals('pa'));

      // Check Firestore doc directly
      final docSnap = await fakeFirestore.collection('users').doc('farmer_raj_101').get();
      expect(docSnap.data()!['name'], equals('Rajinder Singh Sandhu'));
      expect(docSnap.data()!['district'], equals('Jalandhar'));
      // createdAt is preserved
      final savedTs = (docSnap.data()!['createdAt'] as Timestamp).toDate();
      expect(savedTs.year, equals(2026));
      expect(savedTs.month, equals(2));
      expect(savedTs.day, equals(10));
    });
  });

  group('Day 26 — ScanHistoryService Unit Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late TestFirebaseAuth mockAuth;
    late TestUser mockUser;

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();
      mockUser = TestUser(
        uid: 'farmer_user_99',
        displayName: 'Harpreet Kaur',
      );
      mockAuth = TestFirebaseAuth(mockUser);

      // Seed scan entries for this user and another user
      final scans = fakeFirestore.collection('scans');
      await scans.add({
        'userId': 'farmer_user_99',
        'productCode': 'FD-FT-00101-SCAN01',
        'productName': 'IFFCO Urea',
        'result': 'genuine',
        'timestamp': Timestamp.fromDate(DateTime(2026, 10, 1, 10, 0)),
      });
      await scans.add({
        'userId': 'farmer_user_99',
        'productCode': 'FD-PS-00202-SCAN02',
        'productName': 'Tata Rallis Insecticide',
        'result': 'recalled',
        'timestamp': Timestamp.fromDate(DateTime(2026, 10, 5, 14, 30)),
      });
      await scans.add({
        'userId': 'farmer_user_99',
        'productCode': 'FD-FT-00303-SCAN03',
        'productName': 'Unregistered Batch',
        'result': 'fake',
        'timestamp': Timestamp.fromDate(DateTime(2026, 10, 8, 9, 15)),
      });

      // Another user's scan
      await scans.add({
        'userId': 'other_farmer_888',
        'productCode': 'FD-FT-00999-SECRET',
        'productName': 'Private Product',
        'result': 'genuine',
        'timestamp': Timestamp.fromDate(DateTime(2026, 10, 9, 12, 0)),
      });
    });

    test('getScanHistory returns notSignedIn when unauthenticated', () async {
      final signedOutAuth = TestFirebaseAuth(null);
      final service = ScanHistoryService(
        firestore: fakeFirestore,
        auth: signedOutAuth,
      );

      final result = await service.getScanHistory();
      expect(result.status, equals(ScanHistoryStatus.notSignedIn));
      expect(result.scans, isEmpty);
    });

    test('getScanHistory returns only authenticated user scans ordered newest first', () async {
      final service = ScanHistoryService(
        firestore: fakeFirestore,
        auth: mockAuth,
      );

      final result = await service.getScanHistory();
      expect(result.status, equals(ScanHistoryStatus.success));
      expect(result.scans.length, equals(3));

      // Should be ordered newest first (Oct 8, then Oct 5, then Oct 1)
      expect(result.scans[0].productCode, equals('FD-FT-00303-SCAN03'));
      expect(result.scans[1].productCode, equals('FD-PS-00202-SCAN02'));
      expect(result.scans[2].productCode, equals('FD-FT-00101-SCAN01'));

      // None of the other user's scans should be present
      for (final s in result.scans) {
        expect(s.userId, equals('farmer_user_99'));
      }
    });

    test('getScanHistory respects limit', () async {
      final service = ScanHistoryService(
        firestore: fakeFirestore,
        auth: mockAuth,
      );

      final result = await service.getScanHistory(limit: 2);
      expect(result.status, equals(ScanHistoryStatus.success));
      expect(result.scans.length, equals(2));
      expect(result.hasMore, isTrue);
      expect(result.lastDocument, isNotNull);
    });
  });
}
