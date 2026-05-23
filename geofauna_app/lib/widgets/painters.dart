import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Diagonal repeating stripes used inside photo placeholders (`.photo-ph`).
class StripePainter extends CustomPainter {
  StripePainter(this.stripe);
  final Color stripe;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = stripe
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;
    // 135° stripes, 14px band repeated every 28px.
    final diag = size.width + size.height;
    for (double d = -size.height; d < diag; d += 28) {
      canvas.drawLine(Offset(d, 0), Offset(d + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(StripePainter old) => old.stripe != stripe;
}

/// Decorative dotted overlay used on emerald hero panels (`.dot-pattern`).
class DotPatternPainter extends CustomPainter {
  DotPatternPainter(this.dot);
  final Color dot;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dot;
    const gap = 18.0;
    for (double y = gap / 2; y < size.height; y += gap) {
      for (double x = gap / 2; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), 1.1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(DotPatternPainter old) => old.dot != dot;
}

/// Pseudo-QR / specimen code block for the digital ID card (`.qr-art`).
class QrArtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final cell = size.width / 12;
    final rng = math.Random(8829);
    final paint = Paint()..color = const Color(0xD9000000);
    for (int r = 0; r < 12; r++) {
      for (int c = 0; c < 12; c++) {
        if (rng.nextBool()) {
          canvas.drawRect(
            Rect.fromLTWH(c * cell, r * cell, cell, cell),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(QrArtPainter old) => false;
}

/// Stylised offline topographic map background (`.topo-map`).
class TopoMap extends StatelessWidget {
  const TopoMap({
    super.key,
    this.borderRadius = 32,
    this.minHeight = 240,
    this.children = const [],
  });

  final double borderRadius;
  final double minHeight;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = dark ? const Color(0xFF1B2E21) : const Color(0xFF355C3F);
    final hi = dark ? const Color(0xFF29422E) : const Color(0xFF4A7A55);
    final lo = dark ? const Color(0xFF14271A) : const Color(0xFF2C4734);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        // A concrete height: inside a ListView the incoming height is unbounded,
        // and this Stack has only positioned children, so it can't derive its
        // own size. Without this the Stack tries to be infinitely tall.
        height: minHeight,
        child: Container(
          color: base,
          child: Stack(
            fit: StackFit.expand,
            children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.4, 0.2),
                    radius: 0.9,
                    colors: [hi, base.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.4, -0.2),
                    radius: 1.0,
                    colors: [lo, base.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _ContourPainter(
                  Colors.white.withValues(alpha: dark ? 0.04 : 0.06),
                ),
              ),
            ),
            ...children,
          ],
          ),
        ),
      ),
    );
  }
}

class _ContourPainter extends CustomPainter {
  _ContourPainter(this.line);
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final center = Offset(size.width * 0.5, size.height * 0.5);
    for (double r = 18; r < size.longestSide; r += 18) {
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(_ContourPainter old) => old.line != line;
}

/// Soft, blurred decorative blob used behind auth screens.
class BlurBlob extends StatelessWidget {
  const BlurBlob({super.key, required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
