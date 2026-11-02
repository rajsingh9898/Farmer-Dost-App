import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:farmer_dost_app/screens/report_screen.dart';
import 'package:farmer_dost_app/services/report_service.dart';
import 'package:farmer_dost_app/models/report_result.dart';
import 'package:farmer_dost_app/routes/app_routes.dart';
import 'package:farmer_dost_app/theme/app_theme.dart';
import 'package:farmer_dost_app/l10n/app_strings.dart';

class MockReportService extends ReportService {
  ReportResult? stubbedResult;
  Completer<ReportResult>? slowCompleter;
  String? capturedCode;
  String? capturedNote;
  int callCount = 0;

  @override
  Future<ReportResult> submitReport({
    required String productCode,
    GeoPoint? location,
    String? note,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    Duration? timeoutDuration,
  }) async {
    callCount++;
    capturedCode = productCode;
    capturedNote = note;
    if (slowCompleter != null) {
      return await slowCompleter!.future;
    }
    return stubbedResult ??
        const ReportResult(
          status: ReportStatus.success,
          productCode: 'FD-FT-99999-NOTFND',
          message: 'Success',
        );
  }
}

void main() {
  group('Day 38 — Report Screen Connected to submitReport Tests', () {
    setUp(() {});

    testWidgets('renders prefilled read-only code, note counter, and submit button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockService = MockReportService();

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: ReportScreen(
            scannedCode: 'FD-FT-99999-NOTFND',
            customReportService: mockService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('FD-FT-99999-NOTFND'), findsOneWidget);
      expect(find.text(AppStrings.reportScreenTitle), findsOneWidget);
      expect(find.text(AppStrings.submitReportBtn), findsOneWidget);
      expect(find.text('0/100'), findsOneWidget); // Character counter
    });

    testWidgets('submitting successful report triggers submitReport and shows success snackbar', (tester) async {
      final mockService = MockReportService()
        ..stubbedResult = const ReportResult(
          status: ReportStatus.success,
          productCode: 'FD-FT-99999-NOTFND',
          message: 'Success',
        );

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: ReportScreen(
            scannedCode: 'FD-FT-99999-NOTFND',
            customReportService: mockService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter optional note
      await tester.enterText(find.byType(TextFormField).last, 'Purchased from suspicious seller in mandi');
      await tester.pumpAndSettle();

      expect(find.textContaining('/100'), findsOneWidget);

      // Tap Submit Report
      await tester.ensureVisible(find.text(AppStrings.submitReportBtn));
      await tester.tap(find.text(AppStrings.submitReportBtn));
      await tester.pumpAndSettle();

      expect(mockService.callCount, equals(1));
      expect(mockService.capturedCode, equals('FD-FT-99999-NOTFND'));
      expect(mockService.capturedNote, equals('Purchased from suspicious seller in mandi'));
      expect(find.text(AppStrings.reportSuccess), findsOneWidget);
    });

    testWidgets('submitting duplicate report shows alreadyReported feedback', (tester) async {
      final mockService = MockReportService()
        ..stubbedResult = const ReportResult(
          status: ReportStatus.alreadyReported,
          productCode: 'FD-FT-99999-NOTFND',
          message: 'Already reported',
        );

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: ReportScreen(
            scannedCode: 'FD-FT-99999-NOTFND',
            customReportService: mockService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text(AppStrings.submitReportBtn));
      await tester.tap(find.text(AppStrings.submitReportBtn));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.reportAlreadyReported), findsOneWidget);
    });

    testWidgets('network error preserves entered note for user retry', (tester) async {
      final mockService = MockReportService()
        ..stubbedResult = const ReportResult(
          status: ReportStatus.networkError,
          productCode: 'FD-FT-99999-NOTFND',
          message: 'Network offline. Please check your connection.',
        );

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: ReportScreen(
            scannedCode: 'FD-FT-99999-NOTFND',
            customReportService: mockService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).last, 'Bags looked tampered');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text(AppStrings.submitReportBtn));
      await tester.tap(find.text(AppStrings.submitReportBtn));
      await tester.pumpAndSettle();

      // Note must remain in the field
      expect(find.text('Bags looked tampered'), findsOneWidget);
      expect(find.text('Network offline. Please check your connection.'), findsOneWidget);
    });

    testWidgets('disables submit button while submission is in-flight to prevent double submissions', (tester) async {
      final slowCompleter = Completer<ReportResult>();
      final mockService = MockReportService()..slowCompleter = slowCompleter;

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: ReportScreen(
            scannedCode: 'FD-FT-99999-NOTFND',
            customReportService: mockService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text(AppStrings.submitReportBtn));
      await tester.tap(find.text(AppStrings.submitReportBtn));
      await tester.pump(); // Enter loading state

      // CircularProgressIndicator should be visible inside the button
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Attempt second tap while in-flight
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(mockService.callCount, equals(1)); // Still only 1 call

      slowCompleter.complete(
        const ReportResult(
          status: ReportStatus.success,
          productCode: 'FD-FT-99999-NOTFND',
          message: 'Done',
        ),
      );
      await tester.pumpAndSettle();

      expect(mockService.callCount, equals(1));
    });

    testWidgets('ReportScreen survives 1.3x font scaling without layout overflow', (tester) async {
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
          home: const ReportScreen(scannedCode: 'FD-FT-99999-NOTFND'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.reportScreenTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
