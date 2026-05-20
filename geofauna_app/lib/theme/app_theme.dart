import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Global light/dark switch. The Settings screen flips this and the whole app
/// rebuilds via the [ValueListenableBuilder] in `main.dart`.
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier<ThemeMode>(ThemeMode.light);

class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(AppColors.light, Brightness.light);
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors eco, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: eco.primary,
      onPrimary: eco.onPrimary,
      primaryContainer: eco.primaryContainer,
      onPrimaryContainer: eco.onPrimaryContainer,
      secondary: eco.secondary,
      onSecondary: eco.onSecondary,
      secondaryContainer: eco.secondaryContainer,
      onSecondaryContainer: eco.onSecondaryContainer,
      tertiary: eco.tertiary,
      onTertiary: eco.onTertiary,
      tertiaryContainer: eco.tertiaryContainer,
      onTertiaryContainer: eco.onTertiaryContainer,
      error: eco.error,
      onError: eco.onError,
      errorContainer: eco.errorContainer,
      onErrorContainer: eco.onErrorContainer,
      surface: eco.surface,
      onSurface: eco.onSurface,
      onSurfaceVariant: eco.onSurfaceVariant,
      outline: eco.outline,
      outlineVariant: eco.outlineVariant,
      surfaceContainerLowest: eco.surfaceContainerLowest,
      surfaceContainerLow: eco.surfaceContainerLow,
      surfaceContainer: eco.surfaceContainer,
      surfaceContainerHigh: eco.surfaceContainerHigh,
      surfaceContainerHighest: eco.surfaceContainerHighest,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: eco.surface,
      // Inter is the editorial typeface in the design; fall back to the
      // platform sans (Roboto/SF) when the bundled font isn't present.
      fontFamily: 'Inter',
      fontFamilyFallback: const ['Roboto', 'SF Pro Text', 'system-ui'],
      extensions: <ThemeExtension<dynamic>>[eco],
      splashFactory: InkRipple.splashFactory,
      textTheme: Typography.material2021(platform: TargetPlatform.android)
          .black
          .apply(
            bodyColor: eco.onSurface,
            displayColor: eco.onSurface,
            fontFamily: 'Inter',
          ),
    );
  }
}
