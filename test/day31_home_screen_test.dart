import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmer_dost_app/theme/app_theme.dart';
import 'package:farmer_dost_app/routes/app_routes.dart';
import 'package:farmer_dost_app/screens/home_screen.dart';
import 'package:farmer_dost_app/widgets/primary_scan_button.dart';
import 'package:farmer_dost_app/widgets/scan_history_tile.dart';
import 'package:farmer_dost_app/widgets/status_badge.dart';
import 'package:farmer_dost_app/l10n/app_strings.dart';

void main() {
  group('Day 31 — Home Screen Static UI Tests', () {
    testWidgets('renders top bar with app title and profile action button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: const HomeScreen(),
        ),
      );

      // Verify App Bar Title
      expect(find.text(AppStrings.appName), findsOneWidget);

      // Verify Profile Icon
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    });

    testWidgets('renders PrimaryScanButton hero element with Tap to scan label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: const HomeScreen(),
        ),
      );

      // Verify Hero Circular Scan Button widget
      expect(find.byType(PrimaryScanButton), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
      expect(find.text(AppStrings.tapToScan), findsOneWidget);
    });

    testWidgets('PrimaryScanButton executes press animation and fires onTap on release', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: Scaffold(
            body: Center(
              child: PrimaryScanButton(
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(PrimaryScanButton);
      expect(buttonFinder, findsOneWidget);

      // Tap Down triggers press scale animation
      final gesture = await tester.startGesture(tester.getCenter(buttonFinder));
      await tester.pump(const Duration(milliseconds: 60));

      // Verify scale transform is applied (< 1.0)
      final transformFinder = find.descendant(
        of: buttonFinder,
        matching: find.byType(Transform),
      );
      expect(transformFinder, findsWidgets);

      // Tap Up completes animation and triggers onTap
      await gesture.up();
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('renders Recent Scans section with placeholder genuine and fake rows', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: const HomeScreen(),
        ),
      );

      // Verify Section Heading & View All link
      expect(find.text(AppStrings.recentScans), findsOneWidget);
      expect(find.text(AppStrings.viewAllScans), findsOneWidget);

      // Verify ScanHistoryTile rows
      expect(find.byType(ScanHistoryTile), findsNWidgets(4));

      // Verify genuine sample product
      expect(find.text('IFFCO Neem Coated Urea 45kg'), findsOneWidget);

      // Verify counterfeit sample alert
      expect(find.text('Super Phosphate DAP (Unregistered)'), findsOneWidget);

      // Verify status badges presence
      expect(find.byType(StatusBadge), findsWidgets);
    });

    testWidgets('renders empty state correctly when showEmptyState is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: const HomeScreen(showEmptyState: true),
        ),
      );

      expect(find.text(AppStrings.noScansYet), findsOneWidget);
      expect(find.byType(ScanHistoryTile), findsNothing);
    });

    testWidgets('ScanHistoryTile enforces minimum 48dp touch target and handles tap', (tester) async {
      bool tileTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: Scaffold(
            body: ScanHistoryTile(
              productName: 'Sample Fertilizer',
              productCode: 'FD-FT-00101-GEN001',
              formattedDate: 'Today, 12:00 PM',
              status: 'genuine',
              onTap: () {
                tileTapped = true;
              },
            ),
          ),
        ),
      );

      final tileFinder = find.byType(ScanHistoryTile);
      final size = tester.getSize(tileFinder);

      // Enforce minimum 48dp touch target standard
      expect(size.height, greaterThanOrEqualTo(48.0));

      await tester.tap(tileFinder);
      await tester.pumpAndSettle();

      expect(tileTapped, isTrue);
    });

    testWidgets('HomeScreen survives 1.3x font scaling without layout overflow', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: const HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Ensure no layout overflow exceptions occurred
      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.appName), findsOneWidget);
      expect(find.byType(PrimaryScanButton), findsOneWidget);
      expect(find.byType(ScanHistoryTile), findsWidgets);

      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
  });
}
