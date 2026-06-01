import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ─── Brand Colors (shared) ────────────────────────────────────────────────
  static const Color primary = Color(0xFFFF6B35);
  static const Color primaryDark = Color(0xFFCC5528);
  static const Color secondary = Color(0xFF2EC4B6);
  static const Color secondaryDark = Color(0xFF259C90);
  static const Color success = Color(0xFF30D158);
  static const Color warning = Color(0xFFFFD60A);
  static const Color error = Color(0xFFFF453A);

  // ─── Dark Palette ─────────────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0F0F0F);
  static const Color surfaceDark = Color(0xFF1C1C1E);
  static const Color cardDark = Color(0xFF252528);
  static const Color borderDark = Color(0xFF3A3A3C);
  static const Color textPrimary = Color(0xFFFAFAFA);
  static const Color textSecondary = Color(0xFF9A9A9E);
  static const Color textHint = Color(0xFF5A5A5E);

  // ─── Light Palette ────────────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF8F8FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE5E5EA);
  static const Color textPrimaryLight = Color(0xFF1C1C1E);
  static const Color textSecondaryLight = Color(0xFF6B6B70);
  static const Color textHintLight = Color(0xFFA0A0A5);

  // ─── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF252528), Color(0xFF1C1C1E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0x00000000), Color(0xE6000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Helpers ──────────────────────────────────────────────────────────────
  /// Gets adaptive colors based on brightness
  static Color bg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? backgroundDark
          : backgroundLight;
  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? surfaceDark
          : surfaceLight;
  static Color card(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? cardDark : cardLight;
  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? borderDark
          : borderLight;
  static Color textP(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? textPrimary
          : textPrimaryLight;
  static Color textS(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? textSecondary
          : textSecondaryLight;
  static Color textH(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? textHint
          : textHintLight;

  // ─── Dark Theme ───────────────────────────────────────────────────────────
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        surface: surfaceDark,
        onSurface: textPrimary,
        error: error,
        onError: Colors.white,
      ),
      textTheme: _buildTextTheme(Brightness.dark),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundDark,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderDark, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: _buildInputTheme(Brightness.dark),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      textButtonTheme: _buildTextButtonTheme(),
      chipTheme: ChipThemeData(
        backgroundColor: cardDark,
        selectedColor: primary.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.poppins(fontSize: 12, color: textSecondary),
        side: const BorderSide(color: borderDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: primary,
        unselectedItemColor: textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(color: borderDark, thickness: 0.5),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardDark,
        contentTextStyle: GoogleFonts.poppins(color: textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Light Theme ──────────────────────────────────────────────────────────
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        surface: surfaceLight,
        onSurface: textPrimaryLight,
        error: error,
        onError: Colors.white,
      ),
      textTheme: _buildTextTheme(Brightness.light),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundLight,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textPrimaryLight),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimaryLight,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: _buildInputTheme(Brightness.light),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      textButtonTheme: _buildTextButtonTheme(),
      chipTheme: ChipThemeData(
        backgroundColor: cardLight,
        selectedColor: primary.withValues(alpha: 0.15),
        labelStyle:
            GoogleFonts.poppins(fontSize: 12, color: textSecondaryLight),
        side: const BorderSide(color: borderLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceLight,
        selectedItemColor: primary,
        unselectedItemColor: textHintLight,
        type: BottomNavigationBarType.fixed,
        elevation: 2,
      ),
      dividerTheme: const DividerThemeData(color: borderLight, thickness: 0.5),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardLight,
        contentTextStyle:
            GoogleFonts.poppins(color: textPrimaryLight, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Shared Builders ──────────────────────────────────────────────────────
  static TextTheme _buildTextTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final tp = isDark ? textPrimary : textPrimaryLight;
    final ts = isDark ? textSecondary : textSecondaryLight;
    final th = isDark ? textHint : textHintLight;
    return GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge: GoogleFonts.poppins(
          fontSize: 32, fontWeight: FontWeight.w700, color: tp),
      displayMedium: GoogleFonts.poppins(
          fontSize: 28, fontWeight: FontWeight.w700, color: tp),
      headlineLarge: GoogleFonts.poppins(
          fontSize: 24, fontWeight: FontWeight.w600, color: tp),
      headlineMedium: GoogleFonts.poppins(
          fontSize: 20, fontWeight: FontWeight.w600, color: tp),
      headlineSmall: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w600, color: tp),
      titleLarge: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w600, color: tp),
      titleMedium: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w500, color: tp),
      bodyLarge: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w400, color: tp),
      bodyMedium: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w400, color: ts),
      bodySmall: GoogleFonts.poppins(
          fontSize: 12, fontWeight: FontWeight.w400, color: th),
      labelLarge: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w600, color: tp),
      labelMedium: GoogleFonts.poppins(
          fontSize: 12, fontWeight: FontWeight.w500, color: ts),
      labelSmall: GoogleFonts.poppins(
          fontSize: 11, fontWeight: FontWeight.w500, color: th),
    );
  }

  static InputDecorationTheme _buildInputTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final fill = isDark ? cardDark : cardLight;
    final hint = isDark ? textHint : textHintLight;
    final brd = isDark ? borderDark : borderLight;
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      hintStyle: GoogleFonts.poppins(color: hint, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: brd),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: brd),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme() =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle:
              GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      );

  static OutlinedButtonThemeData _buildOutlinedButtonTheme() =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle:
              GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      );

  static TextButtonThemeData _buildTextButtonTheme() => TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle:
              GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      );
}
