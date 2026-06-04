import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/preferences_service.dart';

const _gold = Color(0xFFD4AF37);
const _darkBg = Color(0xFF0B0F1A);
const _darkSurface = Color(0xFF161B26);
const _success = Color(0xFF22C55E);
const _loss = Color(0xFFEF4444);

final themeModeProvider = StateNotifierProvider<ThemeModeController, ThemeMode>(
  (ref) => ThemeModeController(ref.watch(preferencesServiceProvider)),
);

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController(this._preferences) : super(_preferences.getThemeMode());

  final PreferencesService _preferences;

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await _preferences.setThemeMode(mode);
  }
}

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: _gold,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(
        primary: _gold,
        error: _loss,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: _gold,
      brightness: Brightness.dark,
      surface: _darkSurface,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(
        primary: _gold,
        surface: _darkSurface,
        error: _loss,
      ),
      scaffoldBackgroundColor: _darkBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkBg,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: _darkSurface,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: _darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }
}

extension ColorSchemeExtension on ColorScheme {
  Color get success => _success;
  Color get loss => _loss;
}

