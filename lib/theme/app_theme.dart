import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  /// Primary / success color: Trustworthy agricultural green
  static const Color primary = Color(0xFF2E7D32);
  static const Color success = Color(0xFF2E7D32);

  /// Danger / warning color: Clear red for fake product states
  static const Color danger = Color(0xFFD32F2F);
  static const Color error = Color(0xFFD32F2F);

  /// Caution / needs review color: Reserved amber for caution states
  static const Color caution = Color(0xFFF9A825);

  /// Background: Light neutral
  static const Color background = Color(0xFFF7F7F7);

  /// Text: Dark grey / near-black for primary text
  static const Color textPrimary = Color(0xFF1A1C1E);

  /// Text: Medium grey for muted / secondary text (dates, subtext)
  static const Color textSecondary = Color(0xFF74777F);

  /// Card / Surface color
  static const Color surface = Colors.white;
}

class AppDimensions {
  /// Screen padding
  static const double screenPadding = 24.0;
  static const double screenPaddingSmall = 16.0;

  /// Card and container border radius
  static const double cardRadius = 16.0;
  static const double smallRadius = 12.0;
  static const double pillRadius = 24.0;

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

  /// Muted / Secondary TextStyle (dates, subtext)
  static TextStyle mutedStyle = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
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
