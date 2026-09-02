import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  FirebaseAuth? _auth;

  FirebaseAuth get auth {
    try {
      _auth ??= FirebaseAuth.instance;
      return _auth!;
    } catch (e) {
      debugPrint('FirebaseAuth.instance exception: $e');
      rethrow;
    }
  }

  Stream<User?> get authStateChanges {
    try {
      return auth.authStateChanges();
    } catch (e) {
      debugPrint('Error getting authStateChanges: $e');
      return Stream.value(null);
    }
  }

  User? get currentUser {
    try {
      return auth.currentUser;
    } catch (e) {
      return null;
    }
  }

  String get currentUserId {
    return currentUser?.uid ?? 'demo_farmer_123';
  }

  Future<UserCredential?> signInWithEmailPassword(
      String email, String password) async {
    try {
      return await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Error in signInWithEmailPassword: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signUpWithEmailPassword(
      String email, String password) async {
    try {
      return await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Error in signUpWithEmailPassword: $e');
      rethrow;
    }
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    try {
      await auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      );
    } catch (e) {
      debugPrint('Error in verifyPhoneNumber: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signInWithOTP(
      String verificationId, String smsCode) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return await auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Error in signInWithOTP: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await auth.signOut();
    } catch (e) {
      debugPrint('Error in signOut: $e');
    }
  }
}
