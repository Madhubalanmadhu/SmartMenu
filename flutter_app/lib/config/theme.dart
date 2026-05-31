import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(0xFF0F0F0F);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceLow = Color(0xFF151515);
  static const Color surfaceHigh = Color(0xFF2D2D2D);
  static const Color surfaceHighest = Color(0xFF3A332E);
  static const Color primary = Color(0xFFFF8C00);
  static const Color primarySoft = Color(0xFFFFB77D);
  static const Color onPrimary = Color(0xFF221000);
  static const Color textPrimary = Color(0xFFF3DFD1);
  static const Color textMuted = Color(0xFFDDC1AE);
  static const Color outline = Color(0x1AFFFFFF);
  static const Color outlineStrong = Color(0x33FFFFFF);
  static const Color successColor = Color(0xFF2ED47A);
  static const Color warningColor = Color(0xFFFFB020);
  static const Color errorColor = Color(0xFFFF6B5F);

  static const Color primaryDarkBrown = background;
  static const Color secondaryDarkBrown = surface;
  static const Color accentBrown = surfaceHigh;
  static const Color accentGold = primary;
  static const Color primaryColor = primary;
  static const Color accentColor = primary;

  static final ColorScheme _scheme = const ColorScheme.dark(
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primary,
    onPrimaryContainer: onPrimary,
    secondary: primarySoft,
    onSecondary: background,
    error: errorColor,
    onError: background,
    errorContainer: Color(0xFF421612),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: surface,
    onSurface: textPrimary,
    surfaceContainerLowest: background,
    surfaceContainerLow: surfaceLow,
    surfaceContainer: surface,
    surfaceContainerHigh: surfaceHigh,
    surfaceContainerHighest: surfaceHighest,
    onSurfaceVariant: textMuted,
    outline: outlineStrong,
  );

  static final ThemeData lightTheme = _buildTheme();
  static final ThemeData darkTheme = _buildTheme();

  static ThemeData _buildTheme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: _scheme,
      scaffoldBackgroundColor: background,
    );

    final inter = GoogleFonts.interTextTheme(
      base.textTheme,
    ).apply(bodyColor: textPrimary, displayColor: textPrimary);

    final textTheme = inter.copyWith(
      displayLarge: GoogleFonts.hankenGrotesk(
        fontSize: 34,
        height: 1.15,
        fontWeight: FontWeight.w800,
        color: textPrimary,
      ),
      headlineLarge: GoogleFonts.hankenGrotesk(
        fontSize: 32,
        height: 1.2,
        fontWeight: FontWeight.w800,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.hankenGrotesk(
        fontSize: 25,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      headlineSmall: GoogleFonts.hankenGrotesk(
        fontSize: 20,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        height: 1.45,
        color: textPrimary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        height: 1.35,
        color: textMuted,
      ),
      labelSmall: GoogleFonts.robotoMono(
        fontSize: 11,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: textMuted,
      ),
      labelLarge: GoogleFonts.robotoMono(
        fontSize: 13,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: textPrimary,
      ),
    );

    return base.copyWith(
      primaryColor: primary,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: surface,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.hankenGrotesk(
          color: primary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: outline),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        selectedLabelStyle: GoogleFonts.robotoMono(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.robotoMono(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: surfaceHigh,
          disabledForegroundColor: textMuted,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: outlineStrong),
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 0,
        shape: CircleBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        labelStyle: const TextStyle(color: textMuted),
        hintStyle: TextStyle(color: textMuted.withValues(alpha: 0.55)),
        prefixIconColor: textMuted,
        suffixIconColor: textMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: outline),
        ),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),
      dividerTheme: const DividerThemeData(color: outline, thickness: 1),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: textTheme.labelSmall?.copyWith(color: primary),
        dataTextStyle: textTheme.bodyMedium,
        dividerThickness: 0.5,
        decoration: BoxDecoration(
          border: Border.all(color: outline),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: textPrimary,
        contentTextStyle: GoogleFonts.inter(
          color: background,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
    );
  }
}
