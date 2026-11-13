import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ChevronBackground extends StatelessWidget {
  final Widget child;
  final double opacity;
  final bool isDark;

  const ChevronBackground({
    super.key,
    required this.child,
    this.opacity = 0.18,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? AppTheme.navyDark : AppTheme.background,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _ChevronPainter(
                opacity: opacity,
                chevronColor: isDark ? AppTheme.primaryOrange : const Color(0xFFF97316),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _ChevronPainter extends CustomPainter {
  final double opacity;
  final Color chevronColor;

  _ChevronPainter({
    required this.opacity,
    required this.chevronColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = chevronColor.withValues(alpha: opacity)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;

    final double step = size.width / 4.8;
    final double midY = size.height * 0.45;

    for (int i = -1; i < 7; i++) {
      final double startX = i * step;

      // Outer chevron arrow pointing right (exactly like Image 1 reference)
      final path = Path();
      path.moveTo(startX, 0);
      path.lineTo(startX + step * 0.85, midY);
      path.lineTo(startX, size.height);
      canvas.drawPath(path, paint);

      // Inner parallel chevron line
      final innerPath = Path();
      innerPath.moveTo(startX + 22, 0);
      innerPath.lineTo(startX + step * 0.85 + 22, midY);
      innerPath.lineTo(startX + 22, size.height);
      canvas.drawPath(innerPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChevronPainter oldDelegate) =>
      oldDelegate.opacity != opacity || oldDelegate.chevronColor != chevronColor;
}
