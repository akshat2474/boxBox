import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Core palette — F1 TV inspired
  static const Color bg = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF141414);
  static const Color surfaceElevated = Color(0xFF1E1E1E);
  static const Color border = Color(0xFF2A2A2A);
  static const Color f1Red = Color(0xFFE10600);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF888888);
  static const Color textMuted = Color(0xFF444444);

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      primaryColor: f1Red,
      colorScheme: const ColorScheme.dark(
        primary: f1Red,
        secondary: f1Red,
        surface: surface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.russoOne(
          color: textPrimary,
          fontSize: 20,
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.russoOne(color: textPrimary, fontSize: 40),
        displayMedium: GoogleFonts.russoOne(color: textPrimary, fontSize: 28),
        titleLarge: GoogleFonts.russoOne(color: textPrimary, fontSize: 20),
        titleMedium: GoogleFonts.russoOne(color: textPrimary, fontSize: 16),
        bodyLarge: GoogleFonts.inter(color: textPrimary, fontSize: 16),
        bodyMedium: GoogleFonts.inter(color: textSecondary, fontSize: 14),
        bodySmall: GoogleFonts.inter(color: textMuted, fontSize: 12),
      ),
      useMaterial3: true,
    );
  }
}

// Backward compat alias
class LiquidGlassTheme {
  static ThemeData get theme => AppTheme.theme;
}
