import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors - Ultra Modern Electric Indigo & Neon Cyan
  static const Color primary = Color(0xFF4F46E5); // Electric Indigo
  static const Color primaryLight = Color(0xFF6366F1); // Indigo Accent
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color cyanAccent = Color(0xFF06B6D4); // Neon Cyan
  static const Color secondary = Color(0xFF0EA5E9); // Electric Sky
  static const Color accent = Color(0xFFF59E0B); // Amber Glow

  // Attendance Status Colors
  static const Color present = Color(0xFF10B981); // Emerald
  static const Color absent = Color(0xFFF43F5E); // Rose Coral
  static const Color leave = Color(0xFF8B5CF6); // Royal Violet
  static const Color unmarked = Color(0xFF64748B); // Slate

  // Background Colors
  static const Color darkScaffold = Color(0xFF090D16); // Deep Cyber Midnight
  static const Color darkCard = Color(0xFF121A2B); // Midnight Slate
  static const Color darkCardHigh = Color(0xFF19243C);
  static const Color darkBorder = Color(0xFF1E2D4A);

  static const Color lightScaffold = Color(0xFFF5F7FC); // Soft Crisp Slate
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardHigh = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF3B82F6), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient indigoPurpleGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF152037), Color(0xFF0D1424)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lightCardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient presentGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient absentGradient = LinearGradient(
    colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient amberGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glassmorphism Container Decoration Helper
  static BoxDecoration glassDecoration({
    required bool isDark,
    double borderRadius = 20,
    Color? borderColor,
    double borderWidth = 1.0,
    bool showShadow = true,
  }) {
    return BoxDecoration(
      gradient: isDark ? darkCardGradient : lightCardGradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ??
            (isDark
                ? darkBorder.withValues(alpha: 0.8)
                : lightBorder),
        width: borderWidth,
      ),
      boxShadow: showShadow
          ? [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.35)
                    : primary.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ]
          : null,
    );
  }

  // Glowing Pill Badge Decoration Helper
  static BoxDecoration pillDecoration({
    required Color color,
    double borderRadius = 10,
  }) {
    return BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
    );
  }

  // Light Theme Configuration
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE0E7FF),
      onPrimaryContainer: Color(0xFF312E81),
      secondary: cyanAccent,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFCFFAFE),
      onSecondaryContainer: Color(0xFF155E75),
      surface: lightCard,
      onSurface: Color(0xFF0F172A),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: Color(0xFFF8FAFC),
      surfaceContainer: Color(0xFFF1F5F9),
      surfaceContainerHigh: Color(0xFFE2E8F0),
      outline: lightBorder,
      error: Color(0xFFEF4444),
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: lightScaffold,
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
      displayLarge: GoogleFonts.outfit(
          fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
      displayMedium: GoogleFonts.outfit(
          fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
      headlineMedium: GoogleFonts.outfit(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A),
          letterSpacing: -0.5),
      headlineSmall: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A),
          letterSpacing: -0.3),
      titleLarge: GoogleFonts.outfit(
          fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
      titleMedium: GoogleFonts.inter(
          fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF334155)),
      bodyMedium:
          GoogleFonts.inter(fontSize: 14, color: const Color(0xFF475569)),
      labelLarge: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFF0F172A),
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: lightBorder, width: 1),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        side: const BorderSide(color: lightBorder, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      labelStyle: const TextStyle(color: Color(0xFF475569), fontSize: 14),
    ),
  );

  // Dark Theme Configuration - Ultra Sleek Glassmorphic Midnight
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF818CF8),
      onPrimary: Color(0xFF090D16),
      primaryContainer: Color(0xFF312E81),
      onPrimaryContainer: Color(0xFFE0E7FF),
      secondary: Color(0xFF22D3EE),
      onSecondary: Color(0xFF090D16),
      secondaryContainer: Color(0xFF164E63),
      onSecondaryContainer: Color(0xFFCFFAFE),
      surface: darkCard,
      onSurface: Color(0xFFF8FAFC),
      surfaceContainerLowest: Color(0xFF050811),
      surfaceContainerLow: darkScaffold,
      surfaceContainer: darkCard,
      surfaceContainerHigh: darkCardHigh,
      outline: darkBorder,
      error: Color(0xFFF87171),
      onError: Color(0xFF090D16),
    ),
    scaffoldBackgroundColor: darkScaffold,
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.outfit(
          fontWeight: FontWeight.w700, color: const Color(0xFFF8FAFC)),
      displayMedium: GoogleFonts.outfit(
          fontWeight: FontWeight.w700, color: const Color(0xFFF8FAFC)),
      headlineMedium: GoogleFonts.outfit(
          fontWeight: FontWeight.w700,
          color: const Color(0xFFF8FAFC),
          letterSpacing: -0.5),
      headlineSmall: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          color: const Color(0xFFF8FAFC),
          letterSpacing: -0.3),
      titleLarge: GoogleFonts.outfit(
          fontWeight: FontWeight.w600, color: const Color(0xFFF8FAFC)),
      titleMedium: GoogleFonts.inter(
          fontWeight: FontWeight.w600, color: const Color(0xFFE2E8F0)),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: const Color(0xFFCBD5E1)),
      bodyMedium:
          GoogleFonts.inter(fontSize: 14, color: const Color(0xFF94A3B8)),
      labelLarge: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFFF8FAFC),
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Color(0xFFF8FAFC),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: darkBorder, width: 1),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: primaryLight,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF818CF8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        side: const BorderSide(color: darkBorder, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF818CF8), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFF87171)),
      ),
      hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
      labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
    ),
  );
}
