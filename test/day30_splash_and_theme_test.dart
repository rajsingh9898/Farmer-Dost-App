import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmer_dost_app/theme/app_theme.dart';
import 'package:farmer_dost_app/screens/splash_screen.dart';
import 'package:farmer_dost_app/l10n/app_strings.dart';
import 'package:farmer_dost_app/routes/app_routes.dart';

void main() {
  group('Day 30 — Outdoor Sunlight Contrast & Theme Checks', () {
    test('textPrimary on surface achieves high contrast >= 7.0:1 (WCAG AAA sunlight standard)', () {
      final ratio = AppColors.calculateContrastRatio(AppColors.textPrimary, AppColors.surface);
      expect(ratio, greaterThanOrEqualTo(7.0),
          reason: 'textPrimary ($ratio:1) must provide exceptional sunlight visibility on surface');
      expect(AppColors.meetsOutdoorSunlightStandard(AppColors.textPrimary, AppColors.surface), isTrue);
    });

    test('textPrimary on background achieves high contrast >= 7.0:1 (WCAG AAA)', () {
      final ratio = AppColors.calculateContrastRatio(AppColors.textPrimary, AppColors.background);
      expect(ratio, greaterThanOrEqualTo(7.0),
          reason: 'textPrimary ($ratio:1) must provide high outdoor visibility on background');
      expect(AppColors.meetsOutdoorSunlightStandard(AppColors.textPrimary, AppColors.background), isTrue);
    });

    test('textSecondary on surface meets WCAG AA standard >= 4.5:1', () {
      final ratio = AppColors.calculateContrastRatio(AppColors.textSecondary, AppColors.surface);
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'Secondary text ($ratio:1) must be legible in daylight');
      expect(AppColors.meetsWcagAA(AppColors.textSecondary, AppColors.surface), isTrue);
    });

    test('primary green brand color with white text meets AA contrast', () {
      final ratio = AppColors.calculateContrastRatio(Colors.white, AppColors.primary);
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'White text on primary buttons ($ratio:1) must be readable in sunlight');
    });

    test('danger red brand color with white text meets AA contrast', () {
      final ratio = AppColors.calculateContrastRatio(Colors.white, AppColors.danger);
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'White text on danger alerts ($ratio:1) must be readable');
    });

    test('All interactive touch targets adhere to min 48dp standard', () {
      expect(AppDimensions.minTouchTarget, greaterThanOrEqualTo(48.0));
      expect(AppDimensions.buttonHeight, greaterThanOrEqualTo(48.0));
    });

    testWidgets('Typography uses consistent Inter font family across styles', (tester) async {
      expect(GoogleFonts.asMap().containsKey('Inter'), isTrue);
      expect(AppStyles.displayStyle.fontSize, equals(26));
      expect(AppStyles.headingStyle.fontSize, equals(20));
      expect(AppStyles.sectionHeadingStyle.fontSize, equals(16));
      expect(AppStyles.bodyStyle.fontSize, equals(14));
      expect(AppStyles.mutedStyle.fontSize, equals(12));
    });
  });

  group('Day 30 — Splash Screen Widget & Accessibility Tests', () {
    testWidgets('renders brand elements: logo, app title, and tagline', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: SplashScreen(
            onInitialize: () async {
              // Wait a tick to simulate check without pending unhandled timers
              await Future<void>.delayed(const Duration(milliseconds: 50));
            },
            minDuration: const Duration(milliseconds: 100),
          ),
        ),
      );

      // Verify Brand Logo icon
      expect(find.byIcon(Icons.verified_user_rounded), findsOneWidget);

      // Verify App Name
      expect(find.text(AppStrings.appName), findsOneWidget);

      // Verify Tagline
      expect(find.text(AppStrings.appTagline), findsOneWidget);

      // Verify Circular Loading Indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Settle the init timer
      await tester.pump(const Duration(milliseconds: 150));
    });

    testWidgets('survives 1.3x font scaling without layout overflow', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: SplashScreen(
            onInitialize: () async {
              await Future<void>.delayed(const Duration(milliseconds: 50));
            },
            minDuration: const Duration(milliseconds: 100),
          ),
        ),
      );

      await tester.pump();

      // No overflow exceptions thrown
      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.appName), findsOneWidget);
      expect(find.text(AppStrings.appTagline), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 150));
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    testWidgets('displays retry state when initialization fails or times out', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: SplashScreen(
            onInitialize: () async {
              throw Exception('Simulated Network Offline');
            },
            minDuration: Duration.zero,
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // Should display Retry state UI
      expect(find.text(AppStrings.splashInitFailed), findsOneWidget);
      expect(find.text(AppStrings.retry), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);

      // Touch target verification for retry button
      final retryButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(retryButton.onPressed, isNotNull);

      final buttonFinder = find.byType(ElevatedButton);
      final size = tester.getSize(buttonFinder);
      expect(size.height, greaterThanOrEqualTo(48.0),
          reason: 'Retry button height must meet minimum 48dp touch target requirement');
    });
  });
}
