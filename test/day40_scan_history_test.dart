import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmer_dost_app/screens/scan_history_screen.dart';
import 'package:farmer_dost_app/services/scan_history_service.dart';
import 'package:farmer_dost_app/models/scan_model.dart';
import 'package:farmer_dost_app/widgets/scan_history_tile.dart';
import 'package:farmer_dost_app/routes/app_routes.dart';
import 'package:farmer_dost_app/theme/app_theme.dart';
import 'package:farmer_dost_app/l10n/app_strings.dart';

class MockScanHistoryService extends ScanHistoryService {
  List<ScanModel> stubbedScans = [];
  bool stubbedHasMore = false;
  int getHistoryCallCount = 0;
  String? stubbedErrorMessage;

  @override
  Future<ScanHistoryResult> getScanHistory({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    getHistoryCallCount++;
    if (stubbedErrorMessage != null) {
      return ScanHistoryResult.networkError(stubbedErrorMessage);
    }
    return ScanHistoryResult.success(
      scans: stubbedScans,
      hasMore: stubbedHasMore,
    );
  }
}

void main() {
  group('Day 40 — Paginated Scan History Tests', () {
    testWidgets('renders paginated list of scans with product name, date, and status badges', (tester) async {
      final mockService = MockScanHistoryService()
        ..stubbedScans = List.generate(
          5,
          (i) => ScanModel(
            id: 'scan-$i',
            userId: 'user-1',
            productCode: 'FD-FT-0010$i-GEN00$i',
            productName: 'Sample Fertilizer $i',
            result: i.isEven ? 'genuine' : 'fake',
            timestamp: DateTime(2026, 10, 20, 10, i * 10),
          ),
        );

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: ScanHistoryScreen(customScanHistoryService: mockService),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.scanHistoryTitle), findsOneWidget);
      expect(find.byType(ScanHistoryTile), findsNWidgets(5));
      expect(find.text('Sample Fertilizer 0'), findsOneWidget);
      expect(find.text('Sample Fertilizer 4'), findsOneWidget);
    });

    testWidgets('renders empty state with Scan button when no scans are present', (tester) async {
      final mockService = MockScanHistoryService()..stubbedScans = [];

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: ScanHistoryScreen(customScanHistoryService: mockService),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.noScansYet), findsOneWidget);
      expect(find.text(AppStrings.tapToScan), findsOneWidget);
      expect(find.byType(ScanHistoryTile), findsNothing);
    });

    testWidgets('tapping scan row opens read-only detail bottom sheet', (tester) async {
      final mockService = MockScanHistoryService()
        ..stubbedScans = [
          ScanModel(
            id: 'audit-ref-9988',
            userId: 'user-1',
            productCode: 'FD-FT-00101-GEN001',
            productName: 'IFFCO Neem Coated Urea',
            result: 'genuine',
            timestamp: DateTime(2026, 10, 20, 14, 30),
          ),
        ];

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: ScanHistoryScreen(customScanHistoryService: mockService),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on the scan tile
      await tester.tap(find.text('IFFCO Neem Coated Urea'));
      await tester.pumpAndSettle();

      // Modal Bottom Sheet appears with details
      expect(find.text('Scan Details'), findsOneWidget);
      expect(find.text('audit-ref-9988'), findsOneWidget);
      expect(
        find.descendant(of: find.byType(BottomSheet), matching: find.text('FD-FT-00101-GEN001')),
        findsOneWidget,
      );
      expect(find.text(AppStrings.done), findsOneWidget);

      // Close bottom sheet
      await tester.tap(find.text(AppStrings.done));
      await tester.pumpAndSettle();

      expect(find.text('Scan Details'), findsNothing);
    });

    testWidgets('shows Load More button when hasMore is true and appends next batch', (tester) async {
      final mockService = MockScanHistoryService()
        ..stubbedScans = List.generate(
          5,
          (i) => ScanModel(
            id: 'scan-$i',
            userId: 'user-1',
            productCode: 'FD-FT-0010$i-GEN00$i',
            productName: 'Batch 1 Item $i',
            result: 'genuine',
            timestamp: DateTime(2026, 10, 20, 10, 0),
          ),
        )
        ..stubbedHasMore = true;

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: ScanHistoryScreen(customScanHistoryService: mockService),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.loadMore), findsOneWidget);

      // Setup page 2
      mockService.stubbedScans = [
        ScanModel(
          id: 'scan-page-2',
          userId: 'user-1',
          productCode: 'FD-PS-00202-REC002',
          productName: 'Batch 2 New Item',
          result: 'recalled',
          timestamp: DateTime(2026, 10, 19, 9, 0),
        ),
      ];
      mockService.stubbedHasMore = false;

      // Tap Load More button
      await tester.tap(find.text(AppStrings.loadMore));
      await tester.pumpAndSettle();

      expect(mockService.getHistoryCallCount, equals(2));
      expect(find.text('Batch 2 New Item'), findsOneWidget);
      expect(find.text(AppStrings.loadMore), findsNothing);
    });

    testWidgets('ScanHistoryScreen survives 1.3x font scaling without layout overflow', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });

      final mockService = MockScanHistoryService()
        ..stubbedScans = [
          ScanModel(
            id: 'scan-scale',
            userId: 'user-1',
            productCode: 'FD-FT-00101-GEN001',
            productName: 'Long Product Name Fertilizer 45kg Bag',
            result: 'genuine',
            timestamp: DateTime.now(),
          ),
        ];

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: ScanHistoryScreen(customScanHistoryService: mockService),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.scanHistoryTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
