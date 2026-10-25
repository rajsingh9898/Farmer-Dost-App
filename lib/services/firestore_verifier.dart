import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Day 16 — Temporary Firestore Verification Script
/// Runs click-by-click confirmation of Firestore collection structure,
/// point lookups, non-existent document handling, and composite indexed queries.
Future<bool> runDay16FirestoreVerification({
  FirebaseFirestore? firestore,
  String testProductId = 'FD-PB-00123-A7X9',
  String nonExistentId = 'NON-EXISTENT-CODE-999',
  String testUserId = 'usr_punjab_farmer_01',
}) async {
  FirebaseFirestore db;
  try {
    db = firestore ?? FirebaseFirestore.instance;
  } catch (e) {
    debugPrint('❌ [FAIL] Firebase is not initialized or offline: $e');
    return false;
  }

  debugPrint('\n======================================================');
  debugPrint('🚀 RUNNING DAY 16 FIRESTORE STRUCTURE VERIFICATION');
  debugPrint('======================================================');

  bool check1Passed = false;
  bool check2Passed = false;
  bool check3Passed = false;

  // -----------------------------------------------------------------
  // CHECK 1: Fetch product document by ID and print its fields
  // -----------------------------------------------------------------
  debugPrint('\n--- [CHECK 1] Direct Product Lookup by Document ID ---');
  try {
    final docSnapshot = await db.collection('products').doc(testProductId).get();
    if (docSnapshot.exists && docSnapshot.data() != null) {
      final data = docSnapshot.data()!;
      debugPrint('Found Product: ${docSnapshot.id}');
      data.forEach((key, value) {
        debugPrint('   • $key (${value.runtimeType}): $value');
      });
      debugPrint('✅ [PASS] Check 1: Product document "$testProductId" fetched successfully.');
      check1Passed = true;
    } else {
      debugPrint('❌ [FAIL] Check 1: Product document "$testProductId" does not exist in /products.');
      debugPrint('   Tip: Add document with ID "$testProductId" in the Firebase Console.');
    }
  } catch (e) {
    debugPrint('❌ [FAIL] Check 1 Error: $e');
  }

  // -----------------------------------------------------------------
  // CHECK 2: Fetch product ID that does NOT exist (verifies "fake" detection)
  // -----------------------------------------------------------------
  debugPrint('\n--- [CHECK 2] Non-Existent Product ID (Fake Detection) ---');
  try {
    final fakeSnapshot = await db.collection('products').doc(nonExistentId).get();
    if (!fakeSnapshot.exists) {
      debugPrint('Target ID: "$nonExistentId" -> exists == false');
      debugPrint('✅ [PASS] Check 2: Non-existent product ID correctly returned exists == false.');
      check2Passed = true;
    } else {
      debugPrint('❌ [FAIL] Check 2: Document "$nonExistentId" surprisingly exists!');
    }
  } catch (e) {
    debugPrint('❌ [FAIL] Check 2 Error: $e');
  }

  // -----------------------------------------------------------------
  // CHECK 3: Query scans for test user ordered by timestamp descending
  // -----------------------------------------------------------------
  debugPrint('\n--- [CHECK 3] User Scan History Query (Indexed) ---');
  try {
    final scansSnapshot = await db
        .collection('scans')
        .where('userId', isEqualTo: testUserId)
        .orderBy('timestamp', descending: true)
        .get();

    debugPrint('Found ${scansSnapshot.docs.length} scan records for user: $testUserId');
    for (int i = 0; i < scansSnapshot.docs.length; i++) {
      final doc = scansSnapshot.docs[i];
      final data = doc.data();
      debugPrint('   [Scan ${i + 1}] ID: ${doc.id}');
      debugPrint('      Code: ${data['productCode']} | Result: ${data['result']} | Name: ${data['productName']}');
      debugPrint('      Timestamp: ${data['timestamp']}');
    }

    if (scansSnapshot.docs.isNotEmpty) {
      debugPrint('✅ [PASS] Check 3: Scans query executed and returned ${scansSnapshot.docs.length} record(s).');
      check3Passed = true;
    } else {
      debugPrint('⚠️ [PASS/NOTICE] Check 3: Query succeeded without error, but 0 scans found for "$testUserId".');
      debugPrint('   Tip: Add test documents in "scans" with field userId: "$testUserId".');
      check3Passed = true;
    }
  } on FirebaseException catch (fe) {
    debugPrint('❌ [FAIL] Check 3 FirebaseException [${fe.code}]: ${fe.message}');
    if (fe.message != null && fe.message!.contains('index')) {
      debugPrint('\n🚨 COMPOSITE INDEX REQUIRED:');
      debugPrint('Firestore requires an index for compound queries (where + orderBy).');
      debugPrint('Click the URL in the error message above to auto-create this composite index in Firebase Console:');
      debugPrint('Collection: scans | Fields: userId (ASCENDING), timestamp (DESCENDING)\n');
    }
  } catch (e) {
    debugPrint('❌ [FAIL] Check 3 Unexpected Error: $e');
  }

  // -----------------------------------------------------------------
  // FINAL SUMMARY
  // -----------------------------------------------------------------
  final allPassed = check1Passed && check2Passed && check3Passed;
  debugPrint('\n======================================================');
  debugPrint('📊 DAY 16 VERIFICATION SUMMARY: ${allPassed ? "ALL PASSED ✅" : "ATTENTION NEEDED ⚠️"}');
  debugPrint('------------------------------------------------------');
  debugPrint('Check 1 (Product ID Direct Lookup): ${check1Passed ? "PASS ✅" : "FAIL ❌"}');
  debugPrint('Check 2 (Fake / Exists == False):   ${check2Passed ? "PASS ✅" : "FAIL ❌"}');
  debugPrint('Check 3 (Scan History Composite):   ${check3Passed ? "PASS ✅" : "FAIL ❌"}');
  debugPrint('======================================================\n');

  return allPassed;
}
