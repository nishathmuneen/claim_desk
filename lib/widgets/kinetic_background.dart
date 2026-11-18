import 'package:flutter/material.dart';

/// Kinetic Corporate Precision background inspired by the Stitch corporate card platform.
/// Features a crisp enterprise gradient (#F8FAFF -> #F1F5F9 -> #EFF4FF) with
/// 45° directional chevron watermarks, hairline velocity rules, and subtle ambient highlights.
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
            Color(0xFFF8FAFF),
            Color(0xFFF1F5F9),
            Color(0xFFEFF4FF),
          ],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Subtle kinetic directional chevrons & velocity lines watermark layer
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

    // 1. Subtle hairline 45° velocity lines across the background
    final guideLinePaint = Paint()
      ..color = const Color(0xFF1E2B45).withValues(alpha: 0.022)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const lineSpacing = 110.0;
    for (double offset = -h; offset < w + h; offset += lineSpacing) {
      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset + h * 0.7, h),
        guideLinePaint,
      );
    }

    // 2. Primary Corporate Navy 45° Chevron Ribbons
    final navyChevronPaint = Paint()
      ..color = const Color(0xFF182245).withValues(alpha: 0.028)
      ..style = PaintingStyle.fill;

    // 3. Energy Orange Kinetic Accent Chevron Ribbons
    final orangeChevronPaint = Paint()
      ..color = const Color(0xFFF97316).withValues(alpha: 0.038)
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

        // Highlight every 4th tile with subtle energy orange
        final isOrangeAccent = (colIndex + rowIndex) % 5 == 0;
        canvas.drawPath(
          path,
          isOrangeAccent ? orangeChevronPaint : navyChevronPaint,
        );
      }
    }

    // 4. Subtle top-right ambient warmth radial vignette
    final ambientPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.85, -0.9),
        radius: 0.8,
        colors: [
          const Color(0xFFF97316).withValues(alpha: 0.035),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), ambientPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
