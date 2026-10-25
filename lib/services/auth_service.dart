import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Day 17 — Production Authentication Service for Farmer Dost App.
/// Supports Email/Password registration & sign-in, Phone OTP verification,
/// automated user document synchronization in Firestore, and farmer-friendly error mapping.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  FirebaseAuth? _authInstance;
  FirebaseFirestore? _firestoreInstance;

  FirebaseAuth get auth {
    _authInstance ??= FirebaseAuth.instance;
    return _authInstance!;
  }

  FirebaseFirestore get _firestore {
    _firestoreInstance ??= FirebaseFirestore.instance;
    return _firestoreInstance!;
  }

  /// Auth state changes stream for reactive app root routing
  Stream<User?> get authStateChanges {
    try {
      return auth.authStateChanges();
    } catch (e) {
      debugPrint('Error getting authStateChanges: $e');
      return Stream.value(null);
    }
  }

  /// Currently logged-in Firebase user
  User? get currentUser {
    try {
      return auth.currentUser;
    } catch (e) {
      return null;
    }
  }

  /// Current user UID with safe demo fallback for offline inspection
  String get currentUserId {
    return currentUser?.uid ?? 'demo_farmer_123';
  }

  // =========================================================================
  // 1. EMAIL & PASSWORD AUTHENTICATION
  // =========================================================================

  /// signUpWithEmail(name, email, password)
  /// Creates a new Firebase Auth account, then creates a document at users/{uid}
  /// with: name, email, phone (nullable), language ("en"), createdAt (serverTimestamp).
  /// If Firestore write fails, handles it gracefully so user is not left half-registered.
  Future<UserCredential> signUpWithEmail(
    String name,
    String email,
    String password,
  ) async {
    final cleanEmail = email.trim();
    final cleanPass = password.trim();
    final cleanName = name.trim();

    try {
      // 1. Create account in Firebase Auth
      final credential = await auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPass,
      );

      final user = credential.user;
      if (user != null) {
        // Update user display name in Auth profile
        try {
          await user.updateDisplayName(cleanName);
        } catch (e) {
          debugPrint('Notice: Failed to update displayName in Auth: $e');
        }

        // 2. Create users/{uid} document in Cloud Firestore
        await _createUserDocument(
          uid: user.uid,
          name: cleanName,
          email: cleanEmail,
          phone: user.phoneNumber,
        );
      }

      return credential;
    } catch (e) {
      debugPrint('Error in signUpWithEmail: $e');
      rethrow;
    }
  }

  /// signInWithEmail(email, password)
  /// Signs in existing user and ensures their users/{uid} document exists.
  Future<UserCredential> signInWithEmail(
    String email,
    String password,
  ) async {
    final cleanEmail = email.trim();
    final cleanPass = password.trim();

    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPass,
      );

      // Ensure user profile document exists (heals any prior signup write failure)
      if (credential.user != null) {
        await _ensureUserDocumentExists(credential.user!);
      }

      return credential;
    } catch (e) {
      debugPrint('Error in signInWithEmail: $e');
      rethrow;
    }
  }

  // =========================================================================
  // 2. PHONE OTP FLOW (SEPARATE FROM EMAIL FUNCTIONS)
  // =========================================================================

  /// sendOtp(phoneNumber, onCodeSent, onError)
  /// Initiates SMS OTP delivery via verifyPhoneNumber.
  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String errorMessage) onError,
  }) async {
    final cleanPhone = phoneNumber.trim();

    try {
      await auth.verifyPhoneNumber(
        phoneNumber: cleanPhone.startsWith('+') ? cleanPhone : '+91$cleanPhone',
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Android instant auto-verification
          try {
            final userCredential = await auth.signInWithCredential(credential);
            if (userCredential.user != null) {
              await _ensureUserDocumentExists(userCredential.user!);
            }
          } catch (e) {
            onError(getFriendlyErrorMessage(e));
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('verifyPhoneNumber failed: ${e.code} - ${e.message}');
          onError(getFriendlyErrorMessage(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('SMS auto-retrieval timed out for: $verificationId');
        },
      );
    } catch (e) {
      onError(getFriendlyErrorMessage(e));
    }
  }

  /// verifyOtp(verificationId, smsCode)
  /// Verifies submitted SMS code and signs in.
  /// On first phone sign-in, creates the users/{uid} document if it doesn't exist.
  Future<UserCredential> verifyOtp(
    String verificationId,
    String smsCode,
  ) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );

      final userCredential = await auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        await _ensureUserDocumentExists(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      debugPrint('Error in verifyOtp: $e');
      rethrow;
    }
  }

  // =========================================================================
  // 3. FIRESTORE PROFILE SYNCHRONIZATION HELPERS
  // =========================================================================

  /// Creates a users/{uid} document with graceful error handling.
  Future<void> _createUserDocument({
    required String uid,
    required String name,
    String? email,
    String? phone,
  }) async {
    try {
      final docRef = _firestore.collection('users').doc(uid);
      await docRef.set({
        'name': name.isNotEmpty ? name : 'Farmer',
        'email': email,
        'phone': phone ?? '',
        'language': 'en',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 6));
    } catch (e) {
      // Graceful degradation: log warning so user account remains valid in Auth,
      // and it will be created automatically on next login.
      debugPrint('Warning: Initial Firestore user doc creation delayed: $e');
    }
  }

  /// Ensures users/{uid} exists, healing half-registered states from offline or interrupted signups.
  Future<void> _ensureUserDocumentExists(User user) async {
    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      final snapshot = await docRef.get().timeout(const Duration(seconds: 5));

      if (!snapshot.exists || snapshot.data() == null) {
        debugPrint('Healing user profile for UID: ${user.uid}');
        await docRef.set({
          'name': user.displayName?.isNotEmpty == true ? user.displayName! : 'Farmer',
          'email': user.email,
          'phone': user.phoneNumber ?? '',
          'language': 'en',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Notice: Unable to verify/heal user document in Firestore: $e');
    }
  }

  // =========================================================================
  // 4. SIGN OUT
  // =========================================================================

  /// signOut()
  /// Signs out of Firebase Auth.
  Future<void> signOut() async {
    try {
      await auth.signOut();
    } catch (e) {
      debugPrint('Error in signOut: $e');
    }
  }

  // =========================================================================
  // 5. FARMER-FRIENDLY ERROR TRANSLATION
  // =========================================================================

  /// Converts technical FirebaseAuthException codes into short, farmer-friendly strings.
  String getFriendlyErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return "No account found with this email. Please sign up.";
        case 'wrong-password':
          return "Incorrect password. Please try again.";
        case 'invalid-credential':
          return "Invalid email or password. Please check and try again.";
        case 'email-already-in-use':
          return "An account already exists with this email. Please log in.";
        case 'weak-password':
          return "Password is too weak. Please use at least 6 characters.";
        case 'invalid-email':
          return "Please enter a valid email address.";
        case 'invalid-verification-code':
          return "Incorrect OTP entered. Please check and try again.";
        case 'invalid-verification-id':
          return "OTP session expired. Please request a new code.";
        case 'session-expired':
          return "OTP has expired. Please request a new code.";
        case 'invalid-phone-number':
          return "Invalid phone number. Please enter a valid 10-digit mobile number.";
        case 'too-many-requests':
          return "Too many attempts. Please wait a few minutes and try again.";
        case 'network-request-failed':
          return "No internet connection. Please check your mobile data or Wi-Fi.";
        case 'operation-not-allowed':
          return "This sign-in method is not enabled. Please contact support.";
        case 'user-disabled':
          return "This account has been disabled. Please contact support.";
        default:
          return error.message?.isNotEmpty == true
              ? error.message!
              : "Authentication failed. Please try again.";
      }
    }

    if (error != null) {
      final str = error.toString();
      if (str.contains('network') || str.contains('connection') || str.contains('SocketException')) {
        return "No internet connection. Please check your network.";
      }
      return str.replaceAll('Exception:', '').trim();
    }

    return "An unexpected error occurred. Please try again.";
  }
}
