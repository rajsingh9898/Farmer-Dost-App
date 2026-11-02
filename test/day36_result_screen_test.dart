import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmer_dost_app/screens/result_screen.dart';
import 'package:farmer_dost_app/models/verification_result.dart';
import 'package:farmer_dost_app/routes/app_routes.dart';
import 'package:farmer_dost_app/theme/app_theme.dart';
import 'package:farmer_dost_app/l10n/app_strings.dart';

void main() {
  group('Day 36 & 37 — Result Screen & Visual/Haptic Feedback Tests', () {
    testWidgets('renders Genuine product result with green theme, metadata, and bottom actions', (tester) async {
      const genuineResult = VerificationResult(
        status: VerificationStatus.genuine,
        scannedCode: 'FD-FT-00101-GEN001',
        name: 'IFFCO Neem Coated Urea',
        manufacturer: 'IFFCO India',
        batch: 'B-2026-01',
        type: 'fertilizer',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: const ResultScreen(
            verificationResult: genuineResult,
            scannedCode: 'FD-FT-00101-GEN001',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.genuineHeading), findsOneWidget);
      expect(find.text('IFFCO Neem Coated Urea'), findsOneWidget);
      expect(find.text('IFFCO India'), findsOneWidget);
      expect(find.text(AppStrings.scanAnother), findsOneWidget);
      expect(find.text(AppStrings.backToHome), findsOneWidget);
      // No report button on genuine products
      expect(find.text(AppStrings.reportCounterfeit), findsNothing);
    });

    testWidgets('renders Not Recognized status with alert card and Report button', (tester) async {
      const fakeResult = VerificationResult(
        status: VerificationStatus.notRecognized,
        scannedCode: 'FD-FT-99999-NOTFND',
        message: 'This code was not found in our database.',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: const ResultScreen(
            verificationResult: fakeResult,
            scannedCode: 'FD-FT-99999-NOTFND',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.notRecognizedHeading), findsOneWidget);
      expect(find.text(AppStrings.reportCounterfeit), findsOneWidget);
      expect(find.text(AppStrings.scanAnother), findsOneWidget);
      expect(find.text(AppStrings.backToHome), findsOneWidget);
    });

    testWidgets('renders Recalled product status with warning and Report Recalled button', (tester) async {
      const recalledResult = VerificationResult(
        status: VerificationStatus.recalled,
        scannedCode: 'FD-PS-00202-REC002',
        name: 'Kisan Chlorpyrifos',
        manufacturer: 'Punjab Agro Chemicals',
        batch: 'RCL-2026-99',
        type: 'pesticide',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: const ResultScreen(
            verificationResult: recalledResult,
            scannedCode: 'FD-PS-00202-REC002',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.recalledHeading), findsOneWidget);
      expect(find.text(AppStrings.reportRecalled), findsOneWidget);
      expect(find.text('Kisan Chlorpyrifos'), findsOneWidget);
      expect(find.text('RCL-2026-99'), findsOneWidget);
    });

    testWidgets('renders Expired product status with warning and Report Expired button', (tester) async {
      const expiredResult = VerificationResult(
        status: VerificationStatus.expired,
        scannedCode: 'FD-PS-00888-EXPIRE',
        name: 'Dursban Chlorpyrifos 20% EC',
        manufacturer: 'Agro Corp',
        batch: 'EXP-101',
        type: 'pesticide',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: const ResultScreen(
            verificationResult: expiredResult,
            scannedCode: 'FD-PS-00888-EXPIRE',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.expiredHeading), findsOneWidget);
      expect(find.text(AppStrings.reportExpired), findsOneWidget);
      expect(find.text('Dursban Chlorpyrifos 20% EC'), findsOneWidget);
    });

    testWidgets('renders Network Error status with offline error card and NO report button', (tester) async {
      const netErrorResult = VerificationResult(
        status: VerificationStatus.networkError,
        scannedCode: 'FD-FT-00101-GEN001',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: const ResultScreen(
            verificationResult: netErrorResult,
            scannedCode: 'FD-FT-00101-GEN001',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.networkErrorHeading), findsOneWidget);
      expect(find.text(AppStrings.reportCounterfeit), findsNothing);
      expect(find.text('Retry Verification'), findsOneWidget);
      expect(find.text(AppStrings.backToHome), findsOneWidget);
    });

    testWidgets('renders Invalid Input status with format warning and NO report button', (tester) async {
      const invalidResult = VerificationResult(
        status: VerificationStatus.invalidInput,
        scannedCode: 'INVALID-123',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: const ResultScreen(
            verificationResult: invalidResult,
            scannedCode: 'INVALID-123',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.invalidFormatHeading), findsOneWidget);
      expect(find.text(AppStrings.reportCounterfeit), findsNothing);
      expect(find.text(AppStrings.scanAgain), findsOneWidget);
      expect(find.text(AppStrings.backToHome), findsOneWidget);
    });

    testWidgets('ResultScreen survives 1.3x font scaling without layout overflow', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });

      const genuineResult = VerificationResult(
        status: VerificationStatus.genuine,
        scannedCode: 'FD-FT-00101-GEN001',
        name: 'IFFCO Neem Coated Urea 45kg',
        manufacturer: 'Indian Farmers Fertiliser Cooperative Limited',
        batch: 'B-2026-LONG-BATCH-NUM',
        type: 'fertilizer',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: const ResultScreen(
            verificationResult: genuineResult,
            scannedCode: 'FD-FT-00101-GEN001',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.genuineHeading), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
