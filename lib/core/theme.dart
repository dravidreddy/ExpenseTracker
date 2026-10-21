// lib/core/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Palette ───────────────────────────────────────────────────────────────
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF141414);
  static const Color surfaceVariant = Color(0xFF1E1E1E);
  static const Color border = Color(0xFF2A2A2A);
  static const Color onSurface = Color(0xFFF5F5F5);
  static const Color onSurfaceMuted = Color(0xFF6B7280);
  static const Color accent = Color(0xFFE8E8E8);

  // ── Typography ────────────────────────────────────────────────────────────
  static TextTheme _buildTextTheme() => GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        // Hero amount
        displayLarge: GoogleFonts.outfit(
          fontSize: 64,
          fontWeight: FontWeight.w300,
          color: onSurface,
          letterSpacing: -2,
        ),
        // Monthly total headline
        displayMedium: GoogleFonts.outfit(
          fontSize: 40,
          fontWeight: FontWeight.w300,
          color: onSurface,
          letterSpacing: -1.5,
        ),
        // Section headings
        headlineLarge: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.w500,
          color: onSurface,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w400,
          color: onSurface,
        ),
        // List item primary
        titleLarge: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: onSurface,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: onSurface,
        ),
        // Body & captions
        bodyLarge: GoogleFonts.outfit(
          fontSize: 16,
          color: onSurface,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14,
          color: onSurfaceMuted,
        ),
        bodySmall: GoogleFonts.outfit(
          fontSize: 12,
          color: onSurfaceMuted,
          letterSpacing: 0.4,
        ),
        labelLarge: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: onSurface,
          letterSpacing: 0.5,
        ),
      );

  // ── Theme Data ────────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          surface: surface,
          onSurface: onSurface,
          primary: accent,
          onPrimary: background,
          secondary: onSurfaceMuted,
          outline: border,
        ),
        textTheme: _buildTextTheme(),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceVariant,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: border, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: border, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: accent, width: 1.5),
          ),
          hintStyle: GoogleFonts.outfit(
            fontSize: 16,
            color: onSurfaceMuted,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: border,
          thickness: 1,
          space: 1,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: background,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: onSurface,
          ),
          iconTheme: const IconThemeData(color: onSurface),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: surface,
          selectedItemColor: onSurface,
          unselectedItemColor: onSurfaceMuted,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
      );
}
