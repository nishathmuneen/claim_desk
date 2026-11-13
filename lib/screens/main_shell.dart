import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/claim_desk_provider.dart';
import '../widgets/app_header.dart';
import 'dashboard_screen.dart';
import 'new_claim_screen.dart';
import 'resubmission_screen.dart';
import 'claims_history_screen.dart';

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

    final screens = [
      DashboardScreen(onNavigateTab: _onTabSelected),
      const NewClaimScreen(),
      const ResubmissionScreen(),
      const ClaimsHistoryScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: ClaimDeskAppHeader(
        onNotificationTap: () => _onTabSelected(2), // Jump to Action Needed tab
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.border, width: 1.0)),
          boxShadow: [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTabSelected,
          backgroundColor: Colors.white,
          indicatorColor: AppTheme.primaryOrange.withValues(alpha: 0.18),
          elevation: 0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, color: AppTheme.textSecondary),
              selectedIcon: Icon(Icons.dashboard, color: AppTheme.primaryOrange),
              label: 'Dashboard',
            ),
            const NavigationDestination(
              icon: Icon(Icons.add_circle_outline, color: AppTheme.textSecondary),
              selectedIcon: Icon(Icons.add_circle, color: AppTheme.primaryOrange),
              label: 'New Claim',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: actionNeededCount > 0,
                label: Text('$actionNeededCount'),
                backgroundColor: AppTheme.dangerRed,
                child: const Icon(Icons.assignment_late_outlined, color: AppTheme.textSecondary),
              ),
              selectedIcon: Badge(
                isLabelVisible: actionNeededCount > 0,
                label: Text('$actionNeededCount'),
                backgroundColor: AppTheme.dangerRed,
                child: const Icon(Icons.assignment_late, color: AppTheme.dangerRed),
              ),
              label: 'Action Needed',
            ),
            const NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined, color: AppTheme.textSecondary),
              selectedIcon: Icon(Icons.receipt_long, color: AppTheme.primaryOrange),
              label: 'My Claims',
            ),
          ],
        ),
      ),
    );
  }
}
