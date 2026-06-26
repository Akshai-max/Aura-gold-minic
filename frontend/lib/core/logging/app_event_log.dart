import 'package:flutter/foundation.dart';

/// Debug-only user journey logs: screens, taps, KYC, trading, etc.
/// Filter console with `[APP_EVENT]` (see run.ps1).
class AppEventLog {
  AppEventLog._();

  static bool enabled = kDebugMode;

  static void screen(
    String route, {
    String? from,
    Map<String, Object?>? data,
  }) {
    if (!enabled) return;
    _emit('SCREEN', route, from: from, data: data);
  }

  static void action(
    String name, {
    Map<String, Object?>? data,
  }) {
    if (!enabled) return;
    _emit('ACTION', name, data: data);
  }

  static void _emit(
    String type,
    String name, {
    String? from,
    Map<String, Object?>? data,
  }) {
    final time = DateTime.now().toIso8601String().substring(11, 23);
    final buffer = StringBuffer('[APP_EVENT] $time $type | $name');
    if (from != null && from.isNotEmpty) {
      buffer.write(' | from=$from');
    }
    if (data != null && data.isNotEmpty) {
      final pairs = data.entries
          .where((e) => e.value != null)
          .map((e) => '${e.key}=${e.value}')
          .join(', ');
      if (pairs.isNotEmpty) buffer.write(' | $pairs');
    }
    debugPrint(buffer.toString());
  }
}
