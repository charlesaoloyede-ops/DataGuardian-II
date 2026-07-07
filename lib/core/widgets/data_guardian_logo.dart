import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Draws the Data Guardian shield + signal-bars logo.
class DataGuardianLogo extends StatelessWidget {
  final double size;
  const DataGuardianLogo({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  static const _bg = Color(0xFF1C6B65);
  static const _shield = Colors.white;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final r = s * 0.22;

    // ── Rounded-square background ────────────────────────────────────────
    final bgPaint = Paint()..color = _bg;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, s, s), Radius.circular(r)),
      bgPaint,
    );

    // ── Shield ───────────────────────────────────────────────────────────
    final cx = s / 2;
    final cy = s / 2 - s * 0.01;
    final sw = s * 0.62;
    final sh = s * 0.68;

    final shieldPaint = Paint()..color = _shield;
    canvas.drawPath(_shieldPath(cx, cy, sw, sh), shieldPaint);

    // ── Signal bars (teal on white shield) ────────────────────────────────
    final barPaint = Paint()..color = _bg;
    _drawBars(canvas, cx, cy, sw, sh, barPaint);
  }

  Path _shieldPath(double cx, double cy, double w, double h) {
    final hw = w / 2;
    final topY = cy - h * 0.50;
    final sideY = cy + h * 0.10;
    final botY = cy + h * 0.50;
    final leftX = cx - hw;
    final rightX = cx + hw;
    final cr = w * 0.12;

    final path = Path();

    // Top-left arc
    for (var t = 10; t <= 90; t += 10) {
      final angle = math.pi + t * math.pi / 180;
      final x = leftX + cr + cr * math.cos(angle);
      final y = topY + cr + cr * math.sin(angle);
      t == 10 ? path.moveTo(x, y) : path.lineTo(x, y);
    }

    // Top-right arc
    for (var t = 270; t <= 360; t += 10) {
      final angle = t * math.pi / 180;
      path.lineTo(
        rightX - cr + cr * math.cos(angle),
        topY + cr + cr * math.sin(angle),
      );
    }

    // Right side to tip (quadratic bezier approximated)
    path.lineTo(rightX, sideY);
    const steps = 8;
    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      path.lineTo(
        _bezier(rightX, rightX, cx, t),
        _bezier(sideY, botY, botY, t),
      );
    }

    // Tip back up left side
    for (var i = steps; i >= 0; i--) {
      final t = i / steps;
      path.lineTo(
        _bezier(leftX, leftX, cx, t),
        _bezier(sideY, botY, botY, t),
      );
    }

    path.lineTo(leftX, sideY);
    path.close();
    return path;
  }

  double _bezier(double p0, double p1, double p2, double t) =>
      (1 - t) * (1 - t) * p0 + 2 * (1 - t) * t * p1 + t * t * p2;

  void _drawBars(
      Canvas canvas, double cx, double cy, double sw, double sh, Paint paint) {
    final barAreaW = sw * 0.54;
    final barAreaH = sh * 0.38;
    final barAreaX = cx - barAreaW / 2;
    final barBottomY = cy + sh * 0.16;

    const nBars = 3;
    final gap = barAreaW * 0.18;
    final barW = (barAreaW - gap * (nBars - 1)) / nBars;
    final heights = [barAreaH * 0.45, barAreaH * 0.72, barAreaH * 1.0];
    final radius = barW * 0.28;

    for (var i = 0; i < nBars; i++) {
      final bh = heights[i];
      final bx0 = barAreaX + i * (barW + gap);
      final bx1 = bx0 + barW;
      final by0 = barBottomY - bh;
      final by1 = barBottomY;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(bx0, by0, bx1, by1),
          Radius.circular(radius),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
