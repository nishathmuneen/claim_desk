import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Official 'expertise' Brand Logo Widget.
/// Rendered directly from the official corporate lockup asset
/// featuring the signature dynamic energy orange 'x' and 'Inspiring Excellence' tagline.
class ExpertiseLogo extends StatelessWidget {
  final double height;
  final bool showTagline;
  final Color? taglineColor;
  final bool isBrandCard;

  const ExpertiseLogo({
    super.key,
    this.height = 36.0,
    this.showTagline = false,
    this.taglineColor,
    this.isBrandCard = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isBrandCard) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          'assets/images/expertise_brand_card.png',
          height: height,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildFallback(context),
        ),
      );
    }

    final logoWidget = Image.asset(
      'assets/images/expertise_logo.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => _buildFallback(context),
    );

    if (!showTagline) return logoWidget;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        logoWidget,
        const SizedBox(height: 6),
        Text(
          'Inspiring Excellence',
          style: TextStyle(
            color: taglineColor ?? const Color(0xFFCBD5E1),
            fontSize: height * 0.32,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFallback(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'Segoe UI',
          fontSize: height * 0.8,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
        children: const [
          TextSpan(text: 'e'),
          TextSpan(
            text: 'x',
            style: TextStyle(
              color: AppTheme.primaryOrange,
              fontWeight: FontWeight.w900,
            ),
          ),
          TextSpan(text: 'pertise'),
        ],
      ),
    );
  }
}
