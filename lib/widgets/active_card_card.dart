import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/petty_cash_card.dart';

class ActiveCardCard extends StatefulWidget {
  final PettyCashCard card;
  final VoidCallback? onTap;
  final VoidCallback? onRequestRefill;

  const ActiveCardCard({
    super.key,
    required this.card,
    this.onTap,
    this.onRequestRefill,
  });

  @override
  State<ActiveCardCard> createState() => _ActiveCardCardState();
}

class _ActiveCardCardState extends State<ActiveCardCard> {
  bool _isCardRevealed = false;

  String _getLast4(String cardNumber) {
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 4) {
      return digits.substring(digits.length - 4);
    }
    return digits.padLeft(4, '0');
  }

  String _formatRevealedNumber(String cardNumber) {
    final clean = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (clean.length >= 16) {
      return '${clean.substring(0, 4)}  ${clean.substring(4, 8)}  ${clean.substring(8, 12)}  ${clean.substring(12, 16)}';
    }
    return '4532  8912  6743  ${_getLast4(cardNumber)}';
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final spentRatio = (card.spentAmount / card.monthlyLimit).clamp(0.0, 1.0);
    final utilizationPct = (spentRatio * 100).toInt();
    final last4 = _getLast4(card.cardNumber);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Exact Replica of User's Luxury Ivory & Gold Corporate Card
            InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  // Outer Polished Golden Metallic Rim
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFDF73),
                      Color(0xFFD4AF37),
                      Color(0xFFB45309),
                      Color(0xFFF59E0B),
                      Color(0xFFFFE082),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.18),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: const Color(0xFFD97706).withValues(alpha: 0.22),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(2.4), // Golden Rim Thickness
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    // Main Luxury Ivory / Champagne Canvas
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFFDF9),
                        Color(0xFFFBF7F0),
                        Color(0xFFF5EFE6),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Background Paint: Top-Left Navy Corner Swoosh & Kinetic 3D Chevrons
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _LuxuryCardPainter(),
                        ),
                      ),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Top Section (Padding 18h x 16t)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top-Left: Card Icon + Titles
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0F172A),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: const Color(0xFFD4AF37),
                                            width: 1.2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.2),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.credit_card_rounded,
                                            color: Color(0xFFFDE047),
                                            size: 19,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'CORPORATE PRE-FUNDED',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Color(0xFFB45309),
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 1.1,
                                              ),
                                            ),
                                            SizedBox(height: 1),
                                            Text(
                                              'Executive Mobility',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Color(0xFF0F172A),
                                                fontSize: 18,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Top-Right: Threshold Pill & Toggle Switch
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // Status Pill
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F172A),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(0xFFD4AF37),
                                          width: 1.2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.15),
                                            blurRadius: 5,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 7,
                                            height: 7,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFFF59E0B),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Color(0xFFF59E0B),
                                                  blurRadius: 4,
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            card.isLowBalance ? '$utilizationPct% THRESHOLD' : 'ACTIVE',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    // Eye Toggle Switch
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _isCardRevealed = !_isCardRevealed;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 2.0),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _isCardRevealed ? Icons.visibility_off : Icons.visibility,
                                              size: 18,
                                              color: const Color(0xFF0F172A),
                                            ),
                                            const SizedBox(width: 6),
                                            // Golden Toggle Switch
                                            Container(
                                              width: 36,
                                              height: 19,
                                              padding: const EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(12),
                                                gradient: const LinearGradient(
                                                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(0xFFD97706).withValues(alpha: 0.35),
                                                    blurRadius: 3,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                              alignment: _isCardRevealed ? Alignment.centerRight : Alignment.centerLeft,
                                              child: Container(
                                                width: 15,
                                                height: 15,
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: LinearGradient(
                                                    colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(color: Colors.black26, blurRadius: 2),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // 2. EMV Chip & Contactless Waves
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18.0),
                            child: Row(
                              children: [
                                // Metallic Golden Chip
                                Container(
                                  width: 44,
                                  height: 31,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFFFE082),
                                        Color(0xFFF59E0B),
                                        Color(0xFFD97706),
                                        Color(0xFFB45309),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFFFD54F),
                                      width: 0.8,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF78350F).withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: CustomPaint(
                                    painter: _GoldenChipPainter(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const RotatedBox(
                                  quarterTurns: 1,
                                  child: Icon(
                                    Icons.wifi,
                                    size: 19,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // 3. Card Number (•••• •••• •••• 9901)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18.0),
                            child: Text(
                              _isCardRevealed
                                  ? _formatRevealedNumber(card.cardNumber)
                                  : '••••  ••••  ••••  $last4',
                              style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.5,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // 4. Custodian & Validity Row
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'CARD CUSTODIAN',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      card.cardholderName.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0F172A),
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: const [
                                    Text(
                                      'VALID THRU',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      '09/28',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFFEA580C),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // 5. Glowing 3D Golden Progress Bar
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18.0),
                            child: Container(
                              height: 6.5,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: LayoutBuilder(
                                builder: (ctx, constraints) {
                                  final fillWidth = constraints.maxWidth * spentRatio;
                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      width: fillWidth,
                                      height: 6.5,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        gradient: const LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Color(0xFFFEF08A),
                                            Color(0xFFF59E0B),
                                            Color(0xFFD97706),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFF59E0B).withValues(alpha: 0.55),
                                            blurRadius: 5,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // 6. Bottom Navy & Gold Ribbon (Remaining & Limit)
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF0F172A),
                                  Color(0xFF131D31),
                                  Color(0xFF0A0F1D),
                                ],
                              ),
                              border: Border(
                                top: BorderSide(
                                  color: Color(0xFFD4AF37),
                                  width: 1.4,
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Remaining Balance
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.account_balance_wallet_rounded,
                                      size: 15,
                                      color: Color(0xFFFBBF24),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Remaining: ',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      'SAR ${card.currentBalance.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: Color(0xFFFDE047),
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      width: 1,
                                      height: 12,
                                      color: const Color(0xFFD97706).withValues(alpha: 0.5),
                                    ),
                                  ],
                                ),

                                // Limit
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.monetization_on_rounded,
                                      size: 15,
                                      color: Color(0xFFFBBF24),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Limit: ',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      'SAR ${card.monthlyLimit.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Compact Limit Threshold Active Notification Card
            if (card.isLowBalance) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFF7ED),
                      Colors.white,
                      const Color(0xFFFFEDD5).withValues(alpha: 0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryOrange.withValues(alpha: 0.4),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4.5),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryOrange,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.notification_important,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Limit Threshold Active',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF9A3412),
                                    ),
                                  ),
                                  SizedBox(width: 5),
                                  CircleAvatar(
                                    radius: 3.0,
                                    backgroundColor: AppTheme.primaryOrange,
                                  ),
                                ],
                              ),
                              SizedBox(height: 1),
                              Text(
                                'Remaining balance under SAR 1,000 threshold',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF9A3412),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Replenishment trigger active. Submit receipts to unlock automatic balance reload.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textSecondary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 34,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0.5,
                        ),
                        icon: const Icon(Icons.bolt, size: 14),
                        label: const Text(
                          'Submit Invoices & Request Refill',
                          style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold),
                        ),
                        onPressed: widget.onRequestRefill,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GoldenChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF78350F)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    // Chip internal circuit line carving
    canvas.drawLine(Offset(w * 0.35, 0), Offset(w * 0.35, h), linePaint);
    canvas.drawLine(Offset(w * 0.65, 0), Offset(w * 0.65, h), linePaint);
    canvas.drawLine(Offset(0, h * 0.5), Offset(w, h * 0.5), linePaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.5, h * 0.5), width: w * 0.38, height: h * 0.45),
        const Radius.circular(2),
      ),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LuxuryCardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Top-Left Navy Corner Swoosh with Gold Arc Edge
    final navyPath = Path()
      ..moveTo(0, 0)
      ..lineTo(w * 0.16, 0)
      ..cubicTo(w * 0.11, h * 0.12, 0, h * 0.28, 0, h * 0.38)
      ..close();
    canvas.drawPath(navyPath, Paint()..color = const Color(0xFF0F172A));

    final goldArcPaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    final goldArcPath = Path()
      ..moveTo(w * 0.16, 0)
      ..cubicTo(w * 0.11, h * 0.12, 0, h * 0.28, 0, h * 0.38);
    canvas.drawPath(goldArcPath, goldArcPaint);

    // 2. Beveled 3D Kinetic Chevron Ribs in the Right Half
    for (double xFrac in [0.46, 0.60, 0.74]) {
      final startX = w * xFrac;
      final arrowTipX = startX + h * 0.45;

      final path = Path()
        ..moveTo(startX, 0)
        ..lineTo(arrowTipX, h * 0.44)
        ..lineTo(startX, h * 0.85);

      final chevronPaint = Paint()
        ..color = const Color(0xFFD4AF37).withValues(alpha: 0.16)
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(path, chevronPaint);

      // Subtle light bevel highlight
      final highlightPaint = Paint()
        ..color = const Color(0xFFFFFBEB).withValues(alpha: 0.45)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path.shift(const Offset(-1.2, -1.2)), highlightPaint);
    }

    // 3. Flowing Gold Light Trim along the Bottom Ribbon Edge
    final bottomRibbonTopY = h - 42;
    final goldTrimPath = Path()
      ..moveTo(0, bottomRibbonTopY)
      ..cubicTo(w * 0.25, bottomRibbonTopY - 6, w * 0.45, bottomRibbonTopY + 2, w, bottomRibbonTopY);

    final glowPaint = Paint()
      ..color = const Color(0xFFF59E0B).withValues(alpha: 0.4)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(goldTrimPath, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
