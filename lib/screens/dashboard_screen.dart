import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/claim_desk_provider.dart';
import '../widgets/active_card_card.dart';
import '../widgets/approval_stage_pills.dart';
import '../models/expense_claim.dart';
import '../models/card_refill_request.dart';
import '../models/card_application.dart';
import '../models/user_profile.dart';
import 'ocr_scanner_screen.dart';
import 'card_application_screen.dart';
import 'new_claim_screen.dart';
import 'claim_details_screen.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int) onNavigateTab;

  const DashboardScreen({super.key, required this.onNavigateTab});

  void _showRefillModal(BuildContext context, ClaimDeskProvider provider) {
    double selectedAmount = 5000.0;
    RefillUrgency selectedUrgency = RefillUrgency.urgent;
    final justificationCtrl = TextEditingController(
      text: 'Emergency heavy machinery hydraulic oil purchase for Jubail project.',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.bolt, color: AppTheme.primaryOrange, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Request Card Balance Refill',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(height: 18),

                    // Current Balance Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Current Balance', style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary)),
                              Text(
                                'SAR ${provider.activeCard.currentBalance.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.dangerRed),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Card Limit', style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary)),
                              Text(
                                'SAR ${provider.activeCard.monthlyLimit.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'SELECT REFILL AMOUNT (SAR)',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [1000.0, 2500.0, 5000.0].map((amt) {
                        final isSel = selectedAmount == amt;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: isSel ? AppTheme.primaryOrange : Colors.white,
                                side: BorderSide(
                                  color: isSel ? AppTheme.primaryOrange : AppTheme.border,
                                  width: isSel ? 1.5 : 1.0,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onPressed: () => setModalState(() => selectedAmount = amt),
                              child: Text(
                                'SAR ${amt.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSel ? Colors.white : AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'URGENCY LEVEL',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<RefillUrgency>(
                      value: selectedUrgency,
                      decoration: const InputDecoration(labelText: 'Priority Level'),
                      items: const [
                        DropdownMenuItem(value: RefillUrgency.normal, child: Text('Normal (Next settlement cycle)')),
                        DropdownMenuItem(value: RefillUrgency.urgent, child: Text('Urgent (Within 24 Hours)')),
                        DropdownMenuItem(value: RefillUrgency.critical, child: Text('Critical (Site Work Stoppage)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedUrgency = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: justificationCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Business Justification / Upcoming Needs'),
                    ),
                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.send, size: 16),
                        label: const Text('Submit Refill Request to AP Finance'),
                        onPressed: () {
                          provider.requestCardRefill(
                            requestedAmount: selectedAmount,
                            urgency: selectedUrgency,
                            justification: justificationCtrl.text.trim(),
                          );
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppTheme.navyDark,
                              content: Text('Refill request for SAR ${selectedAmount.toStringAsFixed(0)} submitted to Accounts Payable.'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClaimDeskProvider>();
    final activeCard = provider.activeCard;
    final claims = provider.claims;
    final cardApp = provider.activeCardApplication;

    return RefreshIndicator(
      color: AppTheme.primaryOrange,
      backgroundColor: Colors.white,
      onRefresh: () async => await Future.delayed(const Duration(milliseconds: 600)),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Presentation: Active Card vs Application In Progress vs KYC Required
            if (provider.activeUser.hasActiveCard) ...[
              ActiveCardCard(
                card: activeCard,
                onTap: () {
                  _showCardDetailsModal(context, provider);
                },
                onRequestRefill: () => _showRefillModal(context, provider),
              ),
              const SizedBox(height: 14),
              if (cardApp != null) ...[
                _buildCardAppTrackerPill(context, cardApp),
                const SizedBox(height: 16),
              ],
            ] else if (cardApp != null) ...[
              _buildApplicationInProgressHero(context, cardApp),
              const SizedBox(height: 16),
            ] else ...[
              _buildKycRequiredHero(context, provider.activeUser),
              const SizedBox(height: 16),
            ],

            // Section: Financial Overview (Bento Grid KPIs)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'FINANCIAL OVERVIEW',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMuted,
                    letterSpacing: 1.0,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF4FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Live Ledger',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.infoBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 2x2 Executive Bento Grid for Financial Overview
            Row(
              children: [
                Expanded(
                  child: _aestheticKpiCard(
                    title: 'AVAILABLE CASH',
                    currency: 'SAR',
                    value: activeCard.currentBalance.toStringAsFixed(0),
                    subtitle: 'Monthly Cap: SAR ${activeCard.monthlyLimit.toStringAsFixed(0)}',
                    icon: Icons.account_balance_wallet_rounded,
                    iconBg: const Color(0xFFECFDF5),
                    iconColor: const Color(0xFF059669),
                    valueColor: activeCard.isLowBalance ? AppTheme.primaryOrange : const Color(0xFF0F172A),
                    badgeText: activeCard.isLowBalance ? '91% Consumed' : 'Pre-Funded',
                    badgeBg: activeCard.isLowBalance ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                    badgeColor: activeCard.isLowBalance ? const Color(0xFFDC2626) : const Color(0xFF059669),
                    progress: activeCard.monthlyLimit > 0
                        ? (activeCard.currentBalance / activeCard.monthlyLimit).clamp(0.0, 1.0)
                        : 0.0,
                    onTap: () => _showCardDetailsModal(context, provider),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _aestheticKpiCard(
                    title: 'IN-REVIEW POOL',
                    currency: 'SAR',
                    value: provider.claims
                        .where((c) => c.status == ClaimStatus.submitted)
                        .fold(0.0, (s, c) => s + c.grandTotal)
                        .toStringAsFixed(0),
                    subtitle: '${provider.inApprovalCount} claims in approval',
                    icon: Icons.hourglass_top_rounded,
                    iconBg: const Color(0xFFEFF6FF),
                    iconColor: const Color(0xFF2563EB),
                    valueColor: const Color(0xFF2563EB),
                    badgeText: 'Under SLA',
                    badgeBg: const Color(0xFFEFF6FF),
                    badgeColor: const Color(0xFF2563EB),
                    onTap: () => onNavigateTab(3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _aestheticKpiCard(
                    title: 'SETTLED (MTD)',
                    currency: 'SAR',
                    value: provider.claims
                        .where((c) => c.status == ClaimStatus.approved || c.status == ClaimStatus.fullyClosed)
                        .fold(0.0, (s, c) => s + c.grandTotal)
                        .toStringAsFixed(0),
                    subtitle: 'ZATCA Reconciled',
                    icon: Icons.verified_user_rounded,
                    iconBg: const Color(0xFFF1F5F9),
                    iconColor: const Color(0xFF1E2B45),
                    valueColor: const Color(0xFF0F172A),
                    badgeText: 'This Month',
                    badgeBg: const Color(0xFFF1F5F9),
                    badgeColor: const Color(0xFF475569),
                    onTap: () => onNavigateTab(3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _aestheticKpiCard(
                    title: 'APPROVAL SLA',
                    currency: '',
                    value: '~1.8 Days',
                    subtitle: '4-Tier Governance',
                    icon: Icons.speed_rounded,
                    iconBg: const Color(0xFFF0FDFA),
                    iconColor: const Color(0xFF0D9488),
                    valueColor: const Color(0xFF0D9488),
                    badgeText: 'Fast Track',
                    badgeBg: const Color(0xFFF0FDFA),
                    badgeColor: const Color(0xFF0D9488),
                    onTap: null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Section: Claim Status Breakdown
            const Text(
              'CLAIM STATUS BREAKDOWN',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppTheme.textMuted,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _statusKpiTile(
                    title: 'Drafts',
                    count: '${provider.draftsCount}',
                    subtitle: 'Unsubmitted lines',
                    icon: Icons.edit_note_rounded,
                    iconColor: const Color(0xFF475569),
                    iconBg: const Color(0xFFF1F5F9),
                    pillText: 'Editable',
                    onTap: () => onNavigateTab(3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statusKpiTile(
                    title: 'In Approval',
                    count: '${provider.inApprovalCount}',
                    subtitle: 'Active 4-stage review',
                    icon: Icons.hourglass_top_rounded,
                    iconColor: const Color(0xFF2563EB),
                    iconBg: const Color(0xFFEFF6FF),
                    pillText: 'L1 - L4 AP',
                    onTap: () => onNavigateTab(3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _statusKpiTile(
                    title: 'Action Needed',
                    count: '${provider.actionNeededCount}',
                    subtitle: 'Query / rejection',
                    icon: Icons.assignment_late_rounded,
                    iconColor: const Color(0xFFDC2626),
                    iconBg: const Color(0xFFFEF2F2),
                    pillText: provider.actionNeededCount > 0 ? 'Resolve Now' : 'Clear',
                    highlight: provider.actionNeededCount > 0,
                    onTap: () => onNavigateTab(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statusKpiTile(
                    title: 'Fully Closed',
                    count: '${provider.fullyClosedCount}',
                    subtitle: 'Disbursed & SAP posted',
                    icon: Icons.lock_clock_rounded,
                    iconColor: const Color(0xFF7C3AED),
                    iconBg: const Color(0xFFF5F3FF),
                    pillText: 'Archived',
                    onTap: () => onNavigateTab(3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Section: Quick Actions Grid
            const Text(
              'QUICK ACTIONS',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppTheme.textMuted,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    icon: const Icon(Icons.add, size: 17),
                    label: const Text('New Claim', style: TextStyle(fontSize: 13)),
                    onPressed: () {
                      if (!provider.activeUser.hasActiveCard) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Expense claiming is locked until your corporate card is approved and active.'),
                            backgroundColor: AppTheme.navyDark,
                          ),
                        );
                      } else {
                        onNavigateTab(1);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: const BorderSide(color: AppTheme.primaryOrange, width: 1.2),
                      foregroundColor: AppTheme.primaryOrange,
                    ),
                    icon: const Icon(Icons.document_scanner, size: 17),
                    label: const Text('AI OCR Scan', style: TextStyle(fontSize: 13)),
                    onPressed: () async {
                      final scannedData = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OcrScannerScreen(),
                        ),
                      );
                      if (scannedData != null && scannedData is Map<String, dynamic> && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NewClaimScreen(initialScannedReceipt: scannedData),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.badge_outlined, size: 16),
                    label: const Text('Apply for Card', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CardApplicationScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.bolt, size: 16, color: AppTheme.primaryOrange),
                    label: const Text('Request Refill', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      if (!provider.activeUser.hasActiveCard) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Card balance refill requests are only available for active card custodians.'),
                            backgroundColor: AppTheme.navyDark,
                          ),
                        );
                      } else {
                        _showRefillModal(context, provider);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section: Recent Claims
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'RECENT CLAIMS',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMuted,
                    letterSpacing: 1.0,
                  ),
                ),
                TextButton(
                  onPressed: () => onNavigateTab(3),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: AppTheme.primaryOrange,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (claims.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 38, color: AppTheme.textMuted.withValues(alpha: 0.6)),
                    const SizedBox(height: 8),
                    const Text(
                      'No Expense Claims Yet',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Claims will appear here once your corporate petty cash card is active and expenses are submitted.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              )
            else
              ...claims.take(4).map((claim) => _recentClaimTile(context, claim)),
          ],
        ),
      ),
    );
  }

  Widget _statusKpiTile({
    required String title,
    required String count,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String pillText,
    bool highlight = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: highlight ? const Color(0xFFFEF2F2) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: highlight ? const Color(0xFFF87171) : const Color(0xFFE2E8F0),
            width: highlight ? 1.5 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: iconColor, size: 17),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: highlight ? const Color(0xFFFEE2E2) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: highlight ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    pillText,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: highlight ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: highlight ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: highlight ? const Color(0xFF991B1B) : const Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentClaimTile(BuildContext context, ExpenseClaim claim) {
    Color statusColor;
    Color statusBg;
    String statusLabel;
    IconData statusIcon;

    switch (claim.status) {
      case ClaimStatus.draft:
        statusColor = AppTheme.textSecondary;
        statusBg = const Color(0xFFF1F5F9);
        statusLabel = 'Draft';
        statusIcon = Icons.edit_note;
        break;
      case ClaimStatus.submitted:
        statusColor = AppTheme.infoBlue;
        statusBg = AppTheme.infoLight;
        statusLabel = 'In Approval';
        statusIcon = Icons.hourglass_empty;
        break;
      case ClaimStatus.partiallyRejected:
        statusColor = AppTheme.dangerRed;
        statusBg = AppTheme.dangerLight;
        statusLabel = 'Action Needed';
        statusIcon = Icons.warning_amber_rounded;
        break;
      case ClaimStatus.approved:
        statusColor = AppTheme.successGreen;
        statusBg = AppTheme.successLight;
        statusLabel = 'Approved';
        statusIcon = Icons.check_circle_outline;
        break;
      case ClaimStatus.fullyClosed:
        statusColor = AppTheme.closedPurple;
        statusBg = AppTheme.closedLight;
        statusLabel = 'Fully Closed';
        statusIcon = Icons.lock_outline;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ClaimDetailsScreen(claim: claim)),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              claim.docRefNumber,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'SAR ${claim.grandTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryOrange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          claim.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        if (claim.isZatcaVerified || claim.approvalStages.any((s) => s.remainingSlaHours != null)) ...[
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (claim.isZatcaVerified)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    '✓ ZATCA Valid',
                                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                                  ),
                                ),
                              if (claim.approvalStages.any((s) => s.remainingSlaHours != null)) ...[
                                Builder(
                                  builder: (_) {
                                    final activeStage = claim.approvalStages.firstWhere((s) => s.remainingSlaHours != null);
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF7ED),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '⏱ ${activeStage.remainingSlaHours}h SLA',
                                        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppTheme.primaryOrange),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${claim.lines.length} items • ${_formatDate(claim.claimDate)}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (claim.approvalStages.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ApprovalStagePills(stages: claim.approvalStages),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppTheme.textMuted),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _aestheticKpiCard({
    required String title,
    required String currency,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required Color valueColor,
    required String badgeText,
    required Color badgeColor,
    required Color badgeBg,
    double? progress,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.035),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Squircle Icon Badge & Status Chip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: iconColor, size: 17),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Title Micro-label
            Text(
              title,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(height: 4),
            // Main Currency Value
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                if (currency.isNotEmpty) ...[
                  Text(
                    currency,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: valueColor.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(width: 3),
                ],
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: valueColor,
                      fontFamily: 'monospace',
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (progress != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress < 0.15 ? AppTheme.dangerRed : AppTheme.successGreen,
                  ),
                ),
              ),
            ],
            if (subtitle != null) ...[
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCardDetailsModal(BuildContext context, ClaimDeskProvider provider) {
    final card = provider.activeCard;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Petty Cash Card Master Data',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 20),
              _row('Card Number', card.maskedCardNumber),
              _row('Assigned User', card.cardholderName),
              _row('Employee ID', card.employeeId),
              _row('Company', card.company),
              _row('Division', card.division),
              _row('Cost Center', card.costCenter),
              _row('Monthly Limit', 'SAR ${card.monthlyLimit.toStringAsFixed(0)}'),
              _row('Single Swipe Cap', 'SAR ${card.singleTransactionCap.toStringAsFixed(0)}'),
              _row('Current Balance', 'SAR ${card.currentBalance.toStringAsFixed(0)}'),
              _row('Validity Period', '01/01/2026 – 31/12/2026'),
              _row('Status', 'Active (SAMA Compliant)'),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardAppTrackerPill(BuildContext context, CardApplication cardApp) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CardApplicationScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.primaryOrange.withValues(alpha: 0.4)),
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
            const Icon(Icons.credit_card_outlined, color: AppTheme.primaryOrange, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Card Application ${cardApp.id}',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  Text(
                    'Status: ${cardApp.statusDisplay} (Tap to track)',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationInProgressHero(BuildContext context, CardApplication cardApp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
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
          color: AppTheme.primaryOrange.withValues(alpha: 0.6),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D1322).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.hourglass_top, color: AppTheme.primaryOrange, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CARD APPLICATION IN REVIEW',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: Color(0xFFCBD5E1),
                        ),
                      ),
                      Text(
                        cardApp.id,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryOrange, width: 1.0),
                ),
                child: Text(
                  cardApp.statusDisplay,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Target Card Limit:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    Text('SAR ${cardApp.monthlyLimit.toStringAsFixed(0)} / month', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Project WBS / Site:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    Text('${cardApp.projectWbsCode} • ${cardApp.operatingSiteLocation}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11.5)),
                  ],
                ),
                const SizedBox(height: 6),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Approval Stage:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    Text('Stage 3 of 5 (Finance AP Approval)', style: TextStyle(color: AppTheme.primaryOrange, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.timeline, size: 17),
              label: const Text('Track Approval Pipeline & View KYC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CardApplicationScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKycRequiredHero(BuildContext context, UserProfile user) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF182245), // Deep Midnight Navy
            Color(0xFF0F172A),
            Color(0xFF0D1322),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF2D3C65),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF182245).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Directional kinetic chevron watermark overlay
          Positioned.fill(
            child: CustomPaint(
              painter: _HeroChevronPainter(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Step Badge and SAMA Tag
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryOrange.withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.credit_card, size: 13, color: Colors.white),
                          SizedBox(width: 5),
                          Text(
                            'STEP 1 OF 3: KYC & VERIFICATION',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_outlined, size: 12, color: Color(0xFFCBD5E1)),
                          SizedBox(width: 4),
                          Text(
                            'Action Required',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Instrument Header
                const Text(
                  'Pre-Funded Corporate Card',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Welcome, ${user.name.split(' ').first}! Saudi Central Bank (SAMA) & Corporate Compliance KYC verification is required. Upload your National ID/Iqama, Passport, and Specimen Signature to activate your petty cash corporate card.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                // Compliance Features Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _BulletBenefit(text: 'SAMA Tier-1 Compliant', textColor: Colors.white),
                      _BulletBenefit(text: 'WBS Project Funded', textColor: Colors.white),
                      _BulletBenefit(text: 'Absher 2FA Linked', textColor: Colors.white),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Primary Energy Orange Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 3,
                      shadowColor: AppTheme.primaryOrange.withValues(alpha: 0.5),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CardApplicationScreen()),
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.badge_outlined, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Start KYC Onboarding & Request Card',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

class _HeroChevronPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final chevronPaint = Paint()
      ..color = const Color(0xFFF97316).withValues(alpha: 0.08)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final secondaryPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 20
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    for (double x = w - 120; x < w + 80; x += 55) {
      final path = Path()
        ..moveTo(x - 40, -10)
        ..lineTo(x + 20, h / 2)
        ..lineTo(x - 40, h + 10);
      canvas.drawPath(path, chevronPaint);
    }

    for (double x = w - 160; x < w + 40; x += 70) {
      final path2 = Path()
        ..moveTo(x - 50, -20)
        ..lineTo(x + 30, h / 2)
        ..lineTo(x - 50, h + 20);
      canvas.drawPath(path2, secondaryPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BulletBenefit extends StatelessWidget {
  final String text;
  final Color textColor;
  const _BulletBenefit({required this.text, this.textColor = AppTheme.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, size: 13, color: AppTheme.successGreen),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: textColor),
        ),
      ],
    );
  }
}
