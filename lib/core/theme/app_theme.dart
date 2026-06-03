import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/preferences_service.dart';

const _gold = Color(0xFFD4AF37);
const _darkSurface = Color(0xFF11100D);

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
      colorScheme: scheme.copyWith(primary: _gold),
      appBarTheme: const AppBarTheme(centerTitle: false),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
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
      colorScheme: scheme.copyWith(primary: _gold, surface: _darkSurface),
      scaffoldBackgroundColor: const Color(0xFF090907),
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkSurface,
        centerTitle: false,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Color(0xFF171510),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
    );
  }
}
