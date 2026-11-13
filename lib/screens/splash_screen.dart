import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/chevron_background.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2300), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Exact match to User Image 2: Corporate Deep Navy canvas with subtle chevron lines
    return Scaffold(
      backgroundColor: AppTheme.navyDark,
      body: ChevronBackground(
        opacity: 0.18,
        isDark: true,
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // "expertise" logo matching User Image 2
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'Segoe UI',
                        fontSize: 46,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1.0,
                      ),
                      children: [
                        TextSpan(text: 'e'),
                        TextSpan(
                          text: 'x',
                          style: TextStyle(
                            color: AppTheme.primaryOrange,
                            fontSize: 50,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        TextSpan(text: 'pertise'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Corporate Tagline (From User Image 2)
                  const Text(
                    'Inspiring Excellence',
                    style: TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 16,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 38),
                  // App Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.navySurface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppTheme.primaryOrange.withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long, color: AppTheme.primaryOrange, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'ClaimDesk • Dynamic DMS',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryOrange),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
