import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/claim_desk_provider.dart';
import '../widgets/active_card_card.dart';
import '../models/expense_claim.dart';
import 'ocr_scanner_screen.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int) onNavigateTab;

  const DashboardScreen({super.key, required this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClaimDeskProvider>();
    final activeCard = provider.activeCard;
    final claims = provider.claims;

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
            // Deep Navy Petty Cash Card (Image 2 style against light background)
            ActiveCardCard(
              card: activeCard,
              onTap: () {
                _showCardDetailsModal(context, provider);
              },
            ),
            const SizedBox(height: 20),

            // Section: Quick Stats (4 KPIs)
            const Text(
              'OVERVIEW',
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
                  child: _kpiCard(
                    title: 'Drafts',
                    count: '${provider.draftsCount}',
                    icon: Icons.edit_note,
                    color: AppTheme.textSecondary,
                    bgColor: AppTheme.surface,
                    onTap: () => onNavigateTab(3),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _kpiCard(
                    title: 'In Approval',
                    count: '${provider.inApprovalCount}',
                    icon: Icons.hourglass_top,
                    color: AppTheme.infoBlue,
                    bgColor: AppTheme.infoLight,
                    onTap: () => onNavigateTab(3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _kpiCard(
                    title: 'Action Needed',
                    count: '${provider.actionNeededCount}',
                    icon: Icons.assignment_late,
                    color: AppTheme.dangerRed,
                    bgColor: AppTheme.dangerLight,
                    highlight: provider.actionNeededCount > 0,
                    onTap: () => onNavigateTab(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _kpiCard(
                    title: 'Fully Closed',
                    count: '${provider.fullyClosedCount}',
                    icon: Icons.lock_outline,
                    color: AppTheme.closedPurple,
                    bgColor: AppTheme.closedLight,
                    onTap: () => onNavigateTab(3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Section: Quick Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Claim'),
                    onPressed: () => onNavigateTab(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppTheme.primaryOrange, width: 1.4),
                      foregroundColor: AppTheme.primaryOrange,
                    ),
                    icon: const Icon(Icons.document_scanner, size: 18),
                    label: const Text('AI OCR Scan'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OcrScannerScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),

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

            ...claims.take(4).map((claim) => _recentClaimTile(context, claim)),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required Color bgColor,
    bool highlight = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: highlight ? color : AppTheme.border,
            width: highlight ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
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
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
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
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
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
      ),
    );
  }

  void _showCardDetailsModal(BuildContext context, ClaimDeskProvider provider) {
    final card = provider.activeCard;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Card Custodian Assignment',
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
              _row('Assignment Period', '01/01/2026 to 31/12/2026'),
              _row('Status', 'Active'),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
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
