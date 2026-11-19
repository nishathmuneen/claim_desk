import 'package:flutter/material.dart';

/// Kinetic Corporate Precision background with prominent golden-shaded theme lines.
/// Features a crisp enterprise gradient with richer, darker golden directional
/// velocity lines and warm amber chevron watermarks inspired by executive corporate branding.
class KineticBackground extends StatelessWidget {
  final Widget child;

  const KineticBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFDFBF7), // Warm subtle ivory-gold top
            Color(0xFFF8FAFC), // Crisp clean card base
            Color(0xFFF3F6FC), // Soft blue-tinted base
          ],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Dynamic Golden Directional Velocity Lines & Watermark Layer
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _KineticCanvasPainter(),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _KineticCanvasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Prominent Darker Golden Velocity Lines (Rich Amber / Gold shaded theme lines)
    final goldLinePaint = Paint()
      ..color = const Color(0xFFD97706).withValues(alpha: 0.16)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final goldAccentPaint = Paint()
      ..color = const Color(0xFFF59E0B).withValues(alpha: 0.22)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final goldHairlinePaint = Paint()
      ..color = const Color(0xFFB45309).withValues(alpha: 0.08)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw parallel golden lines angled at ~38° across the entire canvas
    const lineSpacing = 65.0;
    int lineIndex = 0;
    for (double offset = -h * 1.5; offset < w + h * 1.5; offset += lineSpacing) {
      lineIndex++;
      final isAccent = lineIndex % 3 == 0;
      final isHairline = lineIndex % 6 == 1;

      Paint paintToUse;
      if (isAccent) {
        paintToUse = goldAccentPaint;
      } else if (isHairline) {
        paintToUse = goldHairlinePaint;
      } else {
        paintToUse = goldLinePaint;
      }

      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset + h * 0.85, h),
        paintToUse,
      );
    }

    // 2. Warm Golden & Orange Kinetic Chevron Watermarks
    final goldChevronPaint = Paint()
      ..color = const Color(0xFFD97706).withValues(alpha: 0.045)
      ..style = PaintingStyle.fill;

    final orangeChevronPaint = Paint()
      ..color = const Color(0xFFF97316).withValues(alpha: 0.055)
      ..style = PaintingStyle.fill;

    const colSpacing = 180.0;
    const rowSpacing = 150.0;
    const dx = 42.0;
    const dy = 55.0;
    const ribbonWidth = 22.0;

    int colIndex = 0;
    for (double x = -60; x < w + 120; x += colSpacing) {
      colIndex++;
      int rowIndex = 0;
      for (double y = -80; y < h + 140; y += rowSpacing) {
        rowIndex++;
        // Stagger every other column for dynamic tessellation
        final staggeredY = (colIndex % 2 == 1) ? y : y + (rowSpacing / 2);

        final path = Path()
          ..moveTo(x, staggeredY)
          ..lineTo(x + dx, staggeredY + dy)
          ..lineTo(x, staggeredY + 2 * dy)
          ..lineTo(x + ribbonWidth, staggeredY + 2 * dy)
          ..lineTo(x + dx + ribbonWidth, staggeredY + dy)
          ..lineTo(x + ribbonWidth, staggeredY)
          ..close();

        // Highlight with energy orange accent on staggered intervals
        final isOrangeAccent = (colIndex + rowIndex) % 4 == 0;
        canvas.drawPath(
          path,
          isOrangeAccent ? orangeChevronPaint : goldChevronPaint,
        );
      }
    }

    // 3. Ambient Golden Glow Vignette (Top-Right and Bottom-Left)
    final topAmbientPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.85, -0.85),
        radius: 0.9,
        colors: [
          const Color(0xFFD97706).withValues(alpha: 0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), topAmbientPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
