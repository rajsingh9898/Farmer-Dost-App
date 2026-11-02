import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmer_dost_app/theme/app_theme.dart';
import 'package:farmer_dost_app/routes/app_routes.dart';
import 'package:farmer_dost_app/screens/scan_screen.dart';
import 'package:farmer_dost_app/screens/result_screen.dart';
import 'package:farmer_dost_app/models/verification_result.dart';
import 'package:farmer_dost_app/l10n/app_strings.dart';

void main() {
  group('Day 34 — Scan to verifyProduct Integration Tests', () {
    testWidgets('shows loading overlay and calls verifyProduct on code entry', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      final completer = Completer<VerificationResult>();
      int verifyCallCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: ScanScreen(
            customVerifier: (code) {
              verifyCallCount++;
              return completer.future;
            },
          ),
        ),
      );

      // Open manual entry dialog
      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await tester.pumpAndSettle();

      // Tap chip to fill code
      await tester.tap(find.text('Genuine Urea'));
      await tester.pumpAndSettle();

      // Tap Verify Code
      await tester.tap(find.text(AppStrings.verifyCodeBtn));
      await tester.pump();

      // Verify that loading overlay appears
      expect(find.text(AppStrings.verifyingProduct), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(verifyCallCount, equals(1));

      // Complete verification
      completer.complete(
        const VerificationResult(
          status: VerificationStatus.genuine,
          scannedCode: 'FD-FT-00101-GEN001',
          name: 'IFFCO Neem Coated Urea 45kg',
          message: 'Genuine verified product.',
        ),
      );

      await tester.pumpAndSettle();

      // Verify Debug Dialog appears with result details
      expect(find.text(AppStrings.debugResultTitle), findsOneWidget);
      expect(find.text('FD-FT-00101-GEN001'), findsOneWidget);
      expect(find.text('IFFCO Neem Coated Urea 45kg'), findsOneWidget);
      expect(find.text(AppStrings.scanAgain), findsOneWidget);
      expect(find.text(AppStrings.viewFullResult), findsOneWidget);
    });

    testWidgets('displays still checking message when verification exceeds 3.5 seconds', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      final completer = Completer<VerificationResult>();

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: ScanScreen(
            customVerifier: (code) => completer.future,
          ),
        ),
      );

      // Open manual entry dialog and enter code
      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Genuine Urea'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.verifyCodeBtn));
      await tester.pump();

      // Initially verifyingProduct is shown, but stillChecking is NOT shown yet
      expect(find.text(AppStrings.verifyingProduct), findsOneWidget);
      expect(find.text(AppStrings.stillChecking), findsNothing);

      // Advance clock by 4 seconds (exceeding 3.5s slow timer)
      await tester.pump(const Duration(seconds: 4));

      // Still checking warning banner is now visible
      expect(find.text(AppStrings.stillChecking), findsOneWidget);

      completer.complete(
        const VerificationResult(
          status: VerificationStatus.genuine,
          scannedCode: 'FD-FT-00101-GEN001',
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('Scan Again action dismisses debug dialog and resets scanning state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: ScanScreen(
            customVerifier: (code) async {
              return const VerificationResult(
                status: VerificationStatus.genuine,
                scannedCode: 'FD-FT-00101-GEN001',
              );
            },
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Genuine Urea'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.verifyCodeBtn));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.debugResultTitle), findsOneWidget);

      // Tap Scan Again
      await tester.tap(find.text(AppStrings.scanAgain));
      await tester.pumpAndSettle();

      // Dialog is dismissed
      expect(find.text(AppStrings.debugResultTitle), findsNothing);
      expect(find.text(AppStrings.pointCameraPrompt), findsOneWidget);
    });

    testWidgets('View Full Result action navigates to ResultScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: ScanScreen(
            customVerifier: (code) async {
              return const VerificationResult(
                status: VerificationStatus.recalled,
                scannedCode: 'FD-PS-00202-REC002',
                name: 'Kisan Chlorpyrifos',
                message: 'Recalled product batch.',
              );
            },
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Recalled Batch'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.verifyCodeBtn));
      await tester.pumpAndSettle();

      // Tap View Full Result
      await tester.tap(find.text(AppStrings.viewFullResult));
      await tester.pumpAndSettle();

      // Navigates to ResultScreen
      expect(find.byType(ResultScreen), findsOneWidget);
      expect(find.text(AppStrings.resultTitle), findsOneWidget);
    });
  });
}
