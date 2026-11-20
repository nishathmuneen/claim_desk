import 'package:flutter/material.dart';
import '../models/expense_claim.dart';
import '../models/approval_stage.dart';
import '../theme/app_theme.dart';
import 'approval_stage_pills.dart';

/// Unified, luxury enterprise claim card matching the exact design specification.
/// Features a narrow colored left indicator line, squircle status icon badge,
/// golden amount pill, compliant policy badge, status chip, and approval pipeline stepper.
class UnifiedClaimCard extends StatelessWidget {
  final ExpenseClaim claim;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showStepper;
  final Widget? bottomContent;

  const UnifiedClaimCard({
    super.key,
    required this.claim,
    this.onTap,
    this.onLongPress,
    this.showStepper = true,
    this.bottomContent,
  });

  /// Very, very light pastel status accent colors
  Color _getStatusColor() {
    if (claim.hasRejectedLines || claim.status == ClaimStatus.partiallyRejected) {
      return const Color(0xFFFCA5A5); // Very soft pastel coral / rose
    }
    switch (claim.status) {
      case ClaimStatus.draft:
        return const Color(0xFF93C5FD); // Soft sky / powder blue
      case ClaimStatus.submitted:
        final pendingStage = claim.approvalStages.firstWhere(
          (s) => s.status == ApprovalStatus.pending,
          orElse: () => claim.approvalStages.isNotEmpty
              ? claim.approvalStages.first
              : const ApprovalWorkflowStage(
                  stageOrder: 1,
                  roleTitle: '',
                  approverName: '',
                  approverDesignation: '',
                  status: ApprovalStatus.pending,
                ),
        );
        if (pendingStage.stageOrder >= 3) {
          return const Color(0xFFFCD34D); // Light warm pastel amber gold
        } else {
          return const Color(0xFF7DD3FC); // Ultra-light ice blue / soft cyan
        }
      case ClaimStatus.approved:
      case ClaimStatus.fullyClosed:
        return const Color(0xFF86EFAC); // Soft, delicate mint / pale sage green
      case ClaimStatus.partiallyRejected:
        return const Color(0xFFFCA5A5); // Soft pastel coral / rose
    }
  }

  /// Squircle status icon: airy pastel background with crisp tinted icon
  (IconData, Color, Color) _getSquircleIcon() {
    if (claim.hasRejectedLines || claim.status == ClaimStatus.partiallyRejected) {
      return (
        Icons.warning_amber_rounded,
        const Color(0xFFEF4444),
        const Color(0xFFFEF2F2),
      );
    }
    switch (claim.status) {
      case ClaimStatus.draft:
        return (
          Icons.description_outlined,
          const Color(0xFF3B82F6),
          const Color(0xFFF0F7FF),
        );
      case ClaimStatus.submitted:
        final pendingStage = claim.approvalStages.firstWhere(
          (s) => s.status == ApprovalStatus.pending,
          orElse: () => claim.approvalStages.isNotEmpty
              ? claim.approvalStages.first
              : const ApprovalWorkflowStage(
                  stageOrder: 1,
                  roleTitle: '',
                  approverName: '',
                  approverDesignation: '',
                  status: ApprovalStatus.pending,
                ),
        );
        if (pendingStage.stageOrder >= 3) {
          return (
            Icons.hourglass_top_rounded,
            const Color(0xFFD97706),
            const Color(0xFFFFFBEB),
          );
        } else {
          return (
            Icons.hourglass_top_rounded,
            const Color(0xFF0284C7),
            const Color(0xFFF0F9FF),
          );
        }
      case ClaimStatus.approved:
      case ClaimStatus.fullyClosed:
        return (
          Icons.check_circle_outline_rounded,
          const Color(0xFF16A34A),
          const Color(0xFFF0FDF4),
        );
      case ClaimStatus.partiallyRejected:
        return (
          Icons.warning_amber_rounded,
          const Color(0xFFEF4444),
          const Color(0xFFFEF2F2),
        );
    }
  }

