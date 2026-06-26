import 'package:flutter/material.dart';
import 'package:ags_gold/core/theme/app_theme.dart';

/// Dark consumer-facing palette used on the AURUM user dashboard and KYC flow.
class AurumConsumerTheme {
  static const Color background = Color(0xFF0B1118);
  static const Color surface = Color(0xFF141C27);
  static const Color surfaceElevated = Color(0xFF1A2432);
  static const Color border = Color(0xFF273244);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color liveGreen = Color(0xFF22C55E);
  static const Color chipGold = Color(0xFF9A7B2F);

  static ThemeData theme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: AppTheme.primaryGold,
        onPrimary: Color(0xFF1A1200),
        surface: surface,
        onSurface: textPrimary,
        outline: border,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
      cardColor: surface,
      dividerColor: border,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        hintStyle: const TextStyle(color: textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primaryGold, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.primaryGold,
          foregroundColor: const Color(0xFF1A1200),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: Color(0xFF60A5FA),
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  static BoxDecoration cardDecoration({Color? color}) {
    return BoxDecoration(
      color: color ?? surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: border),
    );
  }
}
