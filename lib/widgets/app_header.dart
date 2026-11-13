import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/claim_desk_provider.dart';
import '../screens/login_screen.dart';

class ClaimDeskAppHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onNotificationTap;

  const ClaimDeskAppHeader({
    super.key,
    this.onNotificationTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(66.0);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClaimDeskProvider>();
    final activeUser = provider.activeUser;
    final activeRole = provider.activeRole;

    return AppBar(
      toolbarHeight: 66.0,
      backgroundColor: AppTheme.navyDark, // Deep Navy header matching Image 2
      titleSpacing: 10.0,
      leadingWidth: 175.0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: Center(
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppTheme.navyElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2E3E5C)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: activeRole,
                dropdownColor: AppTheme.navySurface,
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: AppTheme.primaryOrange,
                  size: 20,
                ),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'User / Custodian',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person, size: 15, color: AppTheme.primaryOrange),
                        SizedBox(width: 6),
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
                        SizedBox(width: 6),
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
                        SizedBox(width: 6),
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
                        SizedBox(width: 6),
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
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontFamily: 'Segoe UI',
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
              children: [
                TextSpan(text: 'e'),
                TextSpan(
                  text: 'x',
                  style: TextStyle(
                    color: AppTheme.primaryOrange,
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                  ),
                ),
                TextSpan(text: 'pertise '),
                TextSpan(
                  text: 'ClaimDesk',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: Color(0xFFCBD5E1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (provider.actionNeededCount > 0)
          IconButton(
            tooltip: 'Action Required',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_active_outlined, color: AppTheme.primaryOrange, size: 23),
                Positioned(
                  right: -3,
                  top: -3,
                  child: Container(
                    padding: const EdgeInsets.all(3.5),
                    decoration: const BoxDecoration(
                      color: AppTheme.dangerRed,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${provider.actionNeededCount}',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            onPressed: onNotificationTap,
          ),

        // User Avatar Chip
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: InkWell(
            onTap: () => _showUserModal(context, provider),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.navyElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2E3E5C)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: AppTheme.primaryOrange,
                    child: Text(
                      activeUser.name[0],
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    activeUser.name.split(' ').first,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showUserModal(BuildContext context, ClaimDeskProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final user = provider.activeUser;
        final card = provider.activeCard;
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primaryOrange,
                    child: Text(
                      user.name[0],
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        Text(
                          '${user.designation} • ${user.employeeId}',
                          style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),
              _infoRow('Company', user.company),
              _infoRow('Division', user.division),
              _infoRow('Department', user.department),
              _infoRow('Cost Center', user.costCenter),
              _infoRow('Assigned Card', card.maskedCardNumber),
              _infoRow('Card Validity', '01/01/2026 – 31/12/2026'),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.dangerRed,
                        side: const BorderSide(color: AppTheme.dangerRed, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 13),
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
                        padding: const EdgeInsets.symmetric(vertical: 13),
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
