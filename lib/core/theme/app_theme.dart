import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color navyPrimary = Color(0xFF0B1F3A);
  static const Color navySecondary = Color(0xFF132C4E);
  static const Color navyMuted = Color(0xFF1E3A5F);
  static const Color emeraldAccent = Color(0xFF10B981);
  static const Color emeraldDark = Color(0xFF059669);
  static const Color emeraldSoft = Color(0xFFD1FAE5);
  static const Color surfaceLight = Color(0xFFF4F7FA);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF64748B);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFEF3C7);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color dangerSoft = Color(0xFFFEE2E2);
  static const Color infoBlue = Color(0xFF2563EB);
  static const Color infoSoft = Color(0xFFDBEAFE);
}

class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.navyPrimary,
      primary: AppColors.navyPrimary,
      secondary: AppColors.emeraldAccent,
      surface: AppColors.cardWhite,
      error: AppColors.dangerRed,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surfaceLight,
      textTheme: baseTextTheme.copyWith(
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          color: AppColors.navyPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: AppColors.navyPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: AppColors.textPrimary,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cardWhite,
        foregroundColor: AppColors.navyPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: baseTextTheme.titleLarge?.copyWith(
          color: AppColors.navyPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navyPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size(120, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.emeraldAccent,
          foregroundColor: Colors.white,
          minimumSize: const Size(120, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navyPrimary,
          minimumSize: const Size(100, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          side: const BorderSide(color: AppColors.borderLight, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.navyPrimary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.dangerRed),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.cardWhite,
        indicatorColor: AppColors.emeraldSoft,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.navyPrimary,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          );
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
      ),
    );
  }
}
