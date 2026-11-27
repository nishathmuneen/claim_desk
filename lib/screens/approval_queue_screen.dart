import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/expense_claim.dart';
import '../providers/claim_desk_provider.dart';

class ApprovalQueueScreen extends StatelessWidget {
  const ApprovalQueueScreen({super.key});

  void _showRejectDialog(
    BuildContext context,
    ClaimDeskProvider provider,
    ExpenseClaim claim,
    ExpenseLineItem line,
  ) {
    final commentCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.report_problem_rounded, color: AppTheme.dangerRed, size: 22),
            SizedBox(width: 8),
            Text('Reject Line Item', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${claim.docRefNumber} • ${line.category} (SAR ${line.totalAmount.toStringAsFixed(2)})',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: commentCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Mandatory Rejection Comment (BRD 5.4)',
                  hintText: 'Explain why this line is rejected so custodian can resubmit...',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'A rejection comment is required';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              provider.rejectClaimLine(claim.id, line.id, commentCtrl.text);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppTheme.navyDark,
                  content: Text('Line rejected and returned to ${claim.employeeName}.'),
                ),
              );
            },
            child: const Text('Confirm Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClaimDeskProvider>();
    final queue = provider.pendingApprovalClaims;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'APPROVAL QUEUE',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Line-level review & stage sign-off (BRD 5.4)',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${queue.length} Pending',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (queue.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.verified_outlined, size: 42, color: Color(0xFF059669)),
                  SizedBox(height: 10),
                  Text(
                    'All Claims Reviewed',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'There are no pending claims waiting for line-level approval.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            )
          else
            ...queue.map((claim) => _buildClaimApprovalCard(context, provider, claim)),
        ],
      ),
    );
  }

  Widget _buildClaimApprovalCard(
    BuildContext context,
    ClaimDeskProvider provider,
    ExpenseClaim claim,
  ) {
    final activeStage = claim.approvalStages.cast<dynamic>().firstWhere(
          (s) => s.status.toString().contains('pending'),
          orElse: () => null,
        );
    final stageLabel = activeStage != null ? 'Stage ${activeStage.stageOrder}: ${activeStage.roleTitle}' : 'In Review';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFD), Color(0xFFFEF8EC)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFEF08A).withValues(alpha: 0.55), width: 0.9),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      claim.docRefNumber,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${claim.employeeName} • ${DateFormat('dd MMM yyyy').format(claim.claimDate)}',
                      style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'SAR ${claim.grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: AppTheme.goldDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            claim.description,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              stageLabel,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
            ),
          ),
          const Divider(height: 18),
          ...claim.lines.asMap().entries.map((entry) {
            final idx = entry.key;
            final line = entry.value;
            final isApproved = line.status == LineStatus.approved;
            final isRejected = line.status == LineStatus.rejected;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isRejected
                      ? const Color(0xFFFCA5A5)
                      : isApproved
                          ? const Color(0xFF86EFAC)
                          : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '#${idx + 1} ${line.category} (${line.invoiceNumber})',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        'SAR ${line.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    line.paymentSource == PaymentSource.cashAdvance ? 'Source: Cash Advance' : 'Source: Card Swipe',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                  if (isRejected && line.rejectionComment != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Rejected: ${line.rejectionComment}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.dangerRed, fontWeight: FontWeight.w600),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!isRejected)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.dangerRed,
                            side: const BorderSide(color: Color(0xFFFCA5A5)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                          icon: const Icon(Icons.close, size: 14),
                          label: const Text('Reject', style: TextStyle(fontSize: 11.5)),
                          onPressed: () => _showRejectDialog(context, provider, claim, line),
                        ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isApproved ? const Color(0xFF059669) : AppTheme.primaryOrange,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                        ),
                        icon: Icon(isApproved ? Icons.check_circle : Icons.check, size: 14),
                        label: Text(
                          isApproved ? 'Approved' : 'Approve Line',
                          style: const TextStyle(fontSize: 11.5),
                        ),
                        onPressed: () => provider.approveClaimLine(claim.id, line.id),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.navyDark,
                padding: const EdgeInsets.symmetric(vertical: 11),
              ),
              icon: const Icon(Icons.done_all_rounded, size: 17),
              label: const Text('Approve All Lines & Advance Stage', style: TextStyle(fontWeight: FontWeight.w700)),
              onPressed: () {
                provider.approveAllLinesInClaim(claim.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.navyDark,
                    content: Text('${claim.docRefNumber} approved and advanced to next stage.'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

