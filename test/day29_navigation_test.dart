// ignore_for_file: subtype_of_sealed_class

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmer_dost_app/routes/app_routes.dart';
import 'package:farmer_dost_app/screens/splash_screen.dart';
import 'package:farmer_dost_app/screens/login_screen.dart';
import 'package:farmer_dost_app/screens/home_screen.dart';
import 'package:farmer_dost_app/screens/scan_screen.dart';
import 'package:farmer_dost_app/screens/result_screen.dart';
import 'package:farmer_dost_app/screens/report_screen.dart';
import 'package:farmer_dost_app/screens/profile_screen.dart';
import 'package:farmer_dost_app/services/services.dart';

void main() {
  group('Day 29 — AppRoutes Navigation Tests', () {
    testWidgets('generates MaterialPageRoute for splash route', (tester) async {
      final route = AppRoutes.onGenerateRoute(const RouteSettings(name: AppRoutes.splash));
      expect(route, isA<MaterialPageRoute>());
      final materialRoute = route as MaterialPageRoute;
      final widget = materialRoute.builder(tester.element(find.byType(Container)));
      expect(widget, isA<SplashScreen>());
    });

    testWidgets('generates MaterialPageRoute for login route', (tester) async {
      final route = AppRoutes.onGenerateRoute(const RouteSettings(name: AppRoutes.login));
      expect(route, isA<MaterialPageRoute>());
      final materialRoute = route as MaterialPageRoute;
      final widget = materialRoute.builder(tester.element(find.byType(Container)));
      expect(widget, isA<LoginScreen>());
    });

    testWidgets('generates MaterialPageRoute for home route', (tester) async {
      final route = AppRoutes.onGenerateRoute(const RouteSettings(name: AppRoutes.home));
      expect(route, isA<MaterialPageRoute>());
      final materialRoute = route as MaterialPageRoute;
      final widget = materialRoute.builder(tester.element(find.byType(Container)));
      expect(widget, isA<HomeScreen>());
    });

    testWidgets('generates MaterialPageRoute for scan route', (tester) async {
      final route = AppRoutes.onGenerateRoute(const RouteSettings(name: AppRoutes.scan));
      expect(route, isA<MaterialPageRoute>());
      final materialRoute = route as MaterialPageRoute;
      final widget = materialRoute.builder(tester.element(find.byType(Container)));
      expect(widget, isA<ScanScreen>());
    });

    testWidgets('generates MaterialPageRoute for profile route', (tester) async {
      final route = AppRoutes.onGenerateRoute(const RouteSettings(name: AppRoutes.profile));
      expect(route, isA<MaterialPageRoute>());
      final materialRoute = route as MaterialPageRoute;
      final widget = materialRoute.builder(tester.element(find.byType(Container)));
      expect(widget, isA<ProfileScreen>());
    });

    testWidgets('generates MaterialPageRoute for result route with typed VerificationResult', (tester) async {
      final mockResult = VerificationResult(
        status: VerificationStatus.genuine,
        scannedCode: 'FD-FT-00101-GEN001',
        name: 'Super Urea 46%',
        message: 'Genuine',
      );
      final route = AppRoutes.onGenerateRoute(
        RouteSettings(name: AppRoutes.result, arguments: mockResult),
      );
      expect(route, isA<MaterialPageRoute>());
      final materialRoute = route as MaterialPageRoute;
      final widget = materialRoute.builder(tester.element(find.byType(Container)));
      expect(widget, isA<ResultScreen>());
      final resultScreen = widget as ResultScreen;
      expect(resultScreen.scannedCode, equals('FD-FT-00101-GEN001'));
      expect(resultScreen.verificationResult, equals(mockResult));
    });

    testWidgets('generates MaterialPageRoute for report route with String code', (tester) async {
      final route = AppRoutes.onGenerateRoute(
        const RouteSettings(name: AppRoutes.report, arguments: 'FD-PS-00202-REC002'),
      );
      expect(route, isA<MaterialPageRoute>());
      final materialRoute = route as MaterialPageRoute;
      final widget = materialRoute.builder(tester.element(find.byType(Container)));
      expect(widget, isA<ReportScreen>());
      final reportScreen = widget as ReportScreen;
      expect(reportScreen.scannedCode, equals('FD-PS-00202-REC002'));
    });

    testWidgets('unrecognized route produces fallback error screen without crash', (tester) async {
      final route = AppRoutes.onGenerateRoute(const RouteSettings(name: '/invalid_unknown'));
      expect(route, isA<MaterialPageRoute>());
      final materialRoute = route as MaterialPageRoute;
      final widget = materialRoute.builder(tester.element(find.byType(Container)));
      expect(widget, isA<Scaffold>());
    });
  });

  group('Day 29 — Back Button & PopScope Behavior', () {
    testWidgets('ResultScreen contains PopScope to intercept Android back button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResultScreen(scannedCode: 'FD-FT-00101-GEN001'),
        ),
      );

      final popScopeFinder = find.byWidgetPredicate((widget) => widget is PopScope);
      expect(popScopeFinder, findsOneWidget);

      final popScope = tester.widget<PopScope>(popScopeFinder);
      expect(popScope.canPop, isFalse);
    });
  });
}
