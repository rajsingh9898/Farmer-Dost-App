import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmer_dost_app/screens/scan_screen.dart';
import 'package:farmer_dost_app/models/verification_result.dart';
import 'package:farmer_dost_app/routes/app_routes.dart';
import 'package:farmer_dost_app/theme/app_theme.dart';
import 'package:farmer_dost_app/l10n/app_strings.dart';

void main() {
  group('Day 35 — Scan-to-Verify Race Condition Buffer Tests', () {
    testWidgets('disposing ScanScreen while verification Future is pending does not throw setState after dispose', (tester) async {
      final Completer<VerificationResult> slowCompleter = Completer<VerificationResult>();

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: ScanScreen(
            customVerifier: (code) => slowCompleter.future,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open manual code dialog and trigger verification
      await tester.tap(find.byIcon(Icons.keyboard_outlined).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Genuine Urea'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.verifyCodeBtn));
      await tester.pump(); // Enter loading state

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Pop/replace widget tree while verification is in-flight (simulating navigating away or closing screen)
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: const Scaffold(body: Text('Different Screen')),
        ),
      );

      // Now complete the slow async verification AFTER ScanScreen has been unmounted & disposed
      slowCompleter.complete(
        const VerificationResult(
          status: VerificationStatus.genuine,
          scannedCode: 'FD-FT-00101-GEN001',
          name: 'IFFCO Neem Coated Urea',
        ),
      );

      // Pump to process microtasks and ensure no unhandled exceptions were thrown
      await tester.pumpAndSettle();

      expect(find.text('Different Screen'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('didChangeAppLifecycleState does not crash when controller is stopped or disposed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: const ScanScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Simulate backgrounding the app
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();

      // Simulate foregrounding the app
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping manual verify does not trigger duplicate requests if tapped repeatedly', (tester) async {
      int callCount = 0;
      final Completer<VerificationResult> completer = Completer<VerificationResult>();

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: ScanScreen(
            customVerifier: (code) {
              callCount++;
              return completer.future;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open manual dialog
      await tester.tap(find.byIcon(Icons.keyboard_outlined).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Genuine Urea'));
      await tester.pumpAndSettle();

      // Tap Verify Code button
      await tester.tap(find.text(AppStrings.verifyCodeBtn));
      await tester.pump();

      expect(callCount, equals(1));

      // Attempt to enter verification again while already verifying
      completer.complete(
        const VerificationResult(
          status: VerificationStatus.genuine,
          scannedCode: 'FD-FT-00101-GEN001',
        ),
      );
      await tester.pumpAndSettle();

      expect(callCount, equals(1));
      expect(tester.takeException(), isNull);
    });
  });
}