  /// Refined, soft status chips
  Widget _buildStatusChip() {
    if (claim.hasRejectedLines || claim.status == ClaimStatus.partiallyRejected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.5, vertical: 3.0),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFECDD3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 12.0,
              color: Color(0xFFE11D48),
            ),
            SizedBox(width: 3.5),
            Text(
              'Action Needed',
              softWrap: false,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE11D48),
              ),
            ),
          ],
        ),
      );
    }
    switch (claim.status) {
      case ClaimStatus.draft:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.0),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_outlined, size: 12, color: Color(0xFF64748B)),
              SizedBox(width: 3.5),
              Text(
                'Draft',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        );
      case ClaimStatus.submitted:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.0),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBAE6FD)),
          ),
          child: const Text(
            'In Approval',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0284C7),
            ),
          ),
        );
      case ClaimStatus.approved:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.0),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: const Text(
            'Approved',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF15803D),
            ),
          ),
        );
      case ClaimStatus.fullyClosed:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.0),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF5FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE9D5FF)),
          ),
          child: const Text(
            'Fully Closed',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7E22CE),
            ),
          ),
        );
      case ClaimStatus.partiallyRejected:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.5, vertical: 3.0),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFECDD3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 12.0,
                color: Color(0xFFE11D48),
              ),
              SizedBox(width: 3.5),
              Text(
                'Action Needed',
                softWrap: false,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE11D48),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildCompliantBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, size: 12, color: Color(0xFF059669)),
          SizedBox(width: 3.5),
          Text(
            'Compliant with Policy',
            style: TextStyle(
              fontSize: 10.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF047857),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatCurrency(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final wholePart = parts[0];
    final decPart = parts[1];
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formatted = wholePart.replaceAllMapped(reg, (Match m) => '${m[1]},');
    return 'SAR $formatted.$decPart';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final (iconData, iconColor, iconBg) = _getSquircleIcon();
    final cleanRef = claim.docRefNumber.startsWith('#')
        ? claim.docRefNumber
        : '#${claim.docRefNumber}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFEF08A).withValues(alpha: 0.45),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(
          children: [
            // 1. Ultra-light, pleasant warm champagne gold gradient surface
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFFFFD),
                      Color(0xFFFEF8EC),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Very light pastel status indicator stripe (3.5px wide)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 3.5,
              child: Container(
                color: statusColor,
              ),
            ),

            // 3. Card Content & Tap Area
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                onLongPress: onLongPress,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 14.0, 14.0, 14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Squircle Status Icon Badge (42x42px, radius 12px)
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: iconBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Icon(iconData, color: iconColor, size: 21),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Main Content Column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header: #Ref Number and Lightest Champagne Gold Amount Pill
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      cleanRef,
                                      style: const TextStyle(
                                        fontSize: 15.0,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFFDF5), // Lightest warm champagne cream
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: const Color(0xFFFEF08A), width: 0.8), // Delicate pale gold
                                      ),
                                      child: Text(
                                        _formatCurrency(claim.grandTotal),
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF92400E), // Refined warm honey gold
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),

                                // Description
                                Text(
                                  claim.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                                const SizedBox(height: 5),

                                // Row 1: Date & optional Location
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 12.5,
                                      color: Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDate(claim.claimDate),
                                      style: const TextStyle(
                                        fontSize: 11.0,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    if (claim.projectCode != null) ...[
                                      const SizedBox(width: 6),
                                      const Text(
                                        '|',
                                        style: TextStyle(fontSize: 11.0, color: Color(0xFFCBD5E1)),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.location_on_outlined,
                                        size: 13,
                                        color: Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: Text(
                                          claim.projectCode!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11.0,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // Row 2: Compliant with Policy badge on left, Status chip on right
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildCompliantBadge(),
                                    _buildStatusChip(),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Approval Stepper Pipeline (for non-draft claims)
                      if (showStepper &&
                          claim.status != ClaimStatus.draft &&
                          claim.approvalStages.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ApprovalStagePills(stages: claim.approvalStages),
                      ],

                      // Action Needed Callout (if rejected lines exist and no custom bottomContent)
                      if (claim.hasRejectedLines && bottomContent == null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.dangerLight,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.dangerRed.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.assignment_late, size: 12, color: AppTheme.dangerRed),
                              SizedBox(width: 4),
                              Text(
                                'Action Needed: 1 item requires resubmission',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.dangerRed,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Optional Screen-Specific Bottom Content
                      if (bottomContent != null) ...[
                        const SizedBox(height: 8),
                        bottomContent!,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
