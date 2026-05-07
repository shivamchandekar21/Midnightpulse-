import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand color (Primary 600)
  static const Color primary = Color(0xFF5E35B1); // DeepPurple 600
  // Pressed state (Primary Variant 700)
  static const Color primaryVariant = Color(0xFF512DA8); // DeepPurple 700
  // Accent / CTA (Secondary 400) - Using Cyan for contrast
  static const Color secondary = Color(0xFF26C6DA); // Cyan 400
  
  // App background (Background 900)
  static const Color background = Color(0xFF311B92); // DeepPurple 900
  // Cards, containers (Surface 800)
  static const Color surface = Color(0xFF4527A0); // DeepPurple 800
  // Elevated containers (Surface Light 700)
  static const Color surfaceLight = Color(0xFF512DA8); // DeepPurple 700
  
  // Main text (Text Primary)
  static const Color textPrimary = Color(0xFFFFFFFF); // White
  // Sub text (Text Secondary 200)
  static const Color textSecondary = Color(0xFFB39DDB); // DeepPurple 200
  
  // Subtle lines (Border / Divider 300)
  static const Color border = Color(0xFF9575CD); // DeepPurple 300

  // Fallbacks for existing references
  static const Color accent = secondary;
  static const Color accentSoft = Color(0xFF80DEEA); // Cyan 300 - softer variant
  static const Color accentBright = Color(0xFF00E5FF); // Cyan 200 - brighter variant
  static const Color backgroundDeep = Color(0xFF1A237E); 
  static const Color surfaceAlt = surfaceLight;
  static const Color surfaceStrong = background;
  static const Color textMuted = border;
  static const Color violet = Color(0xFF9E81FF);
  static const Color success = Color(0xFF7CEBFF);
}

class AppGradients {
  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.backgroundDeep, AppColors.background],
  );

  static const LinearGradient primary = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.primary, AppColors.secondary],
  );

  static const LinearGradient panel = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.surfaceLight, AppColors.surface],
  );
}

class AppTheme {
  static ThemeData get themeData {
    final baseTheme = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.soraTextTheme(baseTheme.textTheme).copyWith(
      bodyMedium: GoogleFonts.sora(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      titleLarge: GoogleFonts.sora(
        color: AppColors.textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: GoogleFonts.sora(
        color: AppColors.textPrimary,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
    );

    return baseTheme.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.textPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.background,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceLight,
      ),
      textTheme: textTheme,
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      dividerColor: AppColors.border,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: GoogleFonts.sora(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.secondary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.background,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        contentTextStyle: GoogleFonts.sora(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          elevation: 4,
          shadowColor: AppColors.primaryVariant,
          minimumSize: const Size.fromHeight(58),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: GoogleFonts.sora(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.textSecondary; // Disabled background: 200
            }
            if (states.contains(WidgetState.pressed)) {
              return AppColors.primaryVariant; // Pressed: 700
            }
            return AppColors.primary; // Default: 600
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return const Color(0xFFD1C4E9); // Disabled text: 100
            }
            return AppColors.textPrimary;
          }),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: GoogleFonts.sora(
          color: AppColors.border, // Hint: 300
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.secondary),
        ),
      ),
    );
  }
}
