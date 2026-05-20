import 'package:flutter/material.dart';

/// The "Organic Archive" design tokens, ported 1:1 from `theme.css`.
///
/// Exposed as a [ThemeExtension] so every widget can read the full Material 3
/// surface hierarchy plus the project-specific tokens (photo tones, glass,
/// warning/success) via `Theme.of(context).extension<AppColors>()!` — or the
/// shorthand `context.eco`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.surface,
    required this.surfaceBright,
    required this.surfaceDim,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.primaryFixed,
    required this.primaryFixedDim,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.warning,
    required this.warningContainer,
    required this.success,
    required this.glass,
    required this.photo1,
    required this.photo2,
    required this.photo3,
    required this.photoStripe,
  });

  final Color bg;
  final Color surface;
  final Color surfaceBright;
  final Color surfaceDim;
  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color primaryFixed;
  final Color primaryFixedDim;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color tertiary;
  final Color onTertiary;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;
  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color warning;
  final Color warningContainer;
  final Color success;
  final Color glass;
  final Color photo1;
  final Color photo2;
  final Color photo3;
  final Color photoStripe;

  /// 135° emerald gradient used on CTAs and hero banners (`.organic-gradient`).
  LinearGradient get organicGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, primaryContainer],
      );

  static const AppColors light = AppColors(
    bg: Color(0xFFF0F4F2),
    surface: Color(0xFFF7F9FB),
    surfaceBright: Color(0xFFF7F9FB),
    surfaceDim: Color(0xFFD8DADC),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF2F4F6),
    surfaceContainer: Color(0xFFECEEF0),
    surfaceContainerHigh: Color(0xFFE6E8EA),
    surfaceContainerHighest: Color(0xFFE0E3E5),
    onSurface: Color(0xFF191C1E),
    onSurfaceVariant: Color(0xFF3D4A42),
    outline: Color(0xFF6D7A72),
    outlineVariant: Color(0xFFBCCAC0),
    primary: Color(0xFF006948),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF00855D),
    onPrimaryContainer: Color(0xFFF5FFF7),
    primaryFixed: Color(0xFF85F8C4),
    primaryFixedDim: Color(0xFF68DBA9),
    secondary: Color(0xFF515F74),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFD5E3FD),
    onSecondaryContainer: Color(0xFF3A485C),
    tertiary: Color(0xFF00628D),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFC9E6FF),
    onTertiaryContainer: Color(0xFF004C6E),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF93000A),
    warning: Color(0xFFD97706),
    warningContainer: Color(0xFFFDE7C2),
    success: Color(0xFF00855D),
    glass: Color(0xC7F7F9FB), // rgba(247,249,251,0.78)
    photo1: Color(0xFFB6C8BE),
    photo2: Color(0xFFA3BDCB),
    photo3: Color(0xFFC9D3C2),
    photoStripe: Color(0x0A000000), // rgba(0,0,0,0.04)
  );

  static const AppColors dark = AppColors(
    bg: Color(0xFF0A0F0C),
    surface: Color(0xFF0F1411),
    surfaceBright: Color(0xFF353A38),
    surfaceDim: Color(0xFF0A0E0C),
    surfaceContainerLowest: Color(0xFF0A0E0C),
    surfaceContainerLow: Color(0xFF161A18),
    surfaceContainer: Color(0xFF1C201E),
    surfaceContainerHigh: Color(0xFF262A28),
    surfaceContainerHighest: Color(0xFF313533),
    onSurface: Color(0xFFE2E4E2),
    onSurfaceVariant: Color(0xFFBCCAC0),
    outline: Color(0xFF869389),
    outlineVariant: Color(0xFF3D4A42),
    primary: Color(0xFF68DBA9),
    onPrimary: Color(0xFF00382A),
    primaryContainer: Color(0xFF005137),
    onPrimaryContainer: Color(0xFF85F8C4),
    primaryFixed: Color(0xFF85F8C4),
    primaryFixedDim: Color(0xFF68DBA9),
    secondary: Color(0xFFB9C7E0),
    onSecondary: Color(0xFF243345),
    secondaryContainer: Color(0xFF3A485C),
    onSecondaryContainer: Color(0xFFD5E3FD),
    tertiary: Color(0xFF89CEFF),
    onTertiary: Color(0xFF003351),
    tertiaryContainer: Color(0xFF004C6E),
    onTertiaryContainer: Color(0xFFC9E6FF),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    warning: Color(0xFFF59E0B),
    warningContainer: Color(0xFF4A3A0E),
    success: Color(0xFF68DBA9),
    glass: Color(0xC70F1411), // rgba(15,20,17,0.78)
    photo1: Color(0xFF2B3934),
    photo2: Color(0xFF2A3A44),
    photo3: Color(0xFF2E372C),
    photoStripe: Color(0x0AFFFFFF), // rgba(255,255,255,0.04)
  );

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceBright,
    Color? surfaceDim,
    Color? surfaceContainerLowest,
    Color? surfaceContainerLow,
    Color? surfaceContainer,
    Color? surfaceContainerHigh,
    Color? surfaceContainerHighest,
    Color? onSurface,
    Color? onSurfaceVariant,
    Color? outline,
    Color? outlineVariant,
    Color? primary,
    Color? onPrimary,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? primaryFixed,
    Color? primaryFixedDim,
    Color? secondary,
    Color? onSecondary,
    Color? secondaryContainer,
    Color? onSecondaryContainer,
    Color? tertiary,
    Color? onTertiary,
    Color? tertiaryContainer,
    Color? onTertiaryContainer,
    Color? error,
    Color? onError,
    Color? errorContainer,
    Color? onErrorContainer,
    Color? warning,
    Color? warningContainer,
    Color? success,
    Color? glass,
    Color? photo1,
    Color? photo2,
    Color? photo3,
    Color? photoStripe,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceBright: surfaceBright ?? this.surfaceBright,
      surfaceDim: surfaceDim ?? this.surfaceDim,
      surfaceContainerLowest:
          surfaceContainerLowest ?? this.surfaceContainerLowest,
      surfaceContainerLow: surfaceContainerLow ?? this.surfaceContainerLow,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
      surfaceContainerHighest:
          surfaceContainerHighest ?? this.surfaceContainerHighest,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
      outline: outline ?? this.outline,
      outlineVariant: outlineVariant ?? this.outlineVariant,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      primaryFixed: primaryFixed ?? this.primaryFixed,
      primaryFixedDim: primaryFixedDim ?? this.primaryFixedDim,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      secondaryContainer: secondaryContainer ?? this.secondaryContainer,
      onSecondaryContainer: onSecondaryContainer ?? this.onSecondaryContainer,
      tertiary: tertiary ?? this.tertiary,
      onTertiary: onTertiary ?? this.onTertiary,
      tertiaryContainer: tertiaryContainer ?? this.tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer ?? this.onTertiaryContainer,
      error: error ?? this.error,
      onError: onError ?? this.onError,
      errorContainer: errorContainer ?? this.errorContainer,
      onErrorContainer: onErrorContainer ?? this.onErrorContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      success: success ?? this.success,
      glass: glass ?? this.glass,
      photo1: photo1 ?? this.photo1,
      photo2: photo2 ?? this.photo2,
      photo3: photo3 ?? this.photo3,
      photoStripe: photoStripe ?? this.photoStripe,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      bg: c(bg, other.bg),
      surface: c(surface, other.surface),
      surfaceBright: c(surfaceBright, other.surfaceBright),
      surfaceDim: c(surfaceDim, other.surfaceDim),
      surfaceContainerLowest:
          c(surfaceContainerLowest, other.surfaceContainerLowest),
      surfaceContainerLow: c(surfaceContainerLow, other.surfaceContainerLow),
      surfaceContainer: c(surfaceContainer, other.surfaceContainer),
      surfaceContainerHigh: c(surfaceContainerHigh, other.surfaceContainerHigh),
      surfaceContainerHighest:
          c(surfaceContainerHighest, other.surfaceContainerHighest),
      onSurface: c(onSurface, other.onSurface),
      onSurfaceVariant: c(onSurfaceVariant, other.onSurfaceVariant),
      outline: c(outline, other.outline),
      outlineVariant: c(outlineVariant, other.outlineVariant),
      primary: c(primary, other.primary),
      onPrimary: c(onPrimary, other.onPrimary),
      primaryContainer: c(primaryContainer, other.primaryContainer),
      onPrimaryContainer: c(onPrimaryContainer, other.onPrimaryContainer),
      primaryFixed: c(primaryFixed, other.primaryFixed),
      primaryFixedDim: c(primaryFixedDim, other.primaryFixedDim),
      secondary: c(secondary, other.secondary),
      onSecondary: c(onSecondary, other.onSecondary),
      secondaryContainer: c(secondaryContainer, other.secondaryContainer),
      onSecondaryContainer: c(onSecondaryContainer, other.onSecondaryContainer),
      tertiary: c(tertiary, other.tertiary),
      onTertiary: c(onTertiary, other.onTertiary),
      tertiaryContainer: c(tertiaryContainer, other.tertiaryContainer),
      onTertiaryContainer: c(onTertiaryContainer, other.onTertiaryContainer),
      error: c(error, other.error),
      onError: c(onError, other.onError),
      errorContainer: c(errorContainer, other.errorContainer),
      onErrorContainer: c(onErrorContainer, other.onErrorContainer),
      warning: c(warning, other.warning),
      warningContainer: c(warningContainer, other.warningContainer),
      success: c(success, other.success),
      glass: c(glass, other.glass),
      photo1: c(photo1, other.photo1),
      photo2: c(photo2, other.photo2),
      photo3: c(photo3, other.photo3),
      photoStripe: c(photoStripe, other.photoStripe),
    );
  }
}

/// Convenience accessor: `context.eco.primary`.
extension AppColorsX on BuildContext {
  AppColors get eco => Theme.of(this).extension<AppColors>()!;
}
