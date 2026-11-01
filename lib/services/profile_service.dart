import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'service_helper.dart';

/// Status outcomes for profile operations.
enum ProfileStatus {
  success,
  notSignedIn,
  userNotFound,
  networkError,
  permissionDenied,
  error,
}

/// Structured, non-throwing result returned by [ProfileService].
class ProfileResult {
  final ProfileStatus status;
  final UserModel? user;
  final String? message;

  const ProfileResult({
    required this.status,
    this.user,
    this.message,
  });

  bool get isSuccess => status == ProfileStatus.success;

  factory ProfileResult.success(UserModel user) => ProfileResult(
        status: ProfileStatus.success,
        user: user,
      );

  factory ProfileResult.notSignedIn([String? message]) => ProfileResult(
        status: ProfileStatus.notSignedIn,
        message: message ?? 'You must be signed in to access profile information.',
      );

  factory ProfileResult.userNotFound([String? message]) => ProfileResult(
        status: ProfileStatus.userNotFound,
        message: message ?? 'User profile does not exist.',
      );

  factory ProfileResult.networkError([String? message]) => ProfileResult(
        status: ProfileStatus.networkError,
        message: message ?? 'Unable to connect to server. Please check internet connection.',
      );

  factory ProfileResult.permissionDenied([String? message]) => ProfileResult(
        status: ProfileStatus.permissionDenied,
        message: message ?? 'Access denied by security rules.',
      );

  factory ProfileResult.error(String message) => ProfileResult(
        status: ProfileStatus.error,
        message: message,
      );

  @override
  String toString() => 'ProfileResult(status: $status, user: ${user?.name}, message: $message)';
}

/// Service managing farmer profile data in Firestore `users/{uid}`.
class ProfileService {
  final FirebaseFirestore? _firestoreOverride;
  final FirebaseAuth? _authOverride;
  final Duration timeoutDuration;

  ProfileService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    this.timeoutDuration = kDefaultServiceTimeout,
  })  : _firestoreOverride = firestore,
        _authOverride = auth;

  FirebaseFirestore get _firestore {
    if (_firestoreOverride != null) return _firestoreOverride!;
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('[ProfileService] FirebaseFirestore.instance unavailable: $e');
      rethrow;
    }
  }

  FirebaseAuth? get _auth {
    if (_authOverride != null) return _authOverride;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  /// Fetches a user profile by [uid], or defaults to the currently authenticated user.
  /// If [createIfMissing] is true and no document exists in `users/{uid}`, creates a
  /// default profile document with valid schema and server timestamp.
  Future<ProfileResult> getProfile({
    String? uid,
    bool createIfMissing = true,
  }) async {
    final effectiveUid = uid ?? _auth?.currentUser?.uid;
    if (effectiveUid == null || effectiveUid.trim().isEmpty) {
      return ProfileResult.notSignedIn();
    }

    try {
      final docRef = _firestore.collection('users').doc(effectiveUid);
      final docSnap = await docRef.get().timeout(timeoutDuration);

      if (docSnap.exists && docSnap.data() != null) {
        final user = UserModel.fromMap(docSnap.data()!, docSnap.id);
        return ProfileResult.success(user);
      }

      if (!createIfMissing) {
        return ProfileResult.userNotFound();
      }

      // Auto-create profile if missing
      final currentUser = _auth?.currentUser;
      final defaultName = (currentUser?.displayName != null && currentUser!.displayName!.isNotEmpty)
          ? currentUser.displayName!
          : 'Kisan Dost';
      final defaultPhone = currentUser?.phoneNumber ?? '';
      final defaultEmail = currentUser?.email;

      final initialData = <String, dynamic>{
        'name': defaultName,
        'phone': defaultPhone,
        'language': 'en',
        'createdAt': FieldValue.serverTimestamp(),
      };
      if (defaultEmail != null && defaultEmail.isNotEmpty) {
        initialData['email'] = defaultEmail;
      }

      await docRef.set(initialData).timeout(timeoutDuration);

      final newUser = UserModel(
        uid: effectiveUid,
        name: defaultName,
        phone: defaultPhone,
        email: defaultEmail,
        language: 'en',
        createdAt: DateTime.now(),
      );

      debugPrint('[ProfileService] Auto-created user profile for $effectiveUid');
      return ProfileResult.success(newUser);
    } on TimeoutException {
      return ProfileResult.networkError('Profile request timed out after ${timeoutDuration.inSeconds}s.');
    } catch (e) {
      debugPrint('[ProfileService] getProfile error: $e');
      if (ServiceHelper.isPermissionDenied(e)) {
        return ProfileResult.permissionDenied();
      }
      if (ServiceHelper.isNetworkError(e)) {
        return ProfileResult.networkError(ServiceHelper.mapErrorToUserMessage(e));
      }
      return ProfileResult.error(ServiceHelper.mapErrorToUserMessage(e));
    }
  }

  /// Updates profile fields for the authenticated user without modifying `createdAt`.
  Future<ProfileResult> updateProfile({
    String? name,
    String? phone,
    String? language,
    String? district,
    String? email,
  }) async {
    final effectiveUid = _auth?.currentUser?.uid;
    if (effectiveUid == null || effectiveUid.trim().isEmpty) {
      return ProfileResult.notSignedIn();
    }

    try {
      final docRef = _firestore.collection('users').doc(effectiveUid);
      final updateData = <String, dynamic>{};

      if (name != null) updateData['name'] = name.trim();
      if (phone != null) updateData['phone'] = phone.trim();
      if (language != null) updateData['language'] = language.trim();
      if (district != null) updateData['district'] = district.trim();
      if (email != null) updateData['email'] = email.trim();

      if (updateData.isEmpty) {
        return await getProfile(uid: effectiveUid, createIfMissing: false);
      }

      // Explicitly protect createdAt from modification
      await docRef.update(updateData).timeout(timeoutDuration);

      // Re-fetch updated profile
      final updatedSnap = await docRef.get().timeout(timeoutDuration);
      if (updatedSnap.exists && updatedSnap.data() != null) {
        return ProfileResult.success(UserModel.fromMap(updatedSnap.data()!, updatedSnap.id));
      }
      return ProfileResult.userNotFound();
    } on TimeoutException {
      return ProfileResult.networkError('Profile update timed out.');
    } catch (e) {
      debugPrint('[ProfileService] updateProfile error: $e');
      if (ServiceHelper.isPermissionDenied(e)) {
        return ProfileResult.permissionDenied();
      }
      if (ServiceHelper.isNetworkError(e)) {
        return ProfileResult.networkError(ServiceHelper.mapErrorToUserMessage(e));
      }
      return ProfileResult.error(ServiceHelper.mapErrorToUserMessage(e));
    }
  }
}
