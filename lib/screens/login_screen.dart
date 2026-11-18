import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/user_profile.dart';
import '../providers/claim_desk_provider.dart';
import '../widgets/kinetic_background.dart';
import '../widgets/expertise_logo.dart';
import 'main_shell.dart';

/// Stitch "Corporate Precision & Kinetic Velocity" Login Screen
/// Simplified & focused:
/// - Preserves the exact corporate 'expertise' logo and 'Inspiring Excellence' tagline
/// - Clean employee selector showing only user status: Active, Card Awaited, or New User
/// - No card details, numbers, or virtual card previews
/// - Clean enterprise SSO credentials form matching Stitch specifications
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late UserProfile _selectedUser;
  final _empIdController = TextEditingController();
  final _passwordController = TextEditingController(text: '••••••••');
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _selectedUser = UserProfile.demoUsers.first;
    _empIdController.text = _selectedUser.employeeId;
  }

  @override
  void dispose() {
    _empIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onUserSelected(UserProfile user) {
    setState(() {
      _selectedUser = user;
      _empIdController.text = user.employeeId;
    });
  }

  void _handleLogin() {
    final provider = context.read<ClaimDeskProvider>();
    provider.switchUser(_selectedUser);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: KineticBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Corporate Brand Header (Deep Navy with Signature Logo)
                    _buildBrandHeader(),
                    const SizedBox(height: 18),

                    // 2. Employee Custodian Selector Section (Status: Active / Card Awaited / New User)
                    _buildCustodianSelectorSection(),
                    const SizedBox(height: 18),

                    // 3. Enterprise Credentials & SSO Form Card
                    _buildCredentialsCard(),
                    const SizedBox(height: 20),

                    // 4. Security & Institutional Trust Footer
                    _buildTrustFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 1. Top Brand Header with the exact 'expertise' logo and tagline
  Widget _buildBrandHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.navyDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2B45), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Exact 'expertise' official brand logo with orange 'x' and tagline
          const ExpertiseLogo(
            height: 42,
            showTagline: true,
          ),
          const SizedBox(height: 12),

          // Portal Badge & Enterprise Single Sign-On
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryOrange.withValues(alpha: 0.45)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_person_outlined, size: 12, color: AppTheme.orangeLight),
                    SizedBox(width: 5),
                    Text(
                      'ClaimDesk • Custodian Portal',
                      style: TextStyle(
                        color: AppTheme.orangeLight,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, size: 12, color: Color(0xFF10B981)),
                    SizedBox(width: 4),
                    Text(
                      'SAMA & ZATCA Aligned',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 2. Employee Custodian Selector Section
  Widget _buildCustodianSelectorSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
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
              const Icon(Icons.badge, size: 16, color: AppTheme.primaryOrange),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Select Employee (Card Custodian)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${UserProfile.demoUsers.length} Profiles',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final user in UserProfile.demoUsers)
            _buildUserTile(user),
        ],
      ),
    );
  }

  /// Individual Custodian Profile Tile: Shows ONLY if user is Active, Card Awaited, or New User
  Widget _buildUserTile(UserProfile user) {
    final bool isSelected = user.id == _selectedUser.id;

    Color badgeBg;
    Color badgeText;
    String badgeLabel;
    IconData badgeIcon;

    if (user.hasActiveCard) {
      badgeBg = const Color(0xFFECFDF5);
      badgeText = const Color(0xFF059669);
      badgeLabel = 'Active';
      badgeIcon = Icons.check_circle;
    } else if (user.id == 'USR-002') {
      badgeBg = const Color(0xFFFFFBEB);
      badgeText = const Color(0xFFD97706);
      badgeLabel = 'Card Awaited';
      badgeIcon = Icons.hourglass_top_rounded;
    } else {
      badgeBg = const Color(0xFFEFF6FF);
      badgeText = const Color(0xFF2563EB);
      badgeLabel = 'New User';
      badgeIcon = Icons.person_add_alt_1_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 9.0),
      child: InkWell(
        onTap: () => _onUserSelected(user),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFF7ED) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryOrange : AppTheme.border,
              width: isSelected ? 1.8 : 1.1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              // Avatar circle with initial
              CircleAvatar(
                radius: 18,
                backgroundColor: isSelected ? AppTheme.primaryOrange : const Color(0xFFE2E8F0),
                child: Text(
                  user.name[0],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Employee Details (Name, Designation & Division, Status Badge)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? AppTheme.orangeDark : AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: badgeText.withValues(alpha: 0.35), width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(badgeIcon, size: 11, color: badgeText),
                              const SizedBox(width: 4),
                              Text(
                                badgeLabel,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: badgeText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${user.designation} • ${user.division}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Selection Radio/Indicator
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppTheme.primaryOrange : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryOrange : const Color(0xFFCBD5E1),
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 13, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 3. Enterprise Credentials & SSO Form Card
  Widget _buildCredentialsCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'ENTERPRISE SSO AUTHENTICATION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 10, color: AppTheme.textSecondary),
                    SizedBox(width: 3),
                    Text(
                      '256-Bit TLS',
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Employee ID Field
          TextField(
            controller: _empIdController,
            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              labelText: 'Employee ID',
              prefixIcon: Icon(Icons.badge_outlined, size: 20, color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 14),

          // Password Field
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: AppTheme.textPrimary, letterSpacing: 2.0),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppTheme.textSecondary),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  size: 19,
                  color: AppTheme.textSecondary,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 2FA Absher Linked Notice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              children: [
                Icon(Icons.phonelink_lock, size: 14, color: AppTheme.primaryOrange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Absher Gateway 2FA Linked • Device Authenticated',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Kinetic Velocity Primary Sign In Button
          ElevatedButton(
            onPressed: _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              shadowColor: AppTheme.primaryOrange.withValues(alpha: 0.4),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Sign In to ClaimDesk',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 4. Security & Institutional Trust Footer
  Widget _buildTrustFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _trustChip(Icons.security, 'SAMA Mesh'),
            const SizedBox(width: 8),
            _trustChip(Icons.verified, 'ZATCA Phase 2'),
            const SizedBox(width: 8),
            _trustChip(Icons.lock, 'TLS 1.3'),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Expertise Contracting Company • Corporate Spend Management Portal',
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _trustChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
