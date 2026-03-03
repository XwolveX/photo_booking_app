// lib/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Color Palette ──────────────────────────────────────────
  static const Color primary = Color(0xFF1A1A2E);       // Navy đậm
  static const Color secondary = Color(0xFFE94560);     // Đỏ hồng nổi bật
  static const Color accent = Color(0xFFFFD700);        // Vàng gold
  static const Color surface = Color(0xFF16213E);       // Navy trung
  static const Color cardBg = Color(0xFF0F3460);        // Navy nhạt
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B8C4);
  static const Color inputFill = Color(0xFF1E2A4A);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFFF5252);
  // ── Color Palette (Light - Hồng Pastel mới) ──────────────────
  static const Color lightBg = Color(0xFFFFF5F7);        // Hồng cực nhạt (nền)
  static const Color pinkPrimary = Color(0xFFFFB7C5);    // Hồng Pastel chính
  static const Color pinkAccent = Color(0xFFFF8E9E);     // Hồng đậm hơn chút (nhấn)
  static const Color lightSurface = Color(0xFFFFFFFF);   // Trắng thuần
  static const Color lightTextPrimary = Color(0xFF4A4A4A); // Xám đậm
  static const Color lightTextSecondary = Color(0xFF8E8E8E); // Xám nhạt
  static const Color lightInputFill = Color(0xFFFDEEF1);  // Hồng nhạt (input)
  // Role Colors
  static const Color roleUser = Color(0xFF4FC3F7);       // Xanh dương nhạt
  static const Color rolePhotographer = Color(0xFFE94560); // Đỏ hồng
  static const Color roleMakeuper = Color(0xFFCE93D8);    // Tím nhạt

  // ── Light Theme Configuration ───────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      colorScheme: const ColorScheme.light(
        primary: pinkPrimary,
        secondary: pinkAccent,
        surface: lightSurface,
        onPrimary: Colors.white,
        onSurface: lightTextPrimary,
        error: error,
      ),
      textTheme: GoogleFonts.beVietnamProTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.w700),
          displayMedium: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.w700),
          headlineLarge: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: lightTextPrimary),
          bodyMedium: TextStyle(color: lightTextSecondary),
          labelLarge: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightInputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: pinkPrimary.withOpacity(0.3), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: pinkAccent, width: 1.5),
        ),
        labelStyle: const TextStyle(color: lightTextSecondary),
        hintStyle: TextStyle(color: lightTextSecondary.withOpacity(0.6)),
        prefixIconColor: pinkAccent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: pinkAccent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          shadowColor: pinkAccent.withOpacity(0.3),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: secondary,
        secondary: accent,
        surface: surface,
        error: error,
      ),
      textTheme: GoogleFonts.beVietnamProTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
          displayMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
          headlineLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: Color(0xFF1A1A1A)),
          bodyMedium: TextStyle(color: Color(0xFF4A4A4A)),
          labelLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2D3F6B), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: secondary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: Color(0xFF6B7A99)),
        prefixIconColor: textSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
