import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'painters.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Avatar — monogram or emoji "specimen badge"
// ─────────────────────────────────────────────────────────────────────────────

enum AvatarTone { primary, emerald, blue, slate, sand, coral, forest, teal }

enum AvatarStatus { none, on, off }

class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    this.name,
    this.emoji,
    this.size = 40,
    this.tone = AvatarTone.primary,
    this.status = AvatarStatus.none,
  });

  final String? name;
  final String? emoji;
  final double size;
  final AvatarTone tone;
  final AvatarStatus status;

  static const Map<AvatarTone, List<Color>> _palette = {
    AvatarTone.primary: [Color(0xFF006948), Color(0xFF85F8C4)],
    AvatarTone.emerald: [Color(0xFF005137), Color(0xFF68DBA9)],
    AvatarTone.blue: [Color(0xFF00628D), Color(0xFFC9E6FF)],
    AvatarTone.slate: [Color(0xFF3A485C), Color(0xFFD5E3FD)],
    AvatarTone.sand: [Color(0xFF7A5A2E), Color(0xFFF3E0BD)],
    AvatarTone.coral: [Color(0xFFA33B2A), Color(0xFFFFD9CF)],
    AvatarTone.forest: [Color(0xFF2C4734), Color(0xFFA8D2B3)],
    AvatarTone.teal: [Color(0xFF005F5F), Color(0xFFA3E0E0)],
  };

  String get _initials {
    if (name == null || name!.isEmpty) return '';
    final parts = name!.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((w) => w[0]).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    final colors = _palette[tone]!;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors[0],
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white.withValues(alpha: 0.10), colors[0]],
                stops: const [0, 0.6],
              ),
            ),
            child: emoji != null
                ? Text(emoji!, style: TextStyle(fontSize: size * 0.55))
                : Text(
                    _initials,
                    style: TextStyle(
                      color: colors[1],
                      fontWeight: FontWeight.w800,
                      fontSize: size * 0.4,
                    ),
                  ),
          ),
          if (status != AvatarStatus.none)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: status == AvatarStatus.on
                      ? const Color(0xFF22C55E)
                      : const Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: eco.surfaceContainerLowest, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Photo placeholder — striped editorial block with monospace label + emoji
// ─────────────────────────────────────────────────────────────────────────────

class PhotoPlaceholder extends StatelessWidget {
  const PhotoPlaceholder({
    super.key,
    this.tone = 1,
    this.label = 'FIELD IMAGE',
    this.aspectRatio = 16 / 10,
    this.emoji,
    this.borderRadius = 0,
  });

  final int tone;
  final String label;
  final double aspectRatio;
  final String? emoji;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    final base = tone == 2 ? eco.photo2 : tone == 3 ? eco.photo3 : eco.photo1;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Container(
          color: base,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: StripePainter(eco.photoStripe)),
              if (emoji != null)
                Center(
                  child: Opacity(
                    opacity: 0.6,
                    child: Text(emoji!, style: const TextStyle(fontSize: 64)),
                  ),
                ),
              if (label.isNotEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        letterSpacing: 1.2,
                        color: eco.onSurface.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chip — pill tag
// ─────────────────────────────────────────────────────────────────────────────

enum ChipTone { primary, tertiary, emerald, slate, error, warning }

class EcoChip extends StatelessWidget {
  const EcoChip(this.label, {super.key, this.tone = ChipTone.primary, this.small = false});

  final String label;
  final ChipTone tone;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    late Color bg;
    late Color fg;
    switch (tone) {
      case ChipTone.primary:
        bg = eco.primary.withValues(alpha: 0.12);
        fg = eco.primary;
        break;
      case ChipTone.tertiary:
        bg = eco.tertiary.withValues(alpha: 0.12);
        fg = eco.tertiary;
        break;
      case ChipTone.emerald:
        bg = eco.primaryFixedDim.withValues(alpha: 0.22);
        fg = eco.primary;
        break;
      case ChipTone.slate:
        bg = eco.surfaceContainer;
        fg = eco.onSurfaceVariant;
        break;
      case ChipTone.error:
        bg = eco.errorContainer;
        fg = eco.onErrorContainer;
        break;
      case ChipTone.warning:
        bg = eco.warning.withValues(alpha: 0.18);
        fg = eco.warning;
        break;
    }
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: small ? 8 : 10, vertical: small ? 3 : 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontSize: small ? 9 : 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kicker — section header
// ─────────────────────────────────────────────────────────────────────────────

class Kicker extends StatelessWidget {
  const Kicker(this.title, {super.key, this.action});
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.3,
              color: context.eco.onSurfaceVariant,
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// Tiny uppercase caption used above form fields (`Cap`).
class Cap extends StatelessWidget {
  const Cap(this.label, {super.key, this.action});
  final String label;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: context.eco.outline,
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glass — frosted translucent surface (top bar / bottom nav / overlays)
// ─────────────────────────────────────────────────────────────────────────────

class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.zero;
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          color: context.eco.glass,
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TopBar — in-app glass header
// ─────────────────────────────────────────────────────────────────────────────

class EcoTopBar extends StatelessWidget {
  const EcoTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.large = false,
  });

  final String title;
  final Widget? subtitle;
  final Widget? leading;
  final List<Widget>? trailing;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return Glass(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: large ? 20 : 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: eco.onSurface,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: DefaultTextStyle.merge(
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: eco.onSurfaceVariant,
                      ),
                      child: subtitle!,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[
            for (final w in trailing!) ...[w, const SizedBox(width: 8)],
          ],
        ],
      ),
    );
  }
}

