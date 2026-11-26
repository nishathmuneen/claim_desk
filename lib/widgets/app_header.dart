import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/claim_desk_provider.dart';
import '../screens/login_screen.dart';
import 'expertise_logo.dart';

class ClaimDeskAppHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onNotificationTap;

  const ClaimDeskAppHeader({
    super.key,
    this.onNotificationTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64.0);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClaimDeskProvider>();
    final activeUser = provider.activeUser;
    final activeRole = provider.activeRole;

    String getShortRole(String role) {
      if (role.contains('Custodian')) return 'Custodian';
      if (role.contains('Finance')) return 'Finance';
      return role;
    }

    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 64.0,
      backgroundColor: AppTheme.navyDark, // Deep Navy header matching corporate palette
      titleSpacing: 14.0,
      elevation: 0,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Brand Logo & Product Title
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              ExpertiseLogo(height: 20),
              SizedBox(width: 8),
              Text(
                'ClaimDesk',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16.0,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),

          const SizedBox(width: 8),

          // Right Controls: Sleek Role Switcher + Notification Badge + User Avatar
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
              // Compact Role Switcher Pill
              Container(
                height: 35,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppTheme.navyElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2E3E5C), width: 1.0),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: activeRole,
                    dropdownColor: AppTheme.navySurface,
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: AppTheme.primaryOrange,
                      size: 18,
                    ),
                    isDense: true,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    selectedItemBuilder: (BuildContext ctx) {
                      return [
                        'User / Custodian',
                        'Approver',
                        'Finance / AP',
                        'Admin',
                      ].map((role) {
                        IconData icon;
                        Color iconColor;
                        if (role.contains('Custodian')) {
                          icon = Icons.person;
                          iconColor = AppTheme.primaryOrange;
                        } else if (role.contains('Approver')) {
                          icon = Icons.check_circle_outline;
                          iconColor = AppTheme.infoBlue;
                        } else if (role.contains('Finance')) {
                          icon = Icons.account_balance;
                          iconColor = AppTheme.successGreen;
                        } else {
                          icon = Icons.admin_panel_settings;
                          iconColor = AppTheme.closedPurple;
                        }
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 14, color: iconColor),
                            const SizedBox(width: 5),
                            Text(getShortRole(role)),
                          ],
                        );
                      }).toList();
                    },
                    items: const [
                      DropdownMenuItem(
                        value: 'User / Custodian',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person, size: 15, color: AppTheme.primaryOrange),
                            SizedBox(width: 8),
                            Text('User / Custodian'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Approver',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline, size: 15, color: AppTheme.infoBlue),
                            SizedBox(width: 8),
                            Text('Approver'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Finance / AP',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.account_balance, size: 15, color: AppTheme.successGreen),
                            SizedBox(width: 8),
                            Text('Finance / AP'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Admin',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.admin_panel_settings, size: 15, color: AppTheme.closedPurple),
                            SizedBox(width: 8),
                            Text('Admin'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (newRole) {
                      if (newRole != null) {
                        provider.switchRole(newRole);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Switched view context to $newRole'),
                            backgroundColor: AppTheme.navyDark,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),

              if (provider.actionNeededCount > 0) ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Action Required',
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_active_outlined, color: AppTheme.primaryOrange, size: 21),
                      Positioned(
                        right: -3,
                        top: -3,
                        child: Container(
                          padding: const EdgeInsets.all(3.0),
                          decoration: const BoxDecoration(
                            color: AppTheme.dangerRed,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${provider.actionNeededCount}',
                            style: const TextStyle(
                              fontSize: 9.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  onPressed: onNotificationTap,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                ),
              ],

              const SizedBox(width: 6),

              // User Avatar Chip
              InkWell(
                onTap: () => _showUserModal(context, provider),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 35,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.navyElevated,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF2E3E5C), width: 1.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 11,
                        backgroundColor: AppTheme.primaryOrange,
                        child: Text(
                          activeUser.name[0],
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        activeUser.name.split(' ').first,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
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
    );
  }

  void _showUserModal(BuildContext context, ClaimDeskProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final user = provider.activeUser;
        final card = provider.activeCard;
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppTheme.primaryOrange,
                      child: Text(
                        user.name[0],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          Text(
                            '${user.designation} • ${user.employeeId}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                _infoRow('Company', user.company),
                _infoRow('Division', user.division),
                _infoRow('Department', user.department),
                _infoRow('Cost Center', user.costCenter),
                _infoRow('Assigned Card', user.hasActiveCard ? card.maskedCardNumber : (provider.activeCardApplication != null ? 'Pending Approval' : 'Not Applied Yet')),
                _infoRow('Card Validity', user.hasActiveCard ? '01/01/2026 – 31/12/2026' : 'Awaiting Activation'),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.dangerRed,
                          side: const BorderSide(color: AppTheme.dangerRed, width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        icon: const Icon(Icons.logout, size: 16, color: AppTheme.dangerRed),
                        label: const Text(
                          'Log Out',
                          style: TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Close'),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
