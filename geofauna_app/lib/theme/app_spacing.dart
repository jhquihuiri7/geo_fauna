/// Spacing and corner-radius tokens of the "Organic Archive" design system.
///
/// The scale is not a rounded-off ladder: it keeps the values the screens
/// already use, including the half steps (14, 18) that pad fields and rows.
/// Every value is a `double` so it drops straight into `EdgeInsets`,
/// `SizedBox` and `BorderRadius.circular` without losing `const`.
class AppSpacing {
  AppSpacing._();

  // ── Spacing ────────────────────────────────────────────────────────────────

  /// 4 — icon-to-text gap, Kicker indent.
  static const double space1 = 4;

  /// 8 — small chip padding, gaps between chips.
  static const double space2 = 8;

  /// 12 — EcoTopBar top padding, title-to-subtitle gap.
  static const double space3 = 12;

  /// 14 — vertical padding of fields and rows.
  static const double space3_5 = 14;

  /// 16 — Cap indent, padding of compact cards.
  static const double space4 = 16;

  /// 18 — horizontal padding of text fields and list rows.
  static const double space4_5 = 18;

  /// 20 — screen side margin and EcoCard's default padding.
  static const double space5 = 20;

  /// 24 — GradientPanel and login-card padding.
  static const double space6 = 24;

  /// 28 — padding of large hero panels.
  static const double space7 = 28;

  /// 40 — gap between the brand mark and the card on login.
  static const double space10 = 40;

  // ── Radii ──────────────────────────────────────────────────────────────────

  /// 14 — small icon containers and thumbnails.
  static const double radiusSm = 14;

  /// 18 — inner cards, category tiles.
  static const double radiusMd = 18;

  /// 24 — medium cards, embedded maps, sheets.
  static const double radiusLg = 24;

  /// 26 — the 76px logo container on login.
  static const double radiusLogo = 26;

  /// 28 — EcoTopBar's bottom edge and wall panels.
  static const double radiusXl = 28;

  /// 32 — default radius of EcoCard and GradientPanel.
  static const double radiusCard = 32;

  /// 999 — every control is a pill: buttons, fields, chips, avatars, switches.
  static const double radiusFull = 999;
}
