import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return PreferencesService(AppBootstrapCache.preferences);
});

class AppBootstrapCache {
  static late SharedPreferences preferences;
}

class PreferencesService {
  PreferencesService(this._preferences);

  final SharedPreferences _preferences;

  static const _themeKey = 'theme_mode';
  static const _permissionsKey = 'permissions';
  static const _rememberMeKey = 'remember_me';

  ThemeMode getThemeMode() {
    final value = _preferences.getString(_themeKey);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) {
    return _preferences.setString(_themeKey, mode.name);
  }

  List<String> getPermissions() {
    final raw = _preferences.getString(_permissionsKey);
    if (raw == null) return const [];
    return (jsonDecode(raw) as List<dynamic>).cast<String>();
  }

  Future<void> setPermissions(List<String> permissions) {
    return _preferences.setString(_permissionsKey, jsonEncode(permissions));
  }

  bool getRememberMe() => _preferences.getBool(_rememberMeKey) ?? false;

  Future<void> setRememberMe(bool value) {
    return _preferences.setBool(_rememberMeKey, value);
  }
}
