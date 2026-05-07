import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color leafGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF81C784);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundGray = Color(0xFFF5F5F5);
  static const Color cardBackground = Color(0xFFF9FBF9);
  static const Color textPrimary = Color(0xFF1A2E1A);
  static const Color textSecondary = Color(0xFF6B7B6B);
  static const Color inStock = Color(0xFF4CAF50);
  static const Color lowStock = Color(0xFFFFA726);
  static const Color outOfStock = Color(0xFFEF5350);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: backgroundGray,
      fontFamily: GoogleFonts.inter().fontFamily,
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        secondary: leafGreen,
        surface: backgroundLight,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: primaryGreen),
        titleTextStyle: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: backgroundLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
        ),
      ),
    );
  }
}
