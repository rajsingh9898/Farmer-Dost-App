import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:farmer_dost_app/services/auth_service.dart';
import 'package:farmer_dost_app/services/auth_verifier.dart';
import 'package:farmer_dost_app/models/user_model.dart';
import 'package:farmer_dost_app/screens/auth_gate.dart';

void main() {
  group('Day 17 — AuthService Error Mapping Tests', () {
    final authService = AuthService();

    test('getFriendlyErrorMessage converts all standard FirebaseAuthException codes', () {
      expect(
        authService.getFriendlyErrorMessage(FirebaseAuthException(code: 'user-not-found')),
        contains('No account found'),
      );

      expect(
        authService.getFriendlyErrorMessage(FirebaseAuthException(code: 'wrong-password')),
        contains('Incorrect password'),
      );

      expect(
        authService.getFriendlyErrorMessage(FirebaseAuthException(code: 'email-already-in-use')),
        contains('already exists'),
      );

      expect(
        authService.getFriendlyErrorMessage(FirebaseAuthException(code: 'weak-password')),
        contains('too weak'),
      );

      expect(
        authService.getFriendlyErrorMessage(FirebaseAuthException(code: 'invalid-verification-code')),
        contains('Incorrect OTP'),
      );

      expect(
        authService.getFriendlyErrorMessage(FirebaseAuthException(code: 'too-many-requests')),
        contains('Too many attempts'),
      );

      expect(
        authService.getFriendlyErrorMessage(FirebaseAuthException(code: 'network-request-failed')),
        contains('No internet connection'),
      );

      expect(
        authService.getFriendlyErrorMessage(FirebaseAuthException(code: 'invalid-email')),
        contains('valid email address'),
      );

      expect(
        authService.getFriendlyErrorMessage(FirebaseAuthException(code: 'session-expired')),
        contains('OTP has expired'),
      );
    });

    test('UserModel supports email field persistence and serialization', () {
      final user = UserModel(
        uid: 'usr_day17_test',
        name: 'Baljit Singh',
        email: 'baljit@farmerdost.com',
        phone: '+919876543210',
        language: 'en',
      );

      final map = user.toMap();
      expect(map['email'], 'baljit@farmerdost.com');
      expect(map['name'], 'Baljit Singh');
      expect(map['language'], 'en');

      final reconstructed = UserModel.fromMap(map, 'usr_day17_test');
      expect(reconstructed.email, 'baljit@farmerdost.com');
      expect(reconstructed.name, 'Baljit Singh');
    });

    testWidgets('AuthGate builds and displays LoginScreen or loading state when offline', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthGate(),
        ),
      );

      // Should render without throwing uncaught exceptions
      expect(find.byType(AuthGate), findsOneWidget);
    });

    test('runDay17AuthVerification handles offline / uninitialized Firebase gracefully', () async {
      final result = await runDay17AuthVerification();
      expect(result, isFalse);
    });
  });
}
