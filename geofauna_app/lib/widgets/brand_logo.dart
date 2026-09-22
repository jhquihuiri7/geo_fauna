import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// EcoGuía brand mark — "Tortuga-Topo": a giant tortoise seen from above whose
/// shell is drawn as topographic contour lines. Painted natively (no SVG
/// dependency) from the 120×120 master in `assets/brand/tortuga-topo-simbolo.svg`.
class TortugaTopoMark extends StatelessWidget {
  const TortugaTopoMark({
    super.key,
    this.size = 48,
    this.limb,
    this.shell,
    this.ring,
    this.onFill = false,
  });

  /// Variant for use on the emerald organic gradient (white shell, mint limbs,
  /// emerald contour lines) — e.g. the login badge and app icon.
  const TortugaTopoMark.onFill({Key? key, double size = 48})
    : this(key: key, size: size, onFill: true);

  final double size;
  final Color? limb;
  final Color? shell;
  final Color? ring;
  final bool onFill;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    final painter = _TortugaTopoPainter(
      limb: limb ?? (onFill ? eco.primaryFixed : eco.primaryContainer),
      shell: shell ?? (onFill ? Colors.white : eco.primary),
      ring: ring ?? (onFill ? AppColors.light.primary : eco.primaryFixedDim),
    );
    return Semantics(
      label: 'EcoGuía',
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: painter),
      ),
    );
  }
}

class _TortugaTopoPainter extends CustomPainter {
  _TortugaTopoPainter({
    required this.limb,
    required this.shell,
    required this.ring,
  });
  final Color limb;
  final Color shell;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 120;
    canvas.save();
    canvas.scale(s);

    final limbP = Paint()
      ..color = limb
      ..isAntiAlias = true;
    final shellP = Paint()
      ..color = shell
      ..isAntiAlias = true;
    final ringP = Paint()
      ..color = ring
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..isAntiAlias = true;

    void oval(
      double cx,
      double cy,
      double rx,
      double ry,
      Paint p, [
      double deg = 0,
    ]) {
      canvas.save();
      canvas.translate(cx, cy);
      if (deg != 0) canvas.rotate(deg * 3.141592653589793 / 180);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
        p,
      );
      canvas.restore();
    }

    // Head, four legs, tail.
    oval(60, 18, 10, 11, limbP);
    oval(27, 38, 10, 8, limbP, -35);
    oval(93, 38, 10, 8, limbP, 35);
    oval(29, 88, 10, 8, limbP, 35);
    oval(91, 88, 10, 8, limbP, -35);
    canvas.drawPath(
      Path()
        ..moveTo(60, 104)
        ..lineTo(54, 112)
        ..lineTo(66, 112)
        ..close(),
      limbP,
    );

    // Shell + off-centre contour rings (the "peak" sits up-left).
    oval(60, 63, 38, 42, shellP);
    oval(57, 58, 28, 31, ringP);
    oval(55, 54, 18, 20, ringP);
    oval(54, 51, 8.5, 9.5, ringP);
    canvas.drawCircle(const Offset(54, 51), 3.2, Paint()..color = ring);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_TortugaTopoPainter old) =>
      old.limb != limb || old.shell != shell || old.ring != ring;
}
