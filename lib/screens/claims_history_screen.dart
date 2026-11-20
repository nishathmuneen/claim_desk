import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/claim_desk_provider.dart';
import '../models/expense_claim.dart';
import '../models/approval_stage.dart';
import '../widgets/approval_pipeline_stepper.dart';
import '../widgets/period_filter_bar.dart';
import '../widgets/unified_claim_card.dart';
import 'new_claim_screen.dart';
import 'resubmission_screen.dart';
import 'claim_details_screen.dart';

class ClaimsHistoryScreen extends StatefulWidget {
  const ClaimsHistoryScreen({super.key});

  @override
  State<ClaimsHistoryScreen> createState() => _ClaimsHistoryScreenState();
}

class _ClaimsHistoryScreenState extends State<ClaimsHistoryScreen> {
  String _selectedFilter = 'All';
  final _searchController = TextEditingController();
  DateFilterPeriod _selectedPeriod = DateFilterPeriod.mtd;
  DateTimeRange? _customDateRange;

  final List<String> _filters = [
    'All',
    'Drafts',
    'In Review',
    'Needs Action',
    'Approved',
    'Fully Closed',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isClaimInPeriod(ExpenseClaim claim) {
    final now = DateTime.now();
    final claimDate = claim.claimDate;

    switch (_selectedPeriod) {
      case DateFilterPeriod.wtd:
        // Week to Date (Assuming Sunday is start of week in Saudi Arabia)
        final daysSinceSunday = claimDate.weekday % 7;
        final startOfWeek = DateTime(now.year, now.month, now.day - daysSinceSunday);
        return claimDate.isAfter(startOfWeek.subtract(const Duration(seconds: 1)));

      case DateFilterPeriod.mtd:
        // Month to Date (1st of current month)
        final startOfMonth = DateTime(now.year, now.month, 1);
        return claimDate.isAfter(startOfMonth.subtract(const Duration(seconds: 1)));

      case DateFilterPeriod.ytd:
        // Year to Date (Jan 1st of current year)
        final startOfYear = DateTime(now.year, 1, 1);
        return claimDate.isAfter(startOfYear.subtract(const Duration(seconds: 1)));

      case DateFilterPeriod.customRange:
        if (_customDateRange == null) return true;
        return claimDate.isAfter(_customDateRange!.start.subtract(const Duration(seconds: 1))) &&
            claimDate.isBefore(_customDateRange!.end.add(const Duration(days: 1)));
    }
  }

  void _showClaimDetails(BuildContext context, ExpenseClaim claim, {bool asSheet = false}) {
    if (asSheet) {
      _showLegacyClaimBottomSheet(context, claim);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClaimDetailsScreen(claim: claim)),
    );
  }

