import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/user_profile.dart';
import '../providers/claim_desk_provider.dart';
import '../widgets/chevron_background.dart';
import 'main_shell.dart';

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

  Widget _buildUserTile(UserProfile user) {
    final isSelected = user.id == _selectedUser.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () => _onUserSelected(user),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.orangeMuted : AppTheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.primaryOrange : AppTheme.border,
              width: isSelected ? 1.6 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: isSelected ? AppTheme.primaryOrange : AppTheme.surfaceElevated,
                child: Text(
                  user.name[0],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppTheme.orangeDark : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${user.designation} • ${user.division}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      'Card: ${user.assignedCardNumber.substring(user.assignedCardNumber.length - 4)} • ${user.costCenter}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryOrange,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: ChevronBackground(
        opacity: 0.22, // Clean orange chevrons on light background (Image 1)
        isDark: false,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Header Card: Deep Navy with Expertise Logo & Chevron Lines (Image 2)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppTheme.navyDark,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // "expertise" logo with orange 'X'
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontFamily: 'Segoe UI',
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                              children: [
                                TextSpan(text: 'e'),
                                TextSpan(
                                  text: 'x',
                                  style: TextStyle(
                                    color: AppTheme.primaryOrange,
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                TextSpan(text: 'pertise'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Inspiring Excellence',
                            style: TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 13,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryOrange.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.primaryOrange.withValues(alpha: 0.4)),
                            ),
                            child: const Text(
                              'ClaimDesk • Petty Cash Portal',
                              style: TextStyle(
                                color: AppTheme.orangeLight,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Multi-User Switcher (ONLY Employee Custodians — No Approvers)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.credit_card, size: 16, color: AppTheme.primaryOrange),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Select Employee (Card Custodian)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
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
                    ),
                    const SizedBox(height: 16),

                    // Login Credentials Card (Clean Crisp White)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _empIdController,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'Employee ID',
                              prefixIcon: Icon(Icons.badge_outlined, size: 20, color: AppTheme.textSecondary),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: AppTheme.textPrimary),
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
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _handleLogin,
                            icon: const Icon(Icons.login, size: 18),
                            label: const Text('Sign In to ClaimDesk'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    const Center(
                      child: Text(
                        'Expertise Dynamic DMS • Phase 2 User Portal',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
