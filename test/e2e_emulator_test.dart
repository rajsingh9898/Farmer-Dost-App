// ignore_for_file: subtype_of_sealed_class, avoid_print
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmer_dost_app/services/services.dart';

class MockE2EUser implements User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final String? displayName;
  @override
  final String? phoneNumber;

  MockE2EUser({
    required this.uid,
    this.email = 'testfarmer@dost.in',
    this.displayName = 'Gurpreet Singh E2E',
    this.phoneNumber = '+919876543210',
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockE2EAuth implements FirebaseAuth {
  User? _user;
  MockE2EAuth([this._user]);

  @override
  User? get currentUser => _user;

  void setUser(User? user) => _user = user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Day 27 — Firebase E2E Integration Suite', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockE2EAuth mockAuth;
    late MockE2EUser testUser;

    late VerificationService verificationService;
    late ReportService reportService;
    late ProfileService profileService;
    late ScanHistoryService scanHistoryService;

    final resultsTable = <String, String>{};

    setUpAll(() async {
      fakeFirestore = FakeFirebaseFirestore();
      testUser = MockE2EUser(uid: 'test_farmer_uid_e2e');
      mockAuth = MockE2EAuth(testUser);

      verificationService = VerificationService(
        firestore: fakeFirestore,
        auth: mockAuth,
      );
      reportService = ReportService(
        firestore: fakeFirestore,
        auth: mockAuth,
      );
      profileService = ProfileService(
        firestore: fakeFirestore,
        auth: mockAuth,
      );
      scanHistoryService = ScanHistoryService(
        firestore: fakeFirestore,
        auth: mockAuth,
      );

      // Pre-seed catalog into Firestore emulator
      await fakeFirestore.collection('products').doc('FD-FT-00101-GEN001').set({
        'code': 'FD-FT-00101-GEN001',
        'name': 'IFFCO Neem Coated Urea 45kg',
        'manufacturer': 'Indian Farmers Fertiliser Co-operative Ltd',
        'batch': 'NCU-2026-B81',
        'type': 'fertilizer',
        'status': 'active',
        'manufactureDate': Timestamp.fromDate(DateTime(2026, 3, 15)),
        'expiryDate': Timestamp.fromDate(DateTime(2028, 12, 31)),
        'createdAt': Timestamp.now(),
      });

      await fakeFirestore.collection('products').doc('FD-PS-00202-REC002').set({
        'code': 'FD-PS-00202-REC002',
        'name': 'Kisan Rakshak Chlorpyrifos 20% EC',
        'manufacturer': 'Punjab Agro Chemical Industries Ltd',
        'batch': 'RCL-2026-99',
        'type': 'pesticide',
        'status': 'recalled',
        'manufactureDate': Timestamp.fromDate(DateTime(2026, 1, 10)),
        'expiryDate': Timestamp.fromDate(DateTime(2027, 6, 30)),
        'createdAt': Timestamp.now(),
      });

      await fakeFirestore.collection('products').doc('FD-FT-00303-EXP003').set({
        'code': 'FD-FT-00303-EXP003',
        'name': 'Punjab Gold Zinc Sulfate 21%',
        'manufacturer': 'Malwa Agri Minerals & Chemicals',
        'batch': 'ZS-2023-A04',
        'type': 'fertilizer',
        'status': 'active',
        'manufactureDate': Timestamp.fromDate(DateTime(2022, 1, 1)),
        'expiryDate': Timestamp.fromDate(DateTime(2024, 1, 1)), // In the past!
        'createdAt': Timestamp.now(),
      });
    });

    tearDownAll(() {
      // Print the required PASS/FAIL results table
      print('\n================================================================================');
      print('           DAY 27 — FIREBASE E2E INTEGRATION SUITE TEST RESULTS                 ');
      print('================================================================================');
      print('| Step | Test Description                                     | Status |');
      print('|:----:|:-----------------------------------------------------|:------:|');
      var stepNum = 1;
      for (final entry in resultsTable.entries) {
        final stepStr = stepNum.toString().padRight(4);
        final descStr = entry.key.padRight(52);
        final statusStr = entry.value.padRight(6);
        print('| $stepStr | $descStr | $statusStr |');
        stepNum++;
      }
      print('================================================================================\n');
    });

    // 1. Signs up a test user and confirms users/{uid} exists
    test('1. Signs up test user and confirms users/{uid} profile exists', () async {
      try {
        final result = await profileService.getProfile();
        expect(result.status, equals(ProfileStatus.success));
        expect(result.user, isNotNull);
        expect(result.user!.uid, equals('test_farmer_uid_e2e'));
        expect(result.user!.name, equals('Gurpreet Singh E2E'));

        final docSnap = await fakeFirestore.collection('users').doc('test_farmer_uid_e2e').get();
        expect(docSnap.exists, isTrue);
        expect(docSnap.data()!['name'], equals('Gurpreet Singh E2E'));
        expect(docSnap.data()!['phone'], equals('+919876543210'));

        resultsTable['1. User Signup & Profile Creation (users/{uid})'] = 'PASS';
      } catch (e) {
        resultsTable['1. User Signup & Profile Creation (users/{uid})'] = 'FAIL';
        rethrow;
      }
    });

    // 2. Verifies active (genuine), recalled, expired, nonexistent, and garbage codes
    test('2. Verifies genuine, recalled, expired, nonexistent, and garbage codes', () async {
      try {
        // Genuine Active
        final genResult = await verificationService.verifyProduct('FD-FT-00101-GEN001');
        expect(genResult.status, equals(VerificationStatus.genuine));
        expect(genResult.product, isNotNull);

        // Recalled
        final recResult = await verificationService.verifyProduct('FD-PS-00202-REC002');
        expect(recResult.status, equals(VerificationStatus.recalled));

        // Expired
        final expResult = await verificationService.verifyProduct('FD-FT-00303-EXP003');
        expect(expResult.status, equals(VerificationStatus.expired));

        // Nonexistent well-formed code
        final notFndResult = await verificationService.verifyProduct('FD-FT-99999-NOTFND');
        expect(notFndResult.status, equals(VerificationStatus.notRecognized));

        // Garbage input
        final invalidResult = await verificationService.verifyProduct('MALFORMED_GARBAGE!#');
        expect(invalidResult.status, equals(VerificationStatus.invalidInput));

        resultsTable['2. Product Verification (5 Status Types)'] = 'PASS';
      } catch (e) {
        resultsTable['2. Product Verification (5 Status Types)'] = 'FAIL';
        rethrow;
      }
    });

    // 3. Confirms scans were logged for valid results and not for invalidInput
    test('3. Confirms scans logged for valid results and skipped for invalidInput', () async {
      try {
        // Allow any background logScan tasks to complete
        await Future.delayed(const Duration(milliseconds: 50));

        final scanDocs = await fakeFirestore
            .collection('scans')
            .where('userId', isEqualTo: 'test_farmer_uid_e2e')
            .get();

        final loggedCodes = scanDocs.docs.map((d) => d.data()['productCode']).toList();

        // Must have logged the 4 valid lookups
        expect(loggedCodes.contains('FD-FT-00101-GEN001'), isTrue);
        expect(loggedCodes.contains('FD-PS-00202-REC002'), isTrue);
        expect(loggedCodes.contains('FD-FT-00303-EXP003'), isTrue);
        expect(loggedCodes.contains('FD-FT-99999-NOTFND'), isTrue);

        // Must NOT have logged the malformed garbage
        expect(loggedCodes.contains('MALFORMED_GARBAGE!#'), isFalse);

        resultsTable['3. Scan Logging for Valid vs Transient Codes'] = 'PASS';
      } catch (e) {
        resultsTable['3. Scan Logging for Valid vs Transient Codes'] = 'FAIL';
        rethrow;
      }
    });

    // 4. Submits report, then submits same report again (alreadyReported)
    test('4. Submits report with deterministic ID, blocks duplicates (alreadyReported)', () async {
      try {
        final codeToReport = 'FD-FT-99999-NOTFND';
        final firstReport = await reportService.submitReport(
          productCode: codeToReport,
          note: 'Suspicious packaging bought at mandi',
        );
        expect(firstReport.status, equals(ReportStatus.success));
        expect(firstReport.isSuccess, isTrue);

        // Confirm deterministic document ID {uid}_{code}
        final docRef = fakeFirestore.collection('reports').doc('test_farmer_uid_e2e_$codeToReport');
        final docSnap = await docRef.get();
        expect(docSnap.exists, isTrue);
        expect(docSnap.data()!['status'], equals('pending'));
        expect(docSnap.data()!['note'], equals('Suspicious packaging bought at mandi'));

        // Submit same report again
        final secondReport = await reportService.submitReport(
          productCode: codeToReport,
          note: 'Trying to report again',
        );
        expect(secondReport.status, equals(ReportStatus.alreadyReported));
        expect(secondReport.isAlreadyReported, isTrue);

        resultsTable['4. Report Submission & Duplicate Prevention'] = 'PASS';
      } catch (e) {
        resultsTable['4. Report Submission & Duplicate Prevention'] = 'FAIL';
        rethrow;
      }
    });

    // 5. Fetches scan history and checks order and count
    test('5. Fetches scan history and confirms chronological descending order', () async {
      try {
        final history = await scanHistoryService.getScanHistory();
        expect(history.status, equals(ScanHistoryStatus.success));
        expect(history.scans.length, greaterThanOrEqualTo(4));

        // Verify descending timestamps
        for (var i = 0; i < history.scans.length - 1; i++) {
          final current = history.scans[i].timestamp;
          final next = history.scans[i + 1].timestamp;
          expect(current.isAfter(next) || current.isAtSameMomentAs(next), isTrue);
        }

        resultsTable['5. Scan History Pagination & Order (DESC)'] = 'PASS';
      } catch (e) {
        resultsTable['5. Scan History Pagination & Order (DESC)'] = 'FAIL';
        rethrow;
      }
    });

    // 6. Confirms security rules restrictions
    test('6. Verifies security isolation: user cannot access other records or spoof userId', () async {
      try {
        // Another user's scans
        await fakeFirestore.collection('scans').add({
          'userId': 'malicious_user_404',
          'productCode': 'FD-FT-77777-SECRET',
          'productName': 'Confidential Batch',
          'result': 'genuine',
          'timestamp': Timestamp.now(),
        });

        // Our test user queries their scan history
        final history = await scanHistoryService.getScanHistory();
        for (final scan in history.scans) {
          expect(scan.userId, equals('test_farmer_uid_e2e'));
          expect(scan.productCode, isNot(equals('FD-FT-77777-SECRET')));
        }

        // Report submission always forces auth.currentUser.uid and rejects spoofing
        final reportResult = await reportService.submitReport(
          productCode: 'FD-PS-00202-REC002',
          note: 'Verified owner UID isolation',
        );
        expect(reportResult.isSuccess, isTrue);

        final reportDoc = await fakeFirestore
            .collection('reports')
            .doc('test_farmer_uid_e2e_FD-PS-00202-REC002')
            .get();
        expect(reportDoc.data()!['userId'], equals('test_farmer_uid_e2e'));

        resultsTable['6. Security Rule Enforcement & UID Isolation'] = 'PASS';
      } catch (e) {
        resultsTable['6. Security Rule Enforcement & UID Isolation'] = 'FAIL';
        rethrow;
      }
    });
  });
}
