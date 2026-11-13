import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/claim_desk_provider.dart';
import '../models/expense_claim.dart';
import 'new_claim_screen.dart';

class ClaimsHistoryScreen extends StatefulWidget {
  const ClaimsHistoryScreen({super.key});

  @override
  State<ClaimsHistoryScreen> createState() => _ClaimsHistoryScreenState();
}

class _ClaimsHistoryScreenState extends State<ClaimsHistoryScreen> {
  String _selectedFilter = 'All';
  final _searchController = TextEditingController();

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

  void _showClaimDetails(BuildContext context, ExpenseClaim claim) {
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
                  const Divider(height: 24),

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

    final filtered = claims.where((c) {
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
          const Text(
            'MY CLAIMS & HISTORY',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          // Search Field
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Search by Ref # or description...',
              prefixIcon: Icon(Icons.search, size: 20),
            ),
          ),
          const SizedBox(height: 14),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((filter) {
                final isSelected = filter == _selectedFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() => _selectedFilter = filter);
                    },
                    selectedColor: AppTheme.primaryOrange.withValues(alpha: 0.16),
                    checkmarkColor: AppTheme.primaryOrange,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppTheme.primaryOrange : AppTheme.textSecondary,
                    ),
                    backgroundColor: AppTheme.surface,
                    side: BorderSide(
                      color: isSelected ? AppTheme.primaryOrange : AppTheme.border,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),

          if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Text('No claims found matching "$_selectedFilter"', style: const TextStyle(color: AppTheme.textSecondary)),
              ),
            )
          else
            ...filtered.map((claim) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
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
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              claim.docRefNumber,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'SAR ${claim.grandTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryOrange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          claim.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${claim.lines.length} items • ${_formatDate(claim.claimDate)}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                            _statusChip(claim),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _statusChip(ExpenseClaim claim) {
    Color col;
    Color bg;
    String label;

    switch (claim.status) {
      case ClaimStatus.draft:
        col = AppTheme.textSecondary;
        bg = const Color(0xFFF1F5F9);
        label = 'Draft (Tap to Edit)';
        break;
      case ClaimStatus.submitted:
        col = AppTheme.infoBlue;
        bg = AppTheme.infoLight;
        label = 'In Approval';
        break;
      case ClaimStatus.partiallyRejected:
        col = AppTheme.dangerRed;
        bg = AppTheme.dangerLight;
        label = 'Action Needed';
        break;
      case ClaimStatus.approved:
        col = AppTheme.successGreen;
        bg = AppTheme.successLight;
        label = 'Approved';
        break;
      case ClaimStatus.fullyClosed:
        col = AppTheme.closedPurple;
        bg = AppTheme.closedLight;
        label = 'Fully Closed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: col),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
