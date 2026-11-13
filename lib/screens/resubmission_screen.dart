import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/claim_desk_provider.dart';
import '../models/expense_claim.dart';

class ResubmissionScreen extends StatefulWidget {
  const ResubmissionScreen({super.key});

  @override
  State<ResubmissionScreen> createState() => _ResubmissionScreenState();
}

class _ResubmissionScreenState extends State<ResubmissionScreen> {
  void _openEditDialog(BuildContext context, String claimId, ExpenseLineItem line) {
    final invoiceCtrl = TextEditingController(text: line.invoiceNumber);
    final amountCtrl = TextEditingController(text: line.baseAmount.toStringAsFixed(2));
    String attachment = line.attachmentName ?? 'revised_vat_tax_invoice.pdf';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Revise & Resubmit Line',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 16),

              // Approver Comment Callout Box (BRD Section 5.4 Mandatory Comment)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.dangerLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.dangerRed.withValues(alpha: 0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.feedback_outlined, size: 16, color: AppTheme.dangerRed),
                        SizedBox(width: 6),
                        Text(
                          'Approver Mandatory Rejection Reason:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.dangerRed),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      line.rejectionComment ?? 'Please provide a valid VAT invoice with clear tax breakdown.',
                      style: const TextStyle(fontSize: 12.5, color: AppTheme.textPrimary, height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Editable Inputs
              TextField(
                controller: invoiceCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Corrected Invoice #'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Corrected Base Amount (SAR)'),
              ),
              const SizedBox(height: 12),

              // Replacement attachment
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_upload_outlined, color: AppTheme.primaryOrange, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Replacement Tax Invoice', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          Text(attachment, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          attachment = 'official_zatca_tax_invoice_signed.pdf';
                        });
                      },
                      child: const Text('Change', style: TextStyle(color: AppTheme.primaryOrange, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // BRD 5.4 Notification Box
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.orangeMuted,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primaryOrange.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_mode, color: AppTheme.primaryOrange, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Per BRD Section 5.4, resubmitting this line will automatically generate a NEW Document Reference Number.',
                        style: TextStyle(fontSize: 11.5, color: AppTheme.orangeDark, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Resubmit Line (Generates New Ref #)'),
                  onPressed: () {
                    final base = double.tryParse(amountCtrl.text) ?? line.baseAmount;
                    final vat = (base * line.vatRatePercentage) / 100.0;
                    final total = base + vat;

                    final updatedLine = line.copyWith(
                      invoiceNumber: invoiceCtrl.text.trim(),
                      baseAmount: base,
                      vatAmount: vat,
                      totalAmount: total,
                      attachmentName: attachment,
                    );

                    context.read<ClaimDeskProvider>().resubmitRejectedLine(
                          originalClaimId: claimId,
                          updatedLine: updatedLine,
                        );

                    Navigator.pop(ctx);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: AppTheme.successGreen),
                            SizedBox(width: 8),
                            Expanded(child: Text('Resubmitted with new Document Ref # and audit history link!')),
                          ],
                        ),
                        backgroundColor: AppTheme.navyDark,
                        duration: Duration(seconds: 3),
                      ),
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClaimDeskProvider>();
    final rejectedClaims = provider.rejectedClaims;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.dangerLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assignment_late, color: AppTheme.dangerRed, size: 20),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ACTION REQUIRED',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  Text(
                    'Line-level rejections returned for revision (BRD 5.4)',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          if (rejectedClaims.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Column(
                  children: [
                    Icon(Icons.task_alt, size: 48, color: AppTheme.successGreen.withValues(alpha: 0.6)),
                    const SizedBox(height: 12),
                    const Text(
                      'No Rejected Lines',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'All your submitted expense lines are either approved or in review.',
                      style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            ...rejectedClaims.map((claim) {
              final rejectedLines = claim.rejectedLines;
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
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
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.dangerLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.dangerRed.withValues(alpha: 0.35)),
                            ),
                            child: const Text(
                              'Returned to Initiator',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.dangerRed),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(claim.description, style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary)),
                      const Divider(height: 20),

                      // List of Rejected Lines in this claim
                      ...rejectedLines.map((line) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.dangerRed.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    line.category,
                                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                  ),
                                  Text(
                                    'SAR ${line.totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppTheme.primaryOrange),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Invoice #: ${line.invoiceNumber}', style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary)),
                              const SizedBox(height: 8),

                              // Rejection Comment Box
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.dangerLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Approver Comment: ${line.rejectionComment}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.dangerRed, height: 1.3),
                                ),
                              ),
                              const SizedBox(height: 10),

                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryOrange,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  ),
                                  icon: const Icon(Icons.edit, size: 15),
                                  label: const Text('Edit & Resubmit', style: TextStyle(fontSize: 12.5)),
                                  onPressed: () => _openEditDialog(context, claim.id, line),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
