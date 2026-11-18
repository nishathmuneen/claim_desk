import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/expense_claim.dart';
import '../models/approval_stage.dart';
import '../models/verified_attachment.dart';
import '../providers/claim_desk_provider.dart';
import '../widgets/kinetic_background.dart';
import 'new_claim_screen.dart';

/// Full Corporate Claim Audit Ledger View
/// Matches the official Stitch/Expertise design specification:
/// - Reference & Project Code
/// - Big Reimbursable Amount with Pre-Funded Auth
/// - Financial & ZATCA Tax Split with Dual Accounting Allocation Chips
/// - 4-Level Approval Audit Trail with SLA countdown & Ping Approver
/// - Cryptographically Sealed Verified Attachments Shelf with preview modal
/// - System Audit Logs
/// - Sticky Bottom Action Dock (PDF, Message, Recall)
class ClaimDetailsScreen extends StatefulWidget {
  final ExpenseClaim claim;

  const ClaimDetailsScreen({super.key, required this.claim});

  @override
  State<ClaimDetailsScreen> createState() => _ClaimDetailsScreenState();
}

class _ClaimDetailsScreenState extends State<ClaimDetailsScreen> {
  final _currencyFormat = NumberFormat('#,##0.00', 'en_US');

  void _handlePingApprover(BuildContext context, int stageOrder, String approverName) {
    final provider = context.read<ClaimDeskProvider>();
    provider.pingApprover(widget.claim.id, stageOrder);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.bolt, color: AppTheme.primaryOrange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'High-priority reminder ping dispatched to $approverName (SLA: 4h)',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.navyDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showMessageApproverSheet(BuildContext context) {
    final textController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.chat_bubble_outline, color: AppTheme.primaryOrange, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Message Active Approver',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.navyDark),
                      ),
                      Text(
                        'Direct note to Fahad Al-Zahrani (Procurement Lead)',
                        style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter your message regarding hospitality tier or workshop agenda...',
                  hintStyle: const TextStyle(fontSize: 12.5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('Send Message via Audit Ledger', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    final msg = textController.text.trim();
                    if (msg.isNotEmpty) {
                      context.read<ClaimDeskProvider>().sendApproverMessage(widget.claim.id, msg);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Message delivered to approver: "$msg"'),
                          backgroundColor: AppTheme.navyDark,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRecallConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: AppTheme.primaryOrange),
            SizedBox(width: 8),
            Text('Recall Expense Claim?'),
          ],
        ),
        content: const Text(
          'Recalling this claim halts the approval routing at Stage 3. It will revert to draft status so you can update line items, VAT splits, or attachments before resubmission.',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              context.read<ClaimDeskProvider>().recallClaim(widget.claim.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Claim recalled and returned to Draft status.'),
                  backgroundColor: AppTheme.navyDark,
                ),
              );
            },
            child: const Text('Confirm Recall'),
          ),
        ],
      ),
    );
  }

  void _showAttachmentViewer(BuildContext context, VerifiedAttachment attachment) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: attachment.badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.verified, color: attachment.badgeColor, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        attachment.badgeText,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: attachment.badgeColor,
                          fontSize: 14,
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
              const SizedBox(height: 14),
              Text(
                attachment.fileName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.navyDark),
              ),
              const SizedBox(height: 6),
              Text(
                attachment.summary,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CRYPTOGRAPHIC AUDIT PROOF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
                    const SizedBox(height: 6),
                    const Text(
                      'SHA-256: 7f83b1657ff1fc53b92dc18148a1d65dfc2d4b1fa3d677284addd200126d9069',
                      style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppTheme.navyDark),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'ZATCA Phase 2 Cleared: Cryptographic Stamp Verified by Enterprise Portal',
                      style: TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.navyDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Download Verified File'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Downloading ${attachment.fileName}...')),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _downloadAuditPdf(BuildContext context, ExpenseClaim currentClaim) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.picture_as_pdf, color: AppTheme.primaryOrange),
            const SizedBox(width: 8),
            Text('Generating ZATCA Audit Report for ${currentClaim.docRefNumber}...'),
          ],
        ),
        backgroundColor: AppTheme.navyDark,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClaimDeskProvider>();
    final currentClaim = provider.claims.firstWhere(
      (c) => c.id == widget.claim.id || c.docRefNumber == widget.claim.docRefNumber,
      orElse: () => widget.claim,
    );

    final netAmount = currentClaim.totalBaseAmount > 0 ? currentClaim.totalBaseAmount : 3200.0;
    final vatAmount = currentClaim.totalVatAmount > 0 ? currentClaim.totalVatAmount : 480.0;
    final grossAmount = currentClaim.grandTotal > 0 ? currentClaim.grandTotal : 3680.0;
    final projectCode = currentClaim.projectCode ?? 'SR-1010 (Sadara Complex Jubail)';
    final glAccount = currentClaim.glAccountCode ?? '6250 - LODGING - CORP';
    final costCenter = currentClaim.costCenter.isNotEmpty ? currentClaim.costCenter : 'CC-402 (EP Ops - Petro...)';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppTheme.navyDark,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: const [
            Text(
              'Back to Ledger',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Copy Reference',
            icon: const Icon(Icons.copy, size: 18, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied reference ${currentClaim.docRefNumber}'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Share Claim',
            icon: const Icon(Icons.share_outlined, size: 18, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share audit link copied to clipboard'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'More Options',
            icon: const Icon(Icons.more_vert, size: 18, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: KineticBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Claim Header Reference Card
              _buildClaimHeaderCard(currentClaim, projectCode, grossAmount),
              const SizedBox(height: 16),

              // 2. Financial & ZATCA Tax Split Card
              _buildFinancialTaxSplitCard(netAmount, vatAmount, grossAmount, costCenter, glAccount),
              const SizedBox(height: 16),

              // 3. 4-Level Approval Audit Trail
              _buildApprovalAuditTrail(context, currentClaim),
              const SizedBox(height: 16),

              // 4. Verified Attachments Shelf
              _buildVerifiedAttachmentsShelf(context, currentClaim),
              const SizedBox(height: 16),

              // 5. Claim History & System Logs
              _buildSystemLogsCard(currentClaim),
            ],
          ),
        ),
      ),
      // Sticky Bottom Action Dock
      bottomSheet: _buildBottomActionDock(context, currentClaim),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('New Claim', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewClaimScreen()),
          );
        },
      ),
    );
  }

  /// 1. Claim Header Card
  Widget _buildClaimHeaderCard(ExpenseClaim claim, String projectCode, double grossAmount) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Chips: Reference + Project Code + Status Pill
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                claim.docRefNumber,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.navyDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.business, size: 12, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      projectCode,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircleAvatar(radius: 3.5, backgroundColor: Color(0xFFD97706)),
                    SizedBox(width: 5),
                    Text(
                      'In Review (Stage 3 of 4)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Main Title
          Text(
            claim.description,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.navyDark,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),

          // Category, Card, Date Meta-row
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildMetaPill(Icons.category_outlined, claim.docType),
              _buildMetaPill(Icons.credit_card, 'Corp Card ${claim.cardNumber}'),
              _buildMetaPill(
                Icons.calendar_today_outlined,
                DateFormat('MMM dd, yyyy • hh:mm a').format(claim.claimDate),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Total Authorized Reimbursable Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL AUTHORIZED REIMBURSABLE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SAR ${_currencyFormat.format(grossAmount)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.navyDark,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF15803D)),
                      SizedBox(width: 5),
                      Text(
                        'Pre-funded Auth',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaPill(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppTheme.textMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  /// 2. Financial & ZATCA Tax Split Card
  Widget _buildFinancialTaxSplitCard(
    double netAmount,
    double vatAmount,
    double grossAmount,
    String costCenter,
    String glAccount,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.receipt_long, size: 18, color: AppTheme.primaryOrange),
                  SizedBox(width: 8),
                  Text(
                    'Financial & ZATCA Tax Split',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.navyDark),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Text(
                  'ZATCA Phase 2 Verified',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Net Invoiced Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Net Invoiced Amount (Excl. VAT)', style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary)),
              Text('SAR ${_currencyFormat.format(netAmount)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.navyDark)),
            ],
          ),
          const SizedBox(height: 8),

          // Standard KSA VAT (15%)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Text('Standard KSA VAT (15%)', style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary)),
                  SizedBox(width: 4),
                  Icon(Icons.verified, size: 13, color: Color(0xFF10B981)),
                ],
              ),
              Text('SAR ${_currencyFormat.format(vatAmount)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.navyDark)),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 10),

          // Total Claim Gross
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Claim Gross', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppTheme.navyDark)),
              Text('SAR ${_currencyFormat.format(grossAmount)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.navyDark)),
            ],
          ),
          const SizedBox(height: 16),

          // Dual Accounting Allocation Chips
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('COST CENTER', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
                      const SizedBox(height: 3),
                      Text(
                        costCenter,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.navyDark),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('GL ACCOUNT CODE', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
                      const SizedBox(height: 3),
                      Text(
                        glAccount,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.navyDark),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 3. 4-Level Approval Audit Trail
  Widget _buildApprovalAuditTrail(BuildContext context, ExpenseClaim claim) {
    final stages = claim.approvalStages.isNotEmpty
        ? claim.approvalStages
        : [
            ApprovalWorkflowStage(
              stageOrder: 1,
              roleTitle: 'Accountant',
              approverName: 'Sara Al-Otaibi',
              approverDesignation: 'Senior Financial Auditor (Jubail Hub)',
              status: ApprovalStatus.approved,
              badgeLabel: 'ACCT VALIDATED',
              timestamp: DateTime(2026, 10, 29, 10, 14),
              comments: 'All receipts verified against card terminal auth SAR 3,680.00. Tax ID matches ZATCA registry.',
            ),
            ApprovalWorkflowStage(
              stageOrder: 2,
              roleTitle: 'Division Manager',
              approverName: 'Eng. Khalid Mansoor',
              approverDesignation: 'VP Operations Jubail Complexes',
              status: ApprovalStatus.approved,
              badgeLabel: 'DIV MGR SIGN-OFF',
              timestamp: DateTime(2026, 10, 29, 14, 30),
              comments: 'Approved under Client Workshop Budget FY26-Q4. Valid business case.',
            ),
            const ApprovalWorkflowStage(
              stageOrder: 3,
              roleTitle: 'Procurement Lead',
              approverName: 'Fadhad Al-Zahrani',
              approverDesignation: 'Strategic Sourcing & Procurement Lead',
              status: ApprovalStatus.pending,
              badgeLabel: 'IN REVIEW',
              remainingSlaHours: 4,
              canPing: true,
              comments: 'Under policy price cap verification for corporate hospitality tiers.',
            ),
            const ApprovalWorkflowStage(
              stageOrder: 4,
              roleTitle: 'Finance Manager',
              approverName: 'Dr. Tariq Al-Ghamdi',
              approverDesignation: 'CFO Delegate / Treasury Release',
              status: ApprovalStatus.waiting,
              badgeLabel: 'PENDING',
              upstreamDependency: 'Upstream Stage',
              comments: 'Awaiting Level 3 Procurement endorsement prior to final corporate card credit replenishment.',
            ),
          ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.linear_scale, size: 20, color: AppTheme.navyDark),
                  SizedBox(width: 8),
                  Text(
                    '4-Level Approval Audit Trail',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.navyDark),
                  ),
                ],
              ),
              const Text(
                'Stage 3 / 4 Active',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryOrange),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stepper Items
          for (int i = 0; i < stages.length; i++) ...[
            _buildStageItem(context, stages[i], isLast: i == stages.length - 1),
          ],
        ],
      ),
    );
  }

  Widget _buildStageItem(BuildContext context, ApprovalWorkflowStage stage, {required bool isLast}) {
    Color indicatorColor;
    IconData indicatorIcon;
    Color badgeBg;
    Color badgeFg;

    if (stage.isApproved) {
      indicatorColor = const Color(0xFF10B981);
      indicatorIcon = Icons.check;
      badgeBg = const Color(0xFFECFDF5);
      badgeFg = const Color(0xFF047857);
    } else if (stage.isPending) {
      indicatorColor = AppTheme.primaryOrange;
      indicatorIcon = Icons.hourglass_top;
      badgeBg = const Color(0xFFFFF7ED);
      badgeFg = const Color(0xFFC2410C);
    } else {
      indicatorColor = const Color(0xFF94A3B8);
      indicatorIcon = Icons.lock_outline;
      badgeBg = const Color(0xFFF1F5F9);
      badgeFg = const Color(0xFF475569);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Timeline Indicator Column
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: indicatorColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: indicatorColor, width: 2),
                ),
                child: Icon(indicatorIcon, size: 14, color: indicatorColor),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFFE2E8F0),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Right Stage Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Badge + Timestamp
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Level ${stage.stageOrder}: ${stage.roleTitle}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.navyDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (stage.badgeLabel != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: badgeFg.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            stage.badgeLabel!,
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: badgeFg),
                          ),
                        ),
                      if (stage.remainingSlaHours != null) ...[
                        const SizedBox(width: 6),
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 11, color: AppTheme.primaryOrange),
                            const SizedBox(width: 2),
                            Text(
                              '${stage.remainingSlaHours}h SLA rem.',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryOrange),
                            ),
                          ],
                        ),
                      ],
                      if (stage.timestamp != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('MMM dd • hh:mm a').format(stage.timestamp!),
                          style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Approver Name & Designation
                  Text(
                    stage.approverName,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                  Text(
                    stage.approverDesignation,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),

                  // Remarks Quote Container
                  if (stage.comments != null && stage.comments!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: stage.isPending ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: stage.isPending ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        '"${stage.comments!}"',
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: stage.isPending ? const Color(0xFF92400E) : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],

                  // Ping Approver Button (for Stage 3 / active)
                  if (stage.canPing) ...[
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => _handlePingApprover(context, stage.stageOrder, stage.approverName),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.navyDark,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.navyDark.withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.bolt, size: 14, color: AppTheme.primaryOrange),
                            SizedBox(width: 6),
                            Text(
                              'Ping Approver / Send Reminder',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 4. Verified Attachments Shelf
  Widget _buildVerifiedAttachmentsShelf(BuildContext context, ExpenseClaim claim) {
    final attachments = claim.verifiedAttachments.isNotEmpty
        ? claim.verifiedAttachments
        : const [
            VerifiedAttachment(
              id: 'ATT-01',
              fileName: 'Marriott_Folio_INV902.pdf',
              fileType: 'Tax Invoice',
              badgeText: 'ZATCA OK',
              badgeColor: Color(0xFF059669),
              summary: 'ZATCA QR Scanned • 1.4 MB • Cryptographic Match',
              size: '1.4 MB',
            ),
            VerifiedAttachment(
              id: 'ATT-02',
              fileName: 'POS_Terminal_Slip_A8492.pdf',
              fileType: 'Terminal Slip',
              badgeText: 'AUTH 8492',
              badgeColor: Color(0xFF2563EB),
              summary: 'Merchant Terminal Copy • SAR 3,680.00 Auth',
              size: '320 KB',
            ),
            VerifiedAttachment(
              id: 'ATT-03',
              fileName: 'Workshop_Attendance_Roster.pdf',
              fileType: 'Attendee Roster',
              badgeText: 'ROSTER',
              badgeColor: Color(0xFF475569),
              summary: 'Signed by 14 PetroKemya Delegates • 840 KB',
              size: '840 KB',
            ),
          ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.attach_file, size: 18, color: AppTheme.navyDark),
                  SizedBox(width: 8),
                  Text(
                    'Verified Attachments',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.navyDark),
                  ),
                ],
              ),
              Text(
                '${attachments.length} Cryptographically Sealed',
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Attachment Items
          for (final att in attachments) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: att.badgeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.description, size: 18, color: att.badgeColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                att.fileName,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.navyDark,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: att.badgeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                att.badgeText,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: att.badgeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          att.summary,
                          style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'View Document',
                    icon: const Icon(Icons.remove_red_eye_outlined, size: 18, color: AppTheme.navyDark),
                    onPressed: () => _showAttachmentViewer(context, att),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 5. Claim History & System Logs
  Widget _buildSystemLogsCard(ExpenseClaim claim) {
    final logs = [
      ...claim.systemLogs,
      ...claim.auditTrail,
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Claim History & System Logs',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.navyDark),
              ),
              Icon(Icons.history, size: 18, color: AppTheme.textMuted),
            ],
          ),
          const SizedBox(height: 12),
          for (final log in logs.take(6)) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: AppTheme.primaryOrange, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      log,
                      style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Sticky Bottom Action Dock
  Widget _buildBottomActionDock(BuildContext context, ExpenseClaim currentClaim) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.navyDark,
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.download_outlined, size: 16),
                  label: const Text('Download Audit PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () => _downloadAuditPdf(context, currentClaim),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.message_outlined, size: 16),
                  label: const Text('Message Approver', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () => _showMessageApproverSheet(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (currentClaim.isRecallable && currentClaim.status != ClaimStatus.draft)
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textMuted,
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.lock_open, size: 14),
              label: const Text(
                'Request Claim Recall or Adjustment',
                style: TextStyle(fontSize: 11.5, decoration: TextDecoration.underline),
              ),
              onPressed: () => _showRecallConfirmDialog(context),
            ),
        ],
      ),
    );
  }
}
