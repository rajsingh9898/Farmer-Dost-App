import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  /// Primary / success color: Trustworthy agricultural green (Figma spec)
  static const Color primary = Color(0xFF2E7D32);
  static const Color success = Color(0xFF2E7D32);

  /// Danger / error color: Clear red for counterfeit and error states
  static const Color danger = Color(0xFFD32F2F);
  static const Color error = Color(0xFFD32F2F);

  /// Caution / reserved amber: For recalled/expired/needs review states
  static const Color caution = Color(0xFFF57F17);
  static const Color cautionText = Color(0xFFB26A00); // Deep amber for outdoor contrast

  /// Specific Verification Status Colors
  static const Color recalled = Color(0xFFED6C02);
  static const Color expired = Color(0xFFE65100);
  static const Color offline = Color(0xFF0288D1);

  /// High-Contrast Status Container Backgrounds (Outdoor Field Tested)
  static const Color successContainer = Color(0xFFE8F5E9);
  static const Color errorContainer = Color(0xFFFFEBEE);
  static const Color cautionContainer = Color(0xFFFFF3E0);
  static const Color offlineContainer = Color(0xFFE1F5FE);

  /// Background: Light neutral
  static const Color background = Color(0xFFF7F7F7);

  /// Text: Deep charcoal/near-black for high contrast outdoor sunlight visibility
  static const Color textPrimary = Color(0xFF111418);

  /// Text: Sharpened dark grey for muted/secondary labels (WCAG AAA sunlight compliant)
  static const Color textSecondary = Color(0xFF42474E);

  /// Card / Surface color
  static const Color surface = Colors.white;

  /// High-contrast border color for outdoor legibility
  static const Color border = Color(0xFFE0E0E0);

  /// Helper to calculate WCAG 2.1 relative luminance
  static double getRelativeLuminance(Color color) {
    double transform(double c) {
      return (c <= 0.04045)
          ? c / 12.92
          : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
    }

    final r = transform(color.r);
    final g = transform(color.g);
    final b = transform(color.b);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Calculates WCAG contrast ratio between two colors (ratio from 1.0 to 21.0)
  static double calculateContrastRatio(Color foreground, Color background) {
    final l1 = getRelativeLuminance(foreground);
    final l2 = getRelativeLuminance(background);
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Validates if foreground/background meets standard WCAG AA contrast (4.5:1, or 3.0:1 for large text)
  static bool meetsWcagAA(Color foreground, Color background, {bool isLargeText = false}) {
    final ratio = calculateContrastRatio(foreground, background);
    return ratio >= (isLargeText ? 3.0 : 4.5);
  }

  /// Outdoor sunlight standard: Requires high-contrast ratio (>= 7.0:1, WCAG AAA)
  /// ensuring legibility for farmers working in bright sunlight
  static bool meetsOutdoorSunlightStandard(Color foreground, Color background) {
    final ratio = calculateContrastRatio(foreground, background);
    return ratio >= 7.0;
  }
}

class AppDimensions {
  AppDimensions._();

  /// Screen padding
  static const double screenPadding = 24.0;
  static const double screenPaddingSmall = 16.0;

  /// Card and container border radius
  static const double cardRadius = 16.0;
  static const double smallRadius = 12.0;
  static const double pillRadius = 24.0;
  static const double modalRadius = 24.0;

  /// Minimum Touch Target (Accessibility & Android Material guidelines: >= 48dp)
  static const double minTouchTarget = 48.0;

  /// Button dimensions
  static const double buttonRadius = 12.0;
  static const double buttonHeight = 52.0;
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0);

  /// Consistent Spacing steps
  static const double spaceTiny = 4.0;
  static const double spaceSmall = 8.0;
  static const double spaceMedium = 16.0;
  static const double spaceLarge = 24.0;
  static const double spaceXLarge = 32.0;
}

class AppStyles {
  AppStyles._();

  /// Large Display TextStyle for Hero & Splash (Inter weight 700)
  static TextStyle displayStyle = GoogleFonts.inter(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// Heading TextStyle (Inter weight 600)
  static TextStyle headingStyle = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Subheading / Section Title TextStyle
  static TextStyle sectionHeadingStyle = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Body TextStyle (Inter weight 400-500)
  static TextStyle bodyStyle = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  /// Muted / Secondary TextStyle (dates, subtext - outdoor sunlight enhanced)
  static TextStyle mutedStyle = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
}

/// Centralized ThemeData used across EVERY screen
final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    secondary: AppColors.primary,
    error: AppColors.danger,
    surface: AppColors.surface,
  ),
  textTheme: TextTheme(
    displayLarge: AppStyles.displayStyle,
    headlineMedium: AppStyles.headingStyle,
    titleMedium: AppStyles.sectionHeadingStyle,
    bodyMedium: AppStyles.bodyStyle,
    bodySmall: AppStyles.mutedStyle,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      padding: AppDimensions.buttonPadding,
      minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
      ),
      elevation: 2,
      textStyle: AppStyles.sectionHeadingStyle.copyWith(color: Colors.white),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      padding: AppDimensions.buttonPadding,
      minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
      ),
      side: const BorderSide(color: AppColors.primary, width: 1.5),
      textStyle: AppStyles.sectionHeadingStyle.copyWith(color: AppColors.primary),
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.surface,
    foregroundColor: AppColors.textPrimary,
    centerTitle: true,
    elevation: 0,
    titleTextStyle: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
  ),
);
