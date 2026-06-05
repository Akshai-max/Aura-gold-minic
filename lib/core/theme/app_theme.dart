import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/preferences_service.dart';
import 'app_colors.dart';

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

  static ThemeData get light => _buildTheme(Brightness.light);

  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.royalGold,
      onPrimary: const Color(0xFF1A1408),
      secondary: AppColors.royalGoldDeep,
      onSecondary: Colors.white,
      surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      onSurface: isDark ? const Color(0xFFF2EFE8) : const Color(0xFF1C1E24),
      onSurfaceVariant:
          isDark ? AppColors.onDarkMuted : AppColors.onLightMuted,
      error: AppColors.loss,
      onError: Colors.white,
      outline: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      outlineVariant: AppColors.royalGold.withValues(alpha: 0.2),
    );

    final textTheme = _textTheme(brightness);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.darkBg : AppColors.lightBg,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.w400,
        ),
        iconTheme: IconThemeData(
          color: scheme.onSurface.withValues(alpha: 0.85),
        ),
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        indicatorColor: AppColors.royalGold.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelLarge?.copyWith(
            color: selected
                ? AppColors.royalGold
                : scheme.onSurface.withValues(alpha: 0.78),
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            letterSpacing: 0.2,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? AppColors.royalGold
                : scheme.onSurface.withValues(alpha: 0.65),
            size: 22,
          );
        }),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: AppColors.royalGold.withValues(alpha: isDark ? 0.14 : 0.2),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.royalGold.withValues(alpha: 0.12),
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? AppColors.darkBg.withValues(alpha: 0.55)
            : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(
          color: isDark ? AppColors.onDarkMuted : AppColors.onLightMuted,
          letterSpacing: 0.2,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.royalGold, width: 1.2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.royalGold,
          foregroundColor: const Color(0xFF1A1408),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.royalGold,
          side: BorderSide(
            color: AppColors.royalGold.withValues(alpha: 0.45),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.royalGold,
          textStyle: const TextStyle(letterSpacing: 0.3),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.royalGold;
          }
          return Colors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(Color(0xFF1A1408)),
        side: BorderSide(
          color: AppColors.royalGold.withValues(alpha: 0.5),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.royalGold.withValues(alpha: 0.85),
        textColor: scheme.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
        contentTextStyle: TextStyle(color: scheme.onSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.royalGold,
      ),
      extensions: [RoyalThemeExtension.forBrightness(brightness)],
    );
  }

  static TextTheme _textTheme(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    final primary =
        brightness == Brightness.dark ? Colors.white : const Color(0xFF1C1E24);
    final muted = brightness == Brightness.dark
        ? AppColors.onDarkMuted
        : AppColors.onLightMuted;

    return base.copyWith(
      headlineLarge: base.headlineLarge?.copyWith(
        color: primary,
        fontWeight: FontWeight.w300,
        letterSpacing: 0.5,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        color: primary,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.3,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        color: primary,
        fontWeight: FontWeight.w500,
      ),
      titleLarge: base.titleLarge?.copyWith(
        color: primary,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
      ),
      titleMedium: base.titleMedium?.copyWith(
        color: primary,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: base.bodyLarge?.copyWith(color: primary),
      bodyMedium: base.bodyMedium?.copyWith(color: muted),
      bodySmall: base.bodySmall?.copyWith(color: muted),
      labelLarge: base.labelLarge?.copyWith(letterSpacing: 0.5),
    );
  }
}

class RoyalThemeExtension extends ThemeExtension<RoyalThemeExtension> {
  const RoyalThemeExtension({
    required this.heroGradient,
    required this.surfaceAccent,
    required this.goldBorder,
  });

  final Gradient heroGradient;
  final Color surfaceAccent;
  final Color goldBorder;

  static RoyalThemeExtension forBrightness(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return RoyalThemeExtension(
      heroGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.royalGold.withValues(alpha: isDark ? 0.16 : 0.1),
          isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
        ],
      ),
      surfaceAccent: AppColors.royalGold.withValues(alpha: 0.08),
      goldBorder: AppColors.royalGold.withValues(alpha: isDark ? 0.2 : 0.26),
    );
  }

  @override
  RoyalThemeExtension copyWith({
    Gradient? heroGradient,
    Color? surfaceAccent,
    Color? goldBorder,
  }) {
    return RoyalThemeExtension(
      heroGradient: heroGradient ?? this.heroGradient,
      surfaceAccent: surfaceAccent ?? this.surfaceAccent,
      goldBorder: goldBorder ?? this.goldBorder,
    );
  }

  @override
  RoyalThemeExtension lerp(ThemeExtension<RoyalThemeExtension>? other, double t) {
    if (other is! RoyalThemeExtension) return this;
    return RoyalThemeExtension(
      heroGradient: heroGradient,
      surfaceAccent: Color.lerp(surfaceAccent, other.surfaceAccent, t)!,
      goldBorder: Color.lerp(goldBorder, other.goldBorder, t)!,
    );
  }
}

extension ColorSchemeExtension on ColorScheme {
  Color get success => AppColors.success;
  Color get loss => AppColors.loss;
}

extension RoyalThemeContext on BuildContext {
  RoyalThemeExtension get royalTheme =>
      Theme.of(this).extension<RoyalThemeExtension>()!;
}
