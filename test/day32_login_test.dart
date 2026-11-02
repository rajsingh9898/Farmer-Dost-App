import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:farmer_dost_app/theme/app_theme.dart';
import 'package:farmer_dost_app/routes/app_routes.dart';
import 'package:farmer_dost_app/screens/login_screen.dart';
import 'package:farmer_dost_app/services/auth_service.dart';
import 'package:farmer_dost_app/l10n/app_strings.dart';

void main() {
  group('Day 32 — AuthService Error Mapping & Reset Password Tests', () {
    test('maps Firebase Auth error codes to farmer-friendly strings', () {
      final authService = AuthService();

      expect(
        authService.getFriendlyErrorMessage(
          FirebaseAuthException(code: 'user-not-found'),
        ),
        equals('No account found with this email. Please sign up.'),
      );

      expect(
        authService.getFriendlyErrorMessage(
          FirebaseAuthException(code: 'wrong-password'),
        ),
        equals('Incorrect password. Please try again.'),
      );

      expect(
        authService.getFriendlyErrorMessage(
          FirebaseAuthException(code: 'email-already-in-use'),
        ),
        equals('An account already exists with this email. Please log in.'),
      );

      expect(
        authService.getFriendlyErrorMessage(
          FirebaseAuthException(code: 'weak-password'),
        ),
        equals('Password is too weak. Please use at least 6 characters.'),
      );

      expect(
        authService.getFriendlyErrorMessage(
          FirebaseAuthException(code: 'network-request-failed'),
        ),
        equals('No internet connection. Please check your mobile data or Wi-Fi.'),
      );
    });

    test('sendPasswordResetEmail rejects empty email before calling network', () async {
      final authService = AuthService();
      expect(
        () => authService.sendPasswordResetEmail(''),
        throwsA(isA<FirebaseAuthException>()),
      );
    });
  });

  group('Day 32 — LoginScreen UI & Validation Tests', () {
    testWidgets('renders initial Login mode without Name field', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: const LoginScreen(),
        ),
      );

      // Verify Screen Title
      expect(find.text(AppStrings.loginTitle), findsOneWidget);

      // Verify Email and Password fields are present
      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);

      // Name field should NOT be present in Login mode
      expect(find.byKey(const Key('name_field')), findsNothing);

      // Forgot Password should be visible in Login mode
      expect(find.byKey(const Key('forgot_password_button')), findsOneWidget);

      // Submit button should read "Sign In"
      expect(find.text(AppStrings.signIn), findsOneWidget);
    });

    testWidgets('toggling to Sign Up mode reveals Name field and updates button text', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: const LoginScreen(),
        ),
      );

      // Tap toggle to switch to Sign Up mode
      await tester.tap(find.byKey(const Key('mode_toggle_button')));
      await tester.pumpAndSettle();

      // Verify Sign Up Title and Name field are visible
      expect(find.text(AppStrings.signUpTitle), findsOneWidget);
      expect(find.byKey(const Key('name_field')), findsOneWidget);

      // Submit button should read "Create Account"
      expect(find.text(AppStrings.signUp), findsOneWidget);

      // Forgot Password should be hidden in Sign Up mode
      expect(find.byKey(const Key('forgot_password_button')), findsNothing);
    });

    testWidgets('inline validation triggers on empty and invalid inputs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: const LoginScreen(),
        ),
      );

      // Tap Sign In with empty fields
      await tester.tap(find.byKey(const Key('auth_submit_button')));
      await tester.pumpAndSettle();

      // Verify inline validation errors appear
      expect(find.text(AppStrings.emailRequired), findsOneWidget);
      expect(find.text(AppStrings.passwordRequired), findsOneWidget);

      // Enter invalid email format
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'invalid-email-no-domain',
      );
      // Enter short password
      await tester.enterText(
        find.byKey(const Key('password_field')),
        '123',
      );

      await tester.tap(find.byKey(const Key('auth_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.emailInvalid), findsOneWidget);
      expect(find.text(AppStrings.passwordTooShort), findsOneWidget);
    });

    testWidgets('show/hide password toggle changes obscureText', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: const LoginScreen(),
        ),
      );

      // Initial password field is obscured
      final editableFinder = find.descendant(
        of: find.byKey(const Key('password_field')),
        matching: find.byType(EditableText),
      );
      expect(tester.widget<EditableText>(editableFinder).obscureText, isTrue);

      // Tap eye icon to show password
      await tester.tap(find.byKey(const Key('password_visibility_button')));
      await tester.pumpAndSettle();

      // Password field is now not obscured
      expect(tester.widget<EditableText>(editableFinder).obscureText, isFalse);
    });

    testWidgets('tapping Forgot Password opens reset dialog with pre-filled email', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: const LoginScreen(),
        ),
      );

      // Enter email in login field
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'farmer@punjab.in',
      );

      // Tap Forgot Password
      await tester.tap(find.byKey(const Key('forgot_password_button')));
      await tester.pumpAndSettle();

      // Verify Dialog appears
      expect(find.text(AppStrings.passwordResetDialogTitle), findsOneWidget);
      expect(find.text(AppStrings.sendResetLink), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('farmer@punjab.in'),
        ),
        findsOneWidget,
      );

      // Dismiss dialog
      await tester.tap(find.text(AppStrings.cancel));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.passwordResetDialogTitle), findsNothing);
    });

    testWidgets('LoginScreen survives 1.3x font scaling without layout overflow', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: const LoginScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to sign up mode with extra name field
      await tester.tap(find.byKey(const Key('mode_toggle_button')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.signUpTitle), findsOneWidget);
      expect(find.byKey(const Key('name_field')), findsOneWidget);
    });
  });
}
