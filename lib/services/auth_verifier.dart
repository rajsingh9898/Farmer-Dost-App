import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

/// Day 17 — Temporary Authentication Verification Script
/// Performs end-to-end verification of Email Authentication,
/// Firestore user document persistence at users/{uid}, and clean Sign Out.
Future<bool> runDay17AuthVerification({
  String testEmail = 'testfarmer@farmerdost.com',
  String testPassword = 'Password123!',
  FirebaseAuth? authInstance,
  FirebaseFirestore? firestoreInstance,
}) async {
  debugPrint('\n======================================================');
  debugPrint('🚀 RUNNING DAY 17 FIREBASE AUTH VERIFICATION');
  debugPrint('======================================================');

  FirebaseAuth auth;
  FirebaseFirestore db;

  try {
    auth = authInstance ?? FirebaseAuth.instance;
    db = firestoreInstance ?? FirebaseFirestore.instance;
  } catch (e) {
    debugPrint('❌ [FAIL] Firebase is not initialized or offline: $e');
    return false;
  }

  bool step1Passed = false;
  bool step2Passed = false;
  bool step3Passed = false;

  // -----------------------------------------------------------------
  // STEP 1: Sign in with test account (or create it if first run)
  // -----------------------------------------------------------------
  debugPrint('\n--- [STEP 1] Sign In with Test Account ($testEmail) ---');
  User? user;
  try {
    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: testEmail.trim(),
        password: testPassword,
      );
      user = credential.user;
      debugPrint('Signed in successfully! UID: ${user?.uid}');
    } on FirebaseAuthException catch (fe) {
      if (fe.code == 'user-not-found' || fe.code == 'invalid-credential') {
        debugPrint('Account not found. Attempting to create test account...');
        final cred = await auth.createUserWithEmailAndPassword(
          email: testEmail.trim(),
          password: testPassword,
        );
        user = cred.user;
        debugPrint('Created test account! UID: ${user?.uid}');
      } else {
        rethrow;
      }
    }

    if (user != null && user.uid.isNotEmpty) {
      debugPrint('✅ [PASS] Step 1: Signed in with UID: ${user.uid}');
      step1Passed = true;
    } else {
      debugPrint('❌ [FAIL] Step 1: User signed in but UID was empty.');
    }
  } catch (e) {
    debugPrint('❌ [FAIL] Step 1 Error: ${AuthService().getFriendlyErrorMessage(e)} ($e)');
  }

  // -----------------------------------------------------------------
  // STEP 2: Read users/{uid} document from Cloud Firestore
  // -----------------------------------------------------------------
  if (user != null) {
    debugPrint('\n--- [STEP 2] Check Firestore users/${user.uid} Document ---');
    try {
      final docSnapshot = await db.collection('users').doc(user.uid).get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        debugPrint('User Document Found: ${docSnapshot.id}');
        data.forEach((k, v) => debugPrint('   • $k: $v'));
        debugPrint('✅ [PASS] Step 2: Document users/${user.uid} exists in Cloud Firestore.');
        step2Passed = true;
      } else {
        debugPrint('❌ [FAIL] Step 2: Document users/${user.uid} does NOT exist in Firestore.');
        debugPrint('   Auto-healing: Creating document now to ensure profile integrity...');
        await db.collection('users').doc(user.uid).set({
          'name': user.displayName ?? 'Gurpreet Singh (Test Farmer)',
          'email': user.email,
          'phone': user.phoneNumber ?? '+919876543210',
          'language': 'en',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('   Profile document healed.');
      }
    } catch (e) {
      debugPrint('❌ [FAIL] Step 2 Error checking Firestore: $e');
    }
  }

  // -----------------------------------------------------------------
  // STEP 3: Sign out and confirm currentUser is null
  // -----------------------------------------------------------------
  debugPrint('\n--- [STEP 3] Sign Out & Confirm CurrentUser is null ---');
  try {
    await auth.signOut();
    final remainingUser = auth.currentUser;

    if (remainingUser == null) {
      debugPrint('Auth state confirmed: currentUser is null.');
      debugPrint('✅ [PASS] Step 3: Signed out successfully.');
      step3Passed = true;
    } else {
      debugPrint('❌ [FAIL] Step 3: Expected currentUser to be null, but was: ${remainingUser.uid}');
    }
  } catch (e) {
    debugPrint('❌ [FAIL] Step 3 Error: $e');
  }

  // -----------------------------------------------------------------
  // SUMMARY
  // -----------------------------------------------------------------
  final allPassed = step1Passed && step2Passed && step3Passed;
  debugPrint('\n======================================================');
  debugPrint('📊 DAY 17 AUTH VERIFICATION SUMMARY: ${allPassed ? "ALL PASSED ✅" : "ATTENTION NEEDED ⚠️"}');
  debugPrint('------------------------------------------------------');
  debugPrint('Step 1 (Sign In & Print UID):           ${step1Passed ? "PASS ✅" : "FAIL ❌"}');
  debugPrint('Step 2 (Read users/{uid} in Firestore): ${step2Passed ? "PASS ✅" : "FAIL ❌"}');
  debugPrint('Step 3 (Sign Out & Confirm Null):       ${step3Passed ? "PASS ✅" : "FAIL ❌"}');
  debugPrint('======================================================\n');

  return allPassed;
}
