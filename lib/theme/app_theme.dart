import 'package:flutter/material.dart';

class AppColors {
  // ── Modern Fintech Blue Palette ──────────────────────────────────────

  // Primary & Accents
  static const Color primary = Color(0xFF2563EB); // Royal Blue
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryLighter = Color(0xFF93C5FD);
  static const Color primaryBackground = Color(0xFFDBEAFE);

  static const Color secondary = Color(0xFF10B981); // Emerald Green
  static const Color secondaryLight = Color(0xFF6EE7B7);

  static const Color accentPurple = Color(0xFF8B5CF6); // Vibrant Violet
  static const Color accentOrange = Color(0xFFF59E0B); // Warm Amber

  // Semantic Colors
  static const Color error = Color(0xFFF43F5E); // Soft Rose
  static const Color errorDark = Color(0xFFE11D48);
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color warning = Color(0xFFF59E0B); // Warm Amber

  // Data-Visualization (Pie Chart)
  static const Color chartGreen = Color(0xFF10B981); // Income / Savings
  static const Color chartRose = Color(0xFFF43F5E); // Primary Expense
  static const Color chartViolet = Color(0xFF8B5CF6); // Violet
  static const Color chartIndigo = Color(0xFF6366F1); // Indigo
  static const Color chartBlue = Color(0xFF3B82F6); // Blue
  static const Color chartYellow = Color(0xFFEAB308); // Yellow
  static const Color chartOrange = Color(0xFFF97316); // Orange
  static const Color chartRed = Color(0xFFEF4444); // Red
  static const Color chartAmber = Color(0xFFF59E0B); // Tertiary Category

  // Neutrals / Typography
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF333333);
  static const Color textTertiary = Color(0xFF545454);
  static const Color textHint = Color(0xFF8A8A8A);

  // Greys and Borders
  static const Color greyDark = Color(0xFF54555A);
  static const Color greyMedium = Color(0xFFD9D9D9);
  static const Color greyLight = Color(0xFFE6E6E6);

  // Backgrounds
  static const Color background = Color(0xFFF8FAFC); // Very Light Gray
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color transparent = Color(0x00000000);
  static const Color black = Color(0xFF000000);

  // Legacy aliases for existing views
  static const Color primaryBlue = primary;
  static const Color textBody = textSecondary;
  static const Color textDark = textPrimary;
  static const Color textLight = textHint;
  static const Color cardBg = background;
  static const Color expenseRed = error;
  static const Color incomeGreen = success;
  static const Color white = Color(0xFFFFFFFF);
}

class AppTypography {
  // We use Inter as the primary font and Poppins for stylistic headers depending on usage.

  // App TextTheme (using Inter as the primary body font)
  static TextTheme getTextTheme() {
    return const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w700,
        fontSize: 32.0,
        color: AppColors.textPrimary,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w700,
        fontSize: 24.0,
        color: AppColors.textPrimary,
      ), // Inter_700_24
      displaySmall: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        fontSize: 24.0,
        color: AppColors.textPrimary,
      ), // Inter_600_24

      headlineLarge: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        fontSize: 20.0,
        color: AppColors.textPrimary,
      ), // Inter_600_20
      headlineMedium: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
        fontSize: 20.0,
        color: AppColors.textPrimary,
      ), // Inter_500_20
      headlineSmall: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        fontSize: 18.0,
        color: AppColors.textPrimary,
      ), // Poppins_600_18

      titleLarge: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        fontSize: 17.0,
        color: AppColors.textPrimary,
      ), // Inter_600_17
      titleMedium: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        fontSize: 16.0,
        color: AppColors.textPrimary,
      ), // Poppins_600_16
      titleSmall: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w500,
        fontSize: 16.0,
        color: AppColors.textPrimary,
      ), // Poppins_500_16

      bodyLarge: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        fontSize: 16.0,
        color: AppColors.textSecondary,
      ), // Inter_400_16
      bodyMedium: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w400,
        fontSize: 14.0,
        color: AppColors.textSecondary,
      ), // Poppins_400_14
      bodySmall: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        fontSize: 12.0,
        color: AppColors.textTertiary,
      ), // Inter_400_12

      labelLarge: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
        fontSize: 14.0,
        color: AppColors.textSecondary,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
        fontSize: 12.0,
        color: AppColors.textTertiary,
      ), // Inter_500_12
      labelSmall: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        fontSize: 11.0,
        color: AppColors.textHint,
      ), // Inter_400_11
    );
  }
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background, // #F8FAFC
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.textPrimary,
        onError: AppColors.white,
      ),
      textTheme: AppTypography.getTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 20.0,
          color: AppColors.textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 16.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.greyLight,
        hintStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w400,
          fontSize: 14.0,
          color: AppColors.textHint,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
      ),
    );
  }

  static TextTheme getDarkTextTheme() {
    const Color onSurface = AppColors.white;
    const Color onSurfaceVariant = Color(0xFFBBBBBB);
    const Color onSurfaceDim = Color(0xFF999999);

    return const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w700,
        fontSize: 32.0,
        color: onSurface,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w700,
        fontSize: 24.0,
        color: onSurface,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        fontSize: 24.0,
        color: onSurface,
      ),

      headlineLarge: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        fontSize: 20.0,
        color: onSurface,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
        fontSize: 20.0,
        color: onSurface,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        fontSize: 18.0,
        color: onSurface,
      ),

      titleLarge: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        fontSize: 17.0,
        color: onSurface,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        fontSize: 16.0,
        color: onSurface,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w500,
        fontSize: 16.0,
        color: onSurface,
      ),

      bodyLarge: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        fontSize: 16.0,
        color: onSurfaceVariant,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w400,
        fontSize: 14.0,
        color: onSurfaceVariant,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        fontSize: 12.0,
        color: onSurfaceDim,
      ),

      labelLarge: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
        fontSize: 14.0,
        color: onSurfaceVariant,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
        fontSize: 12.0,
        color: onSurfaceDim,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        fontSize: 11.0,
        color: onSurfaceDim,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: Color(0xFF1E1E1E),
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.white,
        onError: AppColors.white,
      ),
      textTheme: getDarkTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.white),
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 20.0,
          color: AppColors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        hintStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14.0,
          color: AppColors.greyMedium,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1),
        ),
      ),
    );
  }
}
