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

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final utilizationPct = (card.spentAmount / card.monthlyLimit * 100).clamp(0, 100);

    return Column(
      children: [
        InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E2B45),
                  Color(0xFF131D31),
                  Color(0xFF0D1322),
                ],
              ),
              border: Border.all(
                color: card.isLowBalance
                    ? AppTheme.primaryOrange.withValues(alpha: 0.7)
                    : AppTheme.primaryOrange.withValues(alpha: 0.4),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D1322).withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // 45° Directional Chevron Kinetic Watermark
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: CustomPaint(
                      painter: _ChevronWatermarkPainter(),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Card Title & SAMA / Active Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryOrange.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.credit_card,
                                  color: AppTheme.primaryOrange,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CORPORATE PRE-FUNDED',
                                    style: TextStyle(
                                      color: Color(0xFFFED7AA),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  Text(
                                    'Executive Mobility',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: card.isLowBalance
                                  ? AppTheme.primaryOrange.withValues(alpha: 0.2)
                                  : AppTheme.successGreen.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: card.isLowBalance
                                    ? AppTheme.primaryOrange
                                    : AppTheme.successGreen.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 3.5,
                                  backgroundColor: card.isLowBalance ? AppTheme.primaryOrange : AppTheme.successGreen,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  card.isLowBalance ? '${utilizationPct.toInt()}% THRESHOLD' : 'ACTIVE',
                                  style: TextStyle(
                                    color: card.isLowBalance ? AppTheme.orangeLight : const Color(0xFF34D399),
                                    fontSize: 10.0,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // EMV Chip + Contactless symbol + Card Reveal Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 38,
                                height: 28,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                                  ),
                                  borderRadius: BorderRadius.circular(5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: CustomPaint(
                                  painter: _ChipPainter(),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                Icons.contactless,
                                color: Colors.white.withValues(alpha: 0.6),
                                size: 22,
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  _isCardRevealed ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.white70,
                                  size: 19,
                                ),
                                tooltip: _isCardRevealed ? 'Hide card digits' : 'Show full digits',
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  setState(() {
                                    _isCardRevealed = !_isCardRevealed;
                                  });
                                },
                              ),
                              const SizedBox(width: 4),
                              // Mastercard style overlapping circles
                              Row(
                                children: [
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppTheme.primaryOrange.withValues(alpha: 0.9),
                                    ),
                                  ),
                                  Transform.translate(
                                    offset: const Offset(-6, 0),
                                    child: Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFFFDBA74).withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Card Number (Masked vs Revealed)
                      Text(
                        _isCardRevealed
                            ? '4532 8912 6743 ${card.cardNumber.replaceAll(RegExp(r'\D'), '').padLeft(4, '0')}'
                            : card.maskedCardNumber,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.8,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Bottom Row: Cardholder & Validity
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'CARD CUSTODIAN',
                                style: TextStyle(
                                  fontSize: 9.0,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                card.cardholderName.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'VALID THRU',
                                style: TextStyle(
                                  fontSize: 9.0,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                '09/28',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.orangeLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),
                      // Balance & Limit Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (card.spentAmount / card.monthlyLimit).clamp(0.0, 1.0),
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            card.isLowBalance ? AppTheme.primaryOrange : const Color(0xFF38BDF8),
                          ),
                          minHeight: 5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Remaining: SAR ${card.currentBalance.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: card.isLowBalance ? FontWeight.bold : FontWeight.normal,
                              color: card.isLowBalance ? AppTheme.orangeLight : const Color(0xFFCBD5E1),
                            ),
                          ),
                          Text(
                            'Limit: SAR ${card.monthlyLimit.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // High-Priority Limit Threshold Active Notification Card
        if (card.isLowBalance) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFF7ED),
                  Colors.white,
                  const Color(0xFFFFEDD5).withValues(alpha: 0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primaryOrange.withValues(alpha: 0.5), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.notification_important, size: 18, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Limit Threshold Active',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF9A3412),
                                ),
                              ),
                              SizedBox(width: 6),
                              CircleAvatar(
                                radius: 3.5,
                                backgroundColor: AppTheme.primaryOrange,
                              ),
                            ],
                          ),
                          Text(
                            'Remaining balance under SAR 1,000 threshold',
                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Card replenishment trigger is active. To unlock automatic balance reload, submit your unfiled petty cash receipts for approval.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.bolt, size: 16),
                    label: const Text('Submit Invoices & Request Refill', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    onPressed: widget.onRequestRefill,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6B4E04)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    canvas.drawLine(Offset(w * 0.35, 0), Offset(w * 0.35, h), paint);
    canvas.drawLine(Offset(w * 0.65, 0), Offset(w * 0.65, h), paint);
    canvas.drawLine(Offset(0, h * 0.5), Offset(w, h * 0.5), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChevronWatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryOrange.withValues(alpha: 0.055)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    for (double offset = -h; offset < w + h; offset += 60) {
      final path = Path()
        ..moveTo(offset, 0)
        ..lineTo(offset + 40, h * 0.5)
        ..lineTo(offset, h);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
