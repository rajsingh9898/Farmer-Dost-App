import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmer_dost_app/screens/profile_screen.dart';
import 'package:farmer_dost_app/services/profile_service.dart';
import 'package:farmer_dost_app/models/user_model.dart';
import 'package:farmer_dost_app/routes/app_routes.dart';
import 'package:farmer_dost_app/theme/app_theme.dart';
import 'package:farmer_dost_app/l10n/app_strings.dart';

class MockProfileService extends ProfileService {
  ProfileResult? stubbedResult;
  int fetchCallCount = 0;

  @override
  Future<ProfileResult> getProfile({
    String? uid,
    bool createIfMissing = true,
  }) async {
    fetchCallCount++;
    return stubbedResult ??
        ProfileResult.success(
          UserModel(
            uid: uid ?? 'test-uid-123',
            name: 'Gurpreet Singh',
            email: 'gurpreet@punjab.in',
            phone: '+91 98765 43210',
            language: 'pa',
            createdAt: DateTime.now(),
          ),
        );
  }
}

void main() {
  group('Day 39 — Farmer Profile Screen Tests', () {
    testWidgets('renders user profile with initials avatar, details, and language selector', (tester) async {
      final mockProfileService = MockProfileService();

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: ProfileScreen(
            userId: 'test-uid-123',
            customProfileService: mockProfileService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check initials avatar "GS"
      expect(find.text('GS'), findsOneWidget);
      // Check user details
      expect(find.text('Gurpreet Singh'), findsNWidgets(2)); // Header & field row
      expect(find.text('gurpreet@punjab.in'), findsOneWidget);
      expect(find.text('+91 98765 43210'), findsNWidgets(2));
      // Check language preference
      expect(find.text(AppStrings.languagePreference), findsOneWidget);
      expect(find.text(AppStrings.punjabiLanguage), findsOneWidget);
    });

    testWidgets('logout button opens confirmation dialog and confirms sign out', (tester) async {
      final mockProfileService = MockProfileService();
      bool didSignOut = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: ProfileScreen(
            userId: 'test-uid-123',
            customProfileService: mockProfileService,
            onSignOut: () async => didSignOut = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Logout button
      await tester.tap(find.text(AppStrings.logOut));
      await tester.pumpAndSettle();

      // Verify confirmation dialog
      expect(find.text(AppStrings.logoutConfirmTitle), findsOneWidget);
      expect(find.text(AppStrings.logoutConfirmMessage), findsOneWidget);

      // Tap Cancel in dialog
      await tester.tap(find.text(AppStrings.cancel));
      await tester.pumpAndSettle();

      expect(didSignOut, isFalse);

      // Tap Logout button again
      await tester.tap(find.text(AppStrings.logOut));
      await tester.pumpAndSettle();

      // Tap Log Out to confirm
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text(AppStrings.logOut)));
      await tester.pumpAndSettle();

      expect(didSignOut, isTrue);
    });

    testWidgets('error state displays retry button and reloads profile on tap', (tester) async {
      final mockProfileService = MockProfileService()
        ..stubbedResult = ProfileResult.networkError('Offline connection error');

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: ProfileScreen(
            userId: 'test-uid-123',
            customProfileService: mockProfileService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to load profile'), findsOneWidget);
      expect(find.text('Offline connection error'), findsOneWidget);
      expect(find.text(AppStrings.retry), findsOneWidget);

      // Update stubbed result to success and tap Retry
      mockProfileService.stubbedResult = ProfileResult.success(
        UserModel(
          uid: 'test-uid-123',
          name: 'Harpreet Kaur',
          email: 'harpreet@punjab.in',
          phone: '+91 98765 00000',
          language: 'pa',
          createdAt: DateTime.now(),
        ),
      );

      await tester.tap(find.text(AppStrings.retry));
      await tester.pumpAndSettle();

      expect(find.text('Harpreet Kaur'), findsNWidgets(2));
      expect(find.text('HK'), findsOneWidget);
    });

    testWidgets('ProfileScreen survives 1.3x font scaling without layout overflow', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });

      final mockProfileService = MockProfileService();

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: ProfileScreen(
            userId: 'test-uid-123',
            customProfileService: mockProfileService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.profileTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