  void _showLegacyClaimBottomSheet(BuildContext context, ExpenseClaim claim) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: ListView(
                controller: scrollController,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            claim.docRefNumber,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            claim.docType,
                            style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20, color: AppTheme.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Financial Totals with Two-Tone Net vs 15% VAT Ratio Bar
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            const Text(
                              'TOTAL CLAIM VALUE',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 0.8),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF6EE7B7)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified, size: 11, color: Color(0xFF065F46)),
                                  SizedBox(width: 3),
                                  Text('ZATCA 15% Verified', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF065F46))),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'SAR ${claim.grandTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Net: SAR ${claim.totalBaseAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary)),
                                Text('VAT: SAR ${claim.totalVatAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.primaryOrange)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Proportional Two-Tone Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 87,
                                child: Container(
                                  height: 6,
                                  color: const Color(0xFF1E2B45),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                flex: 13,
                                child: Container(
                                  height: 6,
                                  color: AppTheme.primaryOrange,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Pre-Tax Business Expense (86.96%)', style: TextStyle(fontSize: 9.5, color: AppTheme.textMuted)),
                            Text('Recoverable Input Tax (13.04%)', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppTheme.primaryOrange)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // BRD Section 5.6: Post-Approval Financial Closure Card (if Fully Closed)
                  if (claim.status == ClaimStatus.fullyClosed) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.closedLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.closedPurple.withValues(alpha: 0.35)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.lock, color: AppTheme.closedPurple, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'FULLY CLOSED (BRD Section 5.6)',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.closedPurple,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _detailRow('Payment Status', claim.paymentStatus ?? 'Paid', valueColor: AppTheme.successGreen),
                          _detailRow('Payment Number', claim.paymentNumber ?? 'N/A'),
                          _detailRow('SAP Document Ref #', claim.sapDocRefNumber ?? 'N/A', valueColor: AppTheme.primaryOrange),
                          const SizedBox(height: 8),
                          const Text(
                            'Final financial references captured. No further edits allowed.',
                            style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Multi-Level Approval Pipeline Visualizer
                  if (claim.approvalStages.isNotEmpty) ...[
                    ApprovalPipelineStepper(stages: claim.approvalStages),
                    const Divider(height: 28),
                  ],

                  // Claim Header Info
                  _detailRow('Claim Date', _formatDate(claim.claimDate)),
                  _detailRow('Cost Center', claim.costCenter),
                  _detailRow('Petty Cash Card', claim.cardNumber),
                  _detailRow('Business Description', claim.description),
                  const Divider(height: 24),

                  // Line Items
                  const Text(
                    'LINE ITEMS',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 8),
                  ...claim.lines.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final line = entry.value;
                    Color lineStatusColor = AppTheme.textSecondary;
                    Color lineStatusBg = const Color(0xFFF1F5F9);
                    String lineStatusText = 'Pending';
                    if (line.status == LineStatus.approved) {
                      lineStatusColor = AppTheme.successGreen;
                      lineStatusBg = AppTheme.successLight;
                      lineStatusText = 'Approved';
                    }
                    if (line.status == LineStatus.rejected) {
                      lineStatusColor = AppTheme.dangerRed;
                      lineStatusBg = AppTheme.dangerLight;
                      lineStatusText = 'Rejected';
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: lineStatusColor.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '#${idx + 1} ${line.category}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: lineStatusBg,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      lineStatusText,
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: lineStatusColor),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'SAR ${line.totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryOrange),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Invoice: ${line.invoiceNumber} • VAT: SAR ${line.vatAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                          ),
                          if (line.attachmentName != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.attach_file, size: 13, color: AppTheme.successGreen),
                                const SizedBox(width: 4),
                                Text(line.attachmentName!, style: const TextStyle(fontSize: 11, color: AppTheme.successGreen)),
                              ],
                            ),
                          ],
                          if (line.rejectionComment != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.dangerLight,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.dangerRed.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                'Approver: ${line.rejectionComment}',
                                style: const TextStyle(fontSize: 11.5, color: AppTheme.dangerRed, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 12),
                  // Totals
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount Claimed',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                      ),
                      Text(
                        'SAR ${claim.grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primaryOrange),
                      ),
                    ],
                  ),
                  const Divider(height: 30),

                  // Full Audit Trail
                  const Text(
                    'AUDIT TRAIL & HISTORY',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 10),
                  ...claim.auditTrail.map((log) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 4.0),
                              child: Icon(Icons.circle, size: 7, color: AppTheme.primaryOrange),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(log, style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary)),
                            ),
                          ],
                        ),
                      )),
                  // Attached ZATCA Invoices Carousel
                  if (claim.lines.any((l) => l.attachmentName != null)) ...[
                    const Divider(height: 30),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ATTACHED ZATCA INVOICES',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 0.8),
                        ),
                        Text('Cryptographic Stamp Valid', style: TextStyle(fontSize: 10.5, color: AppTheme.successGreen, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 82,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: claim.lines.where((l) => l.attachmentName != null).length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (ctx, i) {
                          final item = claim.lines.where((l) => l.attachmentName != null).toList()[i];
                          return Container(
                            width: 170,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.receipt_long, size: 16, color: AppTheme.primaryOrange),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        item.attachmentName!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('SAR ${item.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: AppTheme.successLight,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('✓ Verified', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.successGreen)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Bottom Action Buttons: Ping Approver & Resubmit (if rejected)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: AppTheme.border),
                          ),
                          icon: const Icon(Icons.notifications_active_outlined, size: 16, color: AppTheme.primaryOrange),
                          label: const Text('Ping Approver', style: TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
                          onPressed: () {
                            Navigator.pop(ctx);
                            final pendingStage = claim.approvalStages.firstWhere(
                              (s) => s.status == ApprovalStatus.pending,
                              orElse: () => claim.approvalStages.isNotEmpty
                                  ? claim.approvalStages.first
                                  : const ApprovalWorkflowStage(
                                      stageOrder: 1,
                                      roleTitle: 'Approver',
                                      approverName: 'Finance AP',
                                      approverDesignation: 'Auditor',
                                      status: ApprovalStatus.pending,
                                    ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Priority reminder sent to ${pendingStage.approverName} (${pendingStage.roleTitle})!'),
                                backgroundColor: AppTheme.navyDark,
                              ),
                            );
                          },
                        ),
                      ),
                      if (claim.hasRejectedLines) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryOrange,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Fix & Resubmit', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ResubmissionScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClaimDeskProvider>();
    final claims = provider.claims;

    // Filter by period first
    final periodClaims = claims.where(_isClaimInPeriod).toList();

    // Summary calculations for the chosen period
    final totalPeriodAmount = periodClaims.fold(0.0, (s, c) => s + c.grandTotal);

    // Filter by status tab & search query
    final filtered = periodClaims.where((c) {
      if (_selectedFilter == 'Drafts' && c.status != ClaimStatus.draft) return false;
      if (_selectedFilter == 'In Review' && c.status != ClaimStatus.submitted) return false;
      if (_selectedFilter == 'Needs Action' && !c.hasRejectedLines) return false;
      if (_selectedFilter == 'Approved' && c.status != ClaimStatus.approved) return false;
      if (_selectedFilter == 'Fully Closed' && c.status != ClaimStatus.fullyClosed) return false;

      final query = _searchController.text.trim().toLowerCase();
      if (query.isNotEmpty) {
        return c.docRefNumber.toLowerCase().contains(query) ||
            c.description.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Gold Squircle Bar Chart Icon (matching reference picture)
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(
                    Icons.bar_chart_rounded,
                    color: Color(0xFFD97706),
                    size: 21,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'My Claims & History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Period Filter Bar (Freestanding Stadium Pills: WTD, MTD, YTD, Custom)
          PeriodFilterBar(
            selectedPeriod: _selectedPeriod,
            customDateRange: _customDateRange,
            onPeriodChanged: (period, range) {
              setState(() {
                _selectedPeriod = period;
                _customDateRange = range;
              });
            },
          ),
          const SizedBox(height: 12),

          // Sleek Total Claimed Pill Bar (matching reference picture)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFFFFD),
                  Color(0xFFFEF8EC),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL CLAIMED (${periodClaims.length} CLAIMS)',
                  style: const TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.3,
                  ),
                ),
                Container(
                  height: 20,
                  width: 1.0,
                  color: const Color(0xFFCBD5E1),
                ),
                Text(
                  _formatCurrency(totalPeriodAmount),
                  style: const TextStyle(
                    fontSize: 19.0,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF854D0E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Search Field with Curvier Corners, Light Gold Gradient & Warm Gold Shadow
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFFFFD),
                  Color(0xFFFEF8EC),
                ],
              ),
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
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: 'Search by Ref # or description...',
                hintStyle: const TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 20,
                  color: Color(0xFF0F172A),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: Color(0xFF64748B)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Status Filter Pills (Matching KPI Shape, Color & Border)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((filter) {
                final isSelected = filter == _selectedFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedFilter = filter);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFFD97706), // Rich amber gold
                                  Color(0xFFB45309), // Deep amber gold
                                ],
                              )
                            : const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFFFFFFD),
                                  Color(0xFFFEF8EC),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFB45309)
                              : const Color(0xFFFEF08A).withValues(alpha: 0.45),
                          width: isSelected ? 1.0 : 0.8,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFB45309).withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: const Color(0xFFD97706).withValues(alpha: 0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                                BoxShadow(
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            filter,
                            style: TextStyle(
                              fontSize: 12.0,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                              color: isSelected ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Text('No claims found in this period matching "$_selectedFilter"', style: const TextStyle(color: AppTheme.textSecondary)),
              ),
            )
          else
            ...filtered.map((claim) {
              return UnifiedClaimCard(
                claim: claim,
                onLongPress: () => _showLegacyClaimBottomSheet(context, claim),
                onTap: () {
                  if (claim.status == ClaimStatus.draft) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(title: const Text('Edit Draft Claim')),
                          body: NewClaimScreen(initialDraft: claim),
                        ),
                      ),
                    );
                  } else {
                    _showClaimDetails(context, claim);
                  }
                },
              );
            }),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _formatCurrency(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final wholePart = parts[0];
    final decPart = parts[1];
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formatted = wholePart.replaceAllMapped(reg, (Match m) => '${m[1]},');
    return 'SAR $formatted.$decPart';
  }
}
