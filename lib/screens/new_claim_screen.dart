import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../models/expense_claim.dart';
import '../providers/claim_desk_provider.dart';
import 'ocr_scanner_screen.dart';

class NewClaimScreen extends StatefulWidget {
  final ExpenseClaim? initialDraft;

  const NewClaimScreen({super.key, this.initialDraft});

  @override
  State<NewClaimScreen> createState() => _NewClaimScreenState();
}

class _NewClaimScreenState extends State<NewClaimScreen> {
  final _uuid = const Uuid();
  late String _docRefNumber;
  String _selectedDocType = 'Petty Cash Reimbursement';
  DateTime _claimDate = DateTime.now();
  final _descController = TextEditingController();

  final List<ExpenseLineItem> _lines = [];

  final List<String> _docTypes = [
    'Petty Cash Reimbursement',
    'Site Operational Expense',
    'Local Travel & Fuel Claim',
    'Urgent Equipment Maintenance',
  ];

  final List<String> _categories = [
    'Fuel & Fleet',
    'Maintenance & Parts',
    'Office Supplies',
    'Safety Consumables',
    'Courier & Freight',
    'Site Hospitality & Meals',
    'Hardware & Tools',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialDraft != null) {
      final draft = widget.initialDraft!;
      _docRefNumber = draft.docRefNumber;
      _selectedDocType = draft.docType;
      _claimDate = draft.claimDate;
      _descController.text = draft.description;
      _lines.addAll(draft.lines);
    } else {
      _docRefNumber = 'EXP-2026-${(100 + DateTime.now().microsecond % 900)}';
      _addNewBlankLine();
    }
  }

  void _addNewBlankLine() {
    final provider = context.read<ClaimDeskProvider>();
    final vatRate = provider.configuredVatPercentage;
    setState(() {
      _lines.add(
        ExpenseLineItem(
          id: _uuid.v4(),
          date: DateTime.now(),
          category: _categories.first,
          invoiceNumber: '',
          baseAmount: 0.0,
          vatRatePercentage: vatRate,
          vatAmount: 0.0,
          totalAmount: 0.0,
          status: LineStatus.pending,
        ),
      );
    });
  }

  void _removeLine(int index) {
    if (_lines.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one line item is required')),
      );
      return;
    }
    setState(() {
      _lines.removeAt(index);
    });
  }

  void _updateLine(int index, ExpenseLineItem updated) {
    setState(() {
      _lines[index] = updated;
    });
  }

  double get _subtotal => _lines.fold(0.0, (s, i) => s + i.baseAmount);
  double get _totalVat => _lines.fold(0.0, (s, i) => s + i.vatAmount);
  double get _grandTotal => _lines.fold(0.0, (s, i) => s + i.totalAmount);

  Future<void> _scanReceiptForLine(int index) async {
    final scannedData = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const OcrScannerScreen(),
      ),
    );

    if (scannedData != null && scannedData is Map<String, dynamic>) {
      if (!mounted) return;
      final provider = context.read<ClaimDeskProvider>();
      final vatRate = provider.configuredVatPercentage;
      final base = (scannedData['baseAmount'] as num).toDouble();
      final vat = (base * vatRate) / 100.0;
      final total = base + vat;

      setState(() {
        _lines[index] = _lines[index].copyWith(
          category: scannedData['category'] ?? _lines[index].category,
          invoiceNumber: scannedData['invoiceNumber'] ?? _lines[index].invoiceNumber,
          date: scannedData['invoiceDate'] ?? _lines[index].date,
          baseAmount: base,
          vatRatePercentage: vatRate,
          vatAmount: vat,
          totalAmount: total,
          attachmentName: scannedData['attachmentName'] ?? 'scanned_receipt.jpg',
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Extracted into line #${index + 1} with $vatRate% VAT!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    }
  }

  void _saveDraft() {
    final provider = context.read<ClaimDeskProvider>();
    final claim = ExpenseClaim(
      id: widget.initialDraft?.id ?? _uuid.v4(),
      docRefNumber: _docRefNumber,
      docType: _selectedDocType,
      claimDate: _claimDate,
      description: _descController.text.trim().isEmpty
          ? 'Draft Expense Claim'
          : _descController.text.trim(),
      employeeId: provider.activeUser.employeeId,
      employeeName: provider.activeUser.name,
      costCenter: provider.activeUser.costCenter,
      cardNumber: provider.activeCard.cardNumber,
      vatRatePercentage: provider.configuredVatPercentage,
      status: ClaimStatus.draft,
      lines: _lines,
      createdAt: widget.initialDraft?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      auditTrail: [
        'Saved as draft by ${provider.activeUser.name} on ${_formatDate(DateTime.now())}'
      ],
    );

    provider.saveClaimAsDraft(claim);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Draft saved successfully ($_docRefNumber)'),
        backgroundColor: AppTheme.navyDark,
      ),
    );
  }

  void _submitClaim() {
    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a business description/purpose for this claim'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
      return;
    }

    for (int i = 0; i < _lines.length; i++) {
      final line = _lines[i];
      if (line.baseAmount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Line #${i + 1} must have an amount greater than 0'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
        return;
      }
      if (line.invoiceNumber.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Line #${i + 1} is missing Invoice/Receipt Number'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
        return;
      }
    }

    final provider = context.read<ClaimDeskProvider>();
    final claim = ExpenseClaim(
      id: widget.initialDraft?.id ?? _uuid.v4(),
      docRefNumber: _docRefNumber,
      docType: _selectedDocType,
      claimDate: _claimDate,
      description: _descController.text.trim(),
      employeeId: provider.activeUser.employeeId,
      employeeName: provider.activeUser.name,
      costCenter: provider.activeUser.costCenter,
      cardNumber: provider.activeCard.cardNumber,
      vatRatePercentage: provider.configuredVatPercentage,
      status: ClaimStatus.submitted,
      lines: _lines,
      createdAt: widget.initialDraft?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      auditTrail: [
        'Claim $_docRefNumber submitted into approval workflow on ${_formatDate(DateTime.now())} by ${provider.activeUser.name}'
      ],
    );

    provider.submitClaim(claim);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.successGreen),
            SizedBox(width: 10),
            Text('Claim Submitted!', style: TextStyle(color: AppTheme.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reference #: $_docRefNumber', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            Text('Document Type: $_selectedDocType', style: const TextStyle(color: AppTheme.textSecondary)),
            Text('Total Lines: ${_lines.length}', style: const TextStyle(color: AppTheme.textSecondary)),
            Text('Grand Total: SAR ${_grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryOrange)),
            const SizedBox(height: 12),
            const Text(
              'Your claim has entered the line-level approval workflow.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _docRefNumber = 'EXP-2026-${(100 + DateTime.now().microsecond % 900)}';
                _descController.clear();
                _lines.clear();
                _addNewBlankLine();
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _downloadAttachments() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.download_done, color: AppTheme.successGreen, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Attachments downloaded to your local "Downloads" folder (BRD 5.3)',
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.navyDark,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClaimDeskProvider>();
    final vatRate = provider.configuredVatPercentage;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Title & Download Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NEW EXPENSE CLAIM',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    'Ref: $_docRefNumber',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontFamily: 'monospace',
                      color: AppTheme.primaryOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Downloads'),
                onPressed: _downloadAttachments,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dynamic VAT Rate Banner (BRD Section 5.7)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.orangeMuted,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.primaryOrange.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calculate, color: AppTheme.primaryOrange, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                      children: [
                        const TextSpan(text: 'Application VAT Rate: '),
                        TextSpan(
                          text: '${vatRate.toStringAsFixed(1)}% ',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.orangeDark),
                        ),
                        const TextSpan(
                          text: '(Dynamically configured per BRD Section 5.7)',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Claim Header Information Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CLAIM DETAILS',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Document Type Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDocType,
                    dropdownColor: Colors.white,
                    decoration: const InputDecoration(
                      labelText: 'Document Type (Routes Workflow)',
                      prefixIcon: Icon(Icons.alt_route, size: 18, color: AppTheme.textSecondary),
                    ),
                    items: _docTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type, style: const TextStyle(fontSize: 13.5, color: AppTheme.textPrimary)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedDocType = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Description
                  TextField(
                    controller: _descController,
                    maxLines: 2,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Business Purpose / Remarks',
                      hintText: 'e.g., Emergency materials for pipeline repair site',
                      prefixIcon: Icon(Icons.notes, size: 18, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),

          // Section Header: Line Items
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LINE ITEMS (${_lines.length})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 17, color: AppTheme.primaryOrange),
                label: const Text(
                  'Add Line',
                  style: TextStyle(
                    color: AppTheme.primaryOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                onPressed: _addNewBlankLine,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Expandable Expense Lines
          ..._lines.asMap().entries.map((entry) {
            final index = entry.key;
            final line = entry.value;
            return _buildLineItemCard(index, line, vatRate);
          }),

          const SizedBox(height: 18),

          // Grand Totals Summary Card
          Container(
            padding: const EdgeInsets.all(18),
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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal (Base Excl. VAT)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    Text('SAR ${_subtotal.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13.5, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total VAT (${vatRate.toStringAsFixed(0)}%)', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    Text('SAR ${_totalVat.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.orangeDark, fontSize: 13.5, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Grand Total', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    Text(
                      'SAR ${_grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Bottom Actions Bar (Draft & Submit)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Save as Draft'),
                  onPressed: _saveDraft,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Submit Claim'),
                  onPressed: _submitClaim,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildLineItemCard(int index, ExpenseLineItem line, double configuredVat) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Line # + Scan OCR + Delete
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppTheme.primaryOrange.withValues(alpha: 0.15),
                      child: Text(
                        '#${index + 1}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryOrange),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      line.category,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: () => _scanReceiptForLine(index),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.orangeMuted,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.primaryOrange.withValues(alpha: 0.5)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.document_scanner, size: 14, color: AppTheme.primaryOrange),
                            SizedBox(width: 4),
                            Text(
                              'AI OCR',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryOrange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.dangerRed),
                      onPressed: () => _removeLine(index),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Category & Invoice # Inputs
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: line.category,
                    dropdownColor: Colors.white,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary)))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        _updateLine(index, line.copyWith(category: val));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    initialValue: line.invoiceNumber,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(labelText: 'Invoice #'),
                    onChanged: (val) {
                      _updateLine(index, line.copyWith(invoiceNumber: val));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Base Amount Input + Auto-Calculated VAT & Total
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: line.baseAmount > 0 ? line.baseAmount.toStringAsFixed(2) : '',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Base Amount (SAR)',
                      prefixText: 'SAR ',
                    ),
                    onChanged: (val) {
                      final base = double.tryParse(val) ?? 0.0;
                      final vat = (base * configuredVat) / 100.0;
                      final total = base + vat;
                      _updateLine(
                        index,
                        line.copyWith(
                          baseAmount: base,
                          vatRatePercentage: configuredVat,
                          vatAmount: vat,
                          totalAmount: total,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VAT (${configuredVat.toStringAsFixed(0)}%): SAR ${line.vatAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Total: SAR ${line.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryOrange),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Attachment Status
            Row(
              children: [
                const Icon(Icons.attach_file, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    line.attachmentName ?? 'No invoice attached yet',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: line.attachmentName != null ? AppTheme.successGreen : AppTheme.textMuted,
                      fontStyle: line.attachmentName != null ? FontStyle.normal : FontStyle.italic,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _updateLine(
                      index,
                      line.copyWith(attachmentName: 'invoice_${line.category.replaceAll(' ', '_')}.pdf'),
                    );
                  },
                  child: Text(
                    line.attachmentName == null ? 'Attach Invoice' : 'Change',
                    style: const TextStyle(fontSize: 12, color: AppTheme.primaryOrange),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
