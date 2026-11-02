import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase_options.dart';
import '../theme/app_theme.dart';
import '../routes/app_routes.dart';
import '../l10n/app_strings.dart';

/// Day 30 — Splash Screen
///
/// Displays branding (Logo icon, "Farmer Dost", tagline).
/// Waits for Firebase initialization and Auth readiness with:
/// - Minimum display duration: 1.0 second (prevents jarring UI flicker)
/// - Maximum timeout: 6.0 seconds
/// - On success: routes via [AppRoutes.authGate]
/// - On failure/timeout: displays retry view with accessible >=48dp touch target
class SplashScreen extends StatefulWidget {
  /// Optional timeout for testing or customization
  final Duration timeout;
  /// Optional min delay for testing
  final Duration minDuration;
  /// Optional custom initializer hook for testing
  final Future<void> Function()? onInitialize;

  const SplashScreen({
    super.key,
    this.timeout = const Duration(seconds: 6),
    this.minDuration = const Duration(milliseconds: 1000),
    this.onInitialize,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasError = false;
  String? _errorMessage;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    if (!mounted) return;
    setState(() {
      _hasError = false;
      _errorMessage = null;
    });

    final stopwatch = Stopwatch()..start();

    try {
      await _runInitChecks().timeout(widget.timeout);

      // Enforce minimum splash display duration
      final elapsed = stopwatch.elapsed;
      if (elapsed < widget.minDuration && mounted) {
        final completer = Completer<void>();
        _delayTimer = Timer(widget.minDuration - elapsed, () {
          if (!completer.isCompleted) completer.complete();
        });
        await completer.future;
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.authGate);
    } catch (e) {
      debugPrint('[SplashScreen] Initialization error or timeout: $e');
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = AppStrings.splashInitFailed;
      });
    } finally {
      stopwatch.stop();
    }
  }

  /// Verifies Firebase Core initialization and Auth readiness
  Future<void> _runInitChecks() async {
    if (widget.onInitialize != null) {
      await widget.onInitialize!();
      return;
    }

    // 1. Ensure Firebase App initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    // 2. Auth readiness check
    try {
      await FirebaseAuth.instance.authStateChanges().first.timeout(
            const Duration(seconds: 3),
          );
    } catch (_) {
      // If authStateChanges times out (e.g. offline device), proceed if Firebase is initialized
      debugPrint('[SplashScreen] AuthState initial check continued');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenPadding,
              vertical: AppDimensions.screenPaddingSmall,
            ),
            child: _hasError ? _buildRetryState() : _buildLoadingState(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // App Logo: High-contrast green circular badge with checkmark shield
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.verified_user_rounded,
            size: 44,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceLarge),

        // App Title: "Farmer Dost"
        Text(
          AppStrings.appName,
          textAlign: TextAlign.center,
          style: AppStyles.displayStyle.copyWith(
            fontSize: 26,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceSmall),

        // Tagline: "Scan. Verify. Trust."
        Text(
          AppStrings.appTagline,
          textAlign: TextAlign.center,
          style: AppStyles.bodyStyle.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceXLarge + 16),

        // Accessible Progress Indicator
        const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildRetryState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Error indicator badge
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.cloud_off_rounded,
            size: 38,
            color: AppColors.danger,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceLarge),

        // App Title
        Text(
          AppStrings.appName,
          textAlign: TextAlign.center,
          style: AppStyles.headingStyle.copyWith(fontSize: 22),
        ),
        const SizedBox(height: AppDimensions.spaceSmall),

        // Farmer-friendly Error Description
        Text(
          _errorMessage ?? AppStrings.splashInitFailed,
          textAlign: TextAlign.center,
          style: AppStyles.bodyStyle.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceXLarge),

        // High-contrast, large touch target (>= 48dp) Retry Button
        SizedBox(
          width: double.infinity,
          height: AppDimensions.buttonHeight,
          child: ElevatedButton.icon(
            onPressed: _initializeApp,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text(
              AppStrings.retry,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