/// Plain back-style header used on Settings / Integridad / Reporte.
class SubHeader extends StatelessWidget {
  const SubHeader({
    super.key,
    required this.title,
    this.onBack,
    this.leadingIcon = Icons.arrow_back,
    this.trailing,
  });

  final String title;
  final VoidCallback? onBack;
  final IconData leadingIcon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return Container(
      color: eco.surface,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(leadingIcon, color: eco.primary),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: eco.primary,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Segmented tabs (Monitoreo / Agenda / Evento)
// ─────────────────────────────────────────────────────────────────────────────

class SegTabs extends StatelessWidget {
  const SegTabs({
    super.key,
    required this.tabs,
    required this.active,
    required this.onChange,
  });

  final List<String> tabs;
  final String active;
  final ValueChanged<String> onChange;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: eco.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (final t in tabs)
            Expanded(
              child: GestureDetector(
                onTap: () => onChange(t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: active == t
                        ? eco.surfaceContainerLowest
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: active == t
                        ? [
                            BoxShadow(
                              color: eco.primary.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Text(
                    t,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: active == t ? eco.primary : eco.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Switch
// ─────────────────────────────────────────────────────────────────────────────

class EcoSwitch extends StatelessWidget {
  const EcoSwitch({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? eco.primary : eco.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: value ? Colors.white : eco.surfaceContainerLowest,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(color: Color(0x26000000), blurRadius: 3, offset: Offset(0, 1)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings list row
// ─────────────────────────────────────────────────────────────────────────────

class EcoListRow extends StatelessWidget {
  const EcoListRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.iconBg,
    this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? iconBg;
  final Color? iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconBg ?? eco.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor ?? eco.primary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: eco.onSurface,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: eco.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pill text field
// ─────────────────────────────────────────────────────────────────────────────

class EcoTextField extends StatelessWidget {
  const EcoTextField({
    super.key,
    this.icon,
    this.hint,
    this.controller,
    this.obscure = false,
    this.keyboardType,
    this.trailing,
  });

  final IconData? icon;
  final String? hint;
  final TextEditingController? controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: eco.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      padding: EdgeInsets.only(left: icon != null ? 18 : 20, right: 16),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: eco.outline, size: 20),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              keyboardType: keyboardType,
              style: TextStyle(fontSize: 15, color: eco.onSurface),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(color: eco.outline, fontSize: 15),
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cards & gradient helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Standard elevated content card (`.bg-sc-lowest .shadow-card`).
class EcoCard extends StatelessWidget {
  const EcoCard({
    super.key,
    required this.child,
    this.radius = 32,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.soft = false,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final bool soft;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? eco.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: dark
                ? Colors.black.withValues(alpha: soft ? 0.5 : 0.45)
                : eco.primary.withValues(alpha: soft ? 0.05 : 0.04),
            blurRadius: soft ? 45 : 24,
            offset: Offset(0, soft ? 12 : 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Emerald gradient panel with optional dotted overlay (`.organic-gradient`).
class GradientPanel extends StatelessWidget {
  const GradientPanel({
    super.key,
    required this.child,
    this.radius = 32,
    this.padding = const EdgeInsets.all(24),
    this.dots = false,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final bool dots;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: eco.organicGradient),
        child: Stack(
          children: [
            if (dots)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.4,
                  child: CustomPaint(
                    painter: DotPatternPainter(
                        Colors.white.withValues(alpha: 0.18)),
                  ),
                ),
              ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

/// Full-width emerald gradient pill button used as the primary CTA.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.trailingIcon,
    this.onPressed,
    this.height = 56,
    this.loading = false,
  });

  final String label;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback? onPressed;
  final double height;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return GestureDetector(
      onTap: loading ? null : onPressed,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: eco.organicGradient,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF006948).withValues(alpha: 0.30),
              blurRadius: 25,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: 8),
                      Icon(trailingIcon, color: Colors.white, size: 20),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

/// Circular icon button on a soft surface (top-bar actions etc.).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 40,
    this.bg,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? bg;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg ?? eco.surfaceContainerLowest,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor ?? eco.primary, size: 22),
      ),
    );
  }
}
