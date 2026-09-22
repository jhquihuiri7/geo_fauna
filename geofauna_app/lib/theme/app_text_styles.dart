import 'package:flutter/material.dart';

/// The "Organic Archive" type scale, ported 1:1 from the design system.
///
/// One family — Inter — with heavy weights (800/900) on titles and labels and
/// 400 reserved for running text. Sizes, line heights and tracking match the
/// published tokens exactly; `height` is the unitless ratio Flutter expects and
/// `letterSpacing` is in logical pixels.
///
/// The uppercase styles ([kicker], [cap], [eyebrow], [chip], [chipSmall]) carry
/// the tracking but not the casing: the caller uppercases the string, as the
/// Kicker/Cap/EcoChip widgets already do.
class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Inter';

  // ── Display ────────────────────────────────────────────────────────────────

  /// 40/900 — brand name on the login screen; once per screen.
  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 40,
    fontWeight: FontWeight.w900,
    height: 1.0,
    letterSpacing: -1.5,
  );

  /// 34/900 — sign-up screens and the "Nuevo" hub title.
  static const TextStyle headline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 34,
    fontWeight: FontWeight.w900,
    height: 1.05,
    letterSpacing: -1.2,
  );

  /// 22/900 — dashboard section titles and card headers.
  static const TextStyle titleLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w900,
    height: 1.1,
    letterSpacing: -0.5,
  );

  /// 20/900 — card titles and medium metrics.
  static const TextStyle titleMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w900,
  );

  // ── Text ───────────────────────────────────────────────────────────────────

  /// 16/800 — names in lists and row headings.
  static const TextStyle titleSm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w800,
  );

  /// 15/800 — GradientButton and pill-button labels.
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w800,
  );

  /// 14/400 — running text and descriptions.
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  /// 14/800 — emphasised text in rows and values.
  static const TextStyle bodyStrong = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w800,
  );

  /// 13/400 — metadata, footnotes and comments.
  static const TextStyle bodySm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );

  /// 12/800 — data labels and small statistics.
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w800,
  );

  // ── Uppercase labels ───────────────────────────────────────────────────────

  /// 11/800, tracking 1.3 — section kicker, UPPERCASE.
  static const TextStyle kicker = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.3,
  );

  /// 10/800, tracking 1.5 — caption above form fields, UPPERCASE.
  static const TextStyle cap = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.5,
  );

  /// 10/800, tracking 1.8 — eyebrow above titles and the brand line, UPPERCASE.
  static const TextStyle eyebrow = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.8,
  );

  /// 10/900, tracking 1.2 — EcoChip text, UPPERCASE.
  static const TextStyle chip = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.2,
  );

  /// The 9px variant of [chip] used by the small EcoChip.
  static const TextStyle chipSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 9,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.2,
  );

  /// The scale wired into Material's slots. Slots the design system does not
  /// name (`displayMedium`, `displaySmall`, `headlineMedium`, `headlineSmall`)
  /// reuse the nearest step so nothing falls back to Roboto's metrics; the
  /// uppercase labels have no Material slot and are used directly.
  ///
  /// Colours are applied by [AppTheme] with `TextTheme.apply`.
  static const TextTheme textTheme = TextTheme(
    displayLarge: display,
    displayMedium: headline,
    displaySmall: titleLg,
    headlineLarge: headline,
    headlineMedium: titleLg,
    headlineSmall: titleMd,
    titleLarge: titleLg,
    titleMedium: titleMd,
    titleSmall: titleSm,
    bodyLarge: bodyStrong,
    bodyMedium: body,
    bodySmall: bodySm,
    labelLarge: button,
    labelMedium: label,
    labelSmall: kicker,
  );
}
