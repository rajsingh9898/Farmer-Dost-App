import 'package:flutter/material.dart';
import '../models/verification_result.dart';
import '../screens/auth_gate.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/scan_screen.dart';
import '../screens/result_screen.dart';
import '../screens/report_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/scan_history_screen.dart';
import '../theme/app_theme.dart';

/// Typed arguments container for navigating to [ResultScreen].
class ResultScreenArguments {
  final VerificationResult? verificationResult;
  final String scannedCode;
  final bool isGenuine;
  final bool connectionError;
  
  final String? errorMessage;

  const ResultScreenArguments({
    this.verificationResult,
    required this.scannedCode,
    this.isGenuine = false,
    this.connectionError = false,
    this.errorMessage,
  });
}

/// Typed arguments container for navigating to [ReportScreen].
class ReportScreenArguments {
  final String scannedCode;

  const ReportScreenArguments({required this.scannedCode});
}

/// Central routing management with strongly typed navigation parameters.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String authGate = '/auth_gate';
  static const String login = '/login';
  static const String home = '/home';
  static const String scan = '/scan';
  static const String result = '/result';
  static const String report = '/report';
  static const String profile = '/profile';
  static const String scanHistory = '/scan_history';

  /// Primary Route Factory with typed argument parsing.
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );

      case authGate:
        return MaterialPageRoute(
          builder: (_) => const AuthGate(),
          settings: settings,
        );

      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );

      case home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );

      case scan:
        return MaterialPageRoute(
          builder: (_) => const ScanScreen(),
          settings: settings,
        );

      case result:
        final args = settings.arguments;
        if (args is VerificationResult) {
          return MaterialPageRoute(
            builder: (_) => ResultScreen(
              verificationResult: args,
              scannedCode: args.scannedCode,
              isGenuine: args.isGenuine,
              connectionError: args.status == VerificationStatus.networkError,
              errorMessage: args.message,
            ),
            settings: settings,
          );
        } else if (args is ResultScreenArguments) {
          return MaterialPageRoute(
            builder: (_) => ResultScreen(
              verificationResult: args.verificationResult,
              scannedCode: args.scannedCode,
              isGenuine: args.isGenuine,
              connectionError: args.connectionError,
              errorMessage: args.errorMessage,
            ),
            settings: settings,
          );
        } else if (args is String) {
          return MaterialPageRoute(
            builder: (_) => ResultScreen(scannedCode: args),
            settings: settings,
          );
        }
        // Fallback default for skeleton navigation
        return MaterialPageRoute(
          builder: (_) => const ResultScreen(scannedCode: 'FD-FT-00101-GEN001'),
          settings: settings,
        );

      case report:
        final args = settings.arguments;
        String productCode = '';
        if (args is String) {
          productCode = args;
        } else if (args is ReportScreenArguments) {
          productCode = args.scannedCode;
        }
        return MaterialPageRoute(
          builder: (_) => ReportScreen(scannedCode: productCode),
          settings: settings,
        );

      case profile:
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
          settings: settings,
        );

      case scanHistory:
        return MaterialPageRoute(
          builder: (_) => const ScanHistoryScreen(),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (ctx) => Scaffold(
            appBar: AppBar(title: const Text('Navigation Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 48),
                  const SizedBox(height: 16),
                  Text('Route not found: ${settings.name}', style: AppStyles.headingStyle),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(ctx, home),
                    child: const Text('Back to Home'),
                  ),
                ],
              ),
            ),
          ),
          settings: settings,
        );
    }
  }
}
