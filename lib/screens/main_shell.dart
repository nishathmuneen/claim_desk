import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/claim_desk_provider.dart';
import '../widgets/app_header.dart';
import '../widgets/kinetic_background.dart';
import 'dashboard_screen.dart';
import 'new_claim_screen.dart';
import 'resubmission_screen.dart';
import 'claims_history_screen.dart';
import 'approval_queue_screen.dart';
import 'sap_posting_screen.dart';
import 'reconciliation_screen.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;

  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClaimDeskProvider>();
    final actionNeededCount = provider.actionNeededCount;
    final activeRole = provider.activeRole;

    late final List<Widget> screens;
    late final List<Widget> navTabs;

    if (activeRole == 'Approver') {
      screens = const [
        ApprovalQueueScreen(),
        ReconciliationScreen(),
        ClaimsHistoryScreen(),
      ];
      final safeIndex = _currentIndex.clamp(0, screens.length - 1);
      navTabs = [
        _buildNavTab(
          index: 0,
          label: 'Approvals',
          unselectedIcon: Icons.fact_check_outlined,
          selectedIcon: Icons.fact_check_rounded,
          isSelected: safeIndex == 0,
          badgeCount: provider.pendingApprovalClaims.length,
        ),
        _buildNavTab(
          index: 1,
          label: 'Reconcile',
          unselectedIcon: Icons.balance_outlined,
          selectedIcon: Icons.balance_rounded,
          isSelected: safeIndex == 1,
        ),
        _buildNavTab(
          index: 2,
          label: 'All Claims',
          unselectedIcon: Icons.layers_outlined,
          selectedIcon: Icons.layers_rounded,
          isSelected: safeIndex == 2,
        ),
      ];
    } else if (activeRole == 'Finance / AP') {
      screens = const [
        SapPostingScreen(),
        ReconciliationScreen(),
        ClaimsHistoryScreen(),
      ];
      final safeIndex = _currentIndex.clamp(0, screens.length - 1);
      navTabs = [
        _buildNavTab(
          index: 0,
          label: 'SAP & Refills',
          unselectedIcon: Icons.account_balance_outlined,
          selectedIcon: Icons.account_balance_rounded,
          isSelected: safeIndex == 0,
          badgeCount: provider.approvedPendingSapClaims.length,
        ),
        _buildNavTab(
          index: 1,
          label: 'Reconcile',
          unselectedIcon: Icons.balance_outlined,
          selectedIcon: Icons.balance_rounded,
          isSelected: safeIndex == 1,
        ),
        _buildNavTab(
          index: 2,
          label: 'All Claims',
          unselectedIcon: Icons.layers_outlined,
          selectedIcon: Icons.layers_rounded,
          isSelected: safeIndex == 2,
        ),
      ];
    } else {
      screens = [
        DashboardScreen(onNavigateTab: _onTabSelected),
        const NewClaimScreen(),
        const ResubmissionScreen(),
        const ClaimsHistoryScreen(),
      ];
      final safeIndex = _currentIndex.clamp(0, screens.length - 1);
      navTabs = [
        _buildNavTab(
          index: 0,
          label: 'Dashboard',
          unselectedIcon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
          isSelected: safeIndex == 0,
        ),
        _buildNavTab(
          index: 1,
          label: 'New Claim',
          unselectedIcon: Icons.add_circle_outline_rounded,
          selectedIcon: Icons.add_circle_rounded,
          isSelected: safeIndex == 1,
        ),
        _buildNavTab(
          index: 2,
          label: 'Action Needed',
          unselectedIcon: Icons.fact_check_outlined,
          selectedIcon: Icons.fact_check_rounded,
          isSelected: safeIndex == 2,
          badgeCount: actionNeededCount,
        ),
        _buildNavTab(
          index: 3,
          label: 'My Claims',
          unselectedIcon: Icons.layers_outlined,
          selectedIcon: Icons.layers_rounded,
          isSelected: safeIndex == 3,
        ),
      ];
    }

    final safeIndex = _currentIndex.clamp(0, screens.length - 1);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: ClaimDeskAppHeader(
        onNotificationTap: () => _onTabSelected(activeRole == 'User / Custodian' ? 2 : 0),
      ),
      body: KineticBackground(
        child: IndexedStack(
          index: safeIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: Container(
            decoration: BoxDecoration(
              // Golden peach / warm champagne gradient matching the reference image
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFDE8C7), // Warm peach-gold top
                  Color(0xFFF7D59E), // Golden amber bottom
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFFF6C987),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFB45309).withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              children: navTabs,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavTab({
    required int index,
    required String label,
    required IconData unselectedIcon,
    required IconData selectedIcon,
    required bool isSelected,
    int badgeCount = 0,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _onTabSelected(index),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF16233B) // Dark Midnight Navy when selected
                    : const Color(0xFFFFFDF8), // Ivory cream white when unselected
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF16233B)
                      : const Color(0xFFF3E4CF),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isSelected ? 0.25 : 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        isSelected ? selectedIcon : unselectedIcon,
                        size: 21,
                        color: isSelected
                            ? const Color(0xFFFBBF24) // Warm gold icon when navy selected
                            : const Color(0xFF5A3110), // Deep bronze/brown icon when unselected
                      ),
                      if (badgeCount > 0)
                        Positioned(
                          top: -4,
                          right: -8,
                          child: Container(
                            padding: const EdgeInsets.all(3.5),
                            decoration: const BoxDecoration(
                              color: Color(0xFFDC2626), // Red circular badge
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Center(
                              child: Text(
                                '$badgeCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3.5),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white // White text when navy selected
                          : const Color(0xFF451A03), // Deep bronze/brown text when unselected
                      letterSpacing: -0.1,
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
