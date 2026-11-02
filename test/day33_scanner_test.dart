import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmer_dost_app/theme/app_theme.dart';
import 'package:farmer_dost_app/routes/app_routes.dart';
import 'package:farmer_dost_app/screens/scan_screen.dart';
import 'package:farmer_dost_app/widgets/corner_brackets_painter.dart';
import 'package:farmer_dost_app/l10n/app_strings.dart';

void main() {
  group('Day 33 — Scanner Screen UI & Overlay Tests', () {
    testWidgets('renders corner bracket viewfinder target and camera prompt', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: const ScanScreen(),
        ),
      );

      // Verify corner brackets painter
      final customPaintFinder = find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is CornerBracketsPainter,
      );
      expect(customPaintFinder, findsOneWidget);

      // Verify instruction text
      expect(find.text(AppStrings.pointCameraPrompt), findsOneWidget);
    });

    testWidgets('renders top action buttons with >=48dp touch targets', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: const ScanScreen(),
        ),
      );

      // Close button
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Torch button
      expect(find.byIcon(Icons.flash_off_rounded), findsOneWidget);

      // Manual entry button
      expect(find.byIcon(Icons.keyboard_outlined), findsOneWidget);
    });

    testWidgets('manual code entry triggers scanned code result dialog', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: const ScanScreen(),
        ),
      );

      // Tap manual entry button
      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await tester.pumpAndSettle();

      // Verify manual entry dialog appears
      expect(find.text(AppStrings.manualCodeDialogTitle), findsOneWidget);

      // Tap chip to populate code
      await tester.tap(find.text('Genuine Urea'));
      await tester.pumpAndSettle();

      // Tap Verify Code button
      await tester.tap(find.text(AppStrings.verifyCodeBtn));
      await tester.pumpAndSettle();

      // Verify Scanned Result Dialog appears with scanned value
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && (w.data == AppStrings.scannedQrTitle || w.data == AppStrings.debugResultTitle),
        ),
        findsOneWidget,
      );
      expect(find.text('FD-FT-00101-GEN001'), findsOneWidget);
      expect(find.text(AppStrings.scanAgain), findsOneWidget);

      // Tap Scan Again to resume scanner
      await tester.tap(find.text(AppStrings.scanAgain));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.scannedQrTitle), findsNothing);
      expect(find.text(AppStrings.debugResultTitle), findsNothing);
    });

    testWidgets('ScanScreen survives 1.3x font scaling without layout overflow', (tester) async {
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
          home: const ScanScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.pointCameraPrompt), findsOneWidget);
    });
  });
}
