import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../models/expense_claim.dart';
import '../providers/claim_desk_provider.dart';
import '../widgets/document_picker_sheet.dart';
import 'ocr_scanner_screen.dart';

class NewClaimScreen extends StatefulWidget {
  final ExpenseClaim? initialDraft;
  final Map<String, dynamic>? initialScannedReceipt;

  const NewClaimScreen({super.key, this.initialDraft, this.initialScannedReceipt});

  @override
  State<NewClaimScreen> createState() => _NewClaimScreenState();
}

class _NewClaimScreenState extends State<NewClaimScreen> {
  final _uuid = const Uuid();
  late String _docRefNumber;
  String _selectedDocType = 'Site Operations & Consumables';
  DateTime _claimDate = DateTime.now();
  final _descController = TextEditingController();

  final List<ExpenseLineItem> _lines = [];
  bool? _hasChosenEntryMode;
  Map<String, TextEditingController>? _invoiceControllers;
  Map<String, TextEditingController>? _amountControllers;

  TextEditingController _invoiceControllerFor(ExpenseLineItem line) {
    _invoiceControllers ??= {};
    return _invoiceControllers!.putIfAbsent(
      line.id,
      () => TextEditingController(text: line.invoiceNumber),
    );
  }

  TextEditingController _amountControllerFor(ExpenseLineItem line) {
    _amountControllers ??= {};
    return _amountControllers!.putIfAbsent(
      line.id,
      () => TextEditingController(
        text: line.baseAmount > 0 ? line.baseAmount.toStringAsFixed(2) : '',
      ),
    );
  }

  @override
  void dispose() {
    _descController.dispose();
    if (_invoiceControllers != null) {
      for (final c in _invoiceControllers!.values) {
        c.dispose();
      }
    }
    if (_amountControllers != null) {
      for (final c in _amountControllers!.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  final List<String> _docTypes = [
    'Site Operations & Consumables',
    'Local Travel & Fuel Claim',
    'Equipment Maintenance & Repairs',
    'General Office & Administrative',
    'Client & Site Hospitality',
  ];

  static String _mapLegacyDocType(String legacy) {
    if (legacy == 'Petty Cash Reimbursement' || legacy == 'Site Operational Expense') {
      return 'Site Operations & Consumables';
    }
    if (legacy == 'Urgent Equipment Maintenance') {
      return 'Equipment Maintenance & Repairs';
    }
    if (legacy == 'Travel & Lodging') {
      return 'Client & Site Hospitality';
    }
    return legacy;
  }

  final List<String> _categories = [
    'Fuel & Fleet',
    'Site Transport & Logistics',
    'Courier & Freight',
    'Maintenance & Parts',
    'Equipment Maintenance & Spare Parts',
    'Hardware & Tools',
    'Office Supplies',
    'Office Supplies & Consumables',
    'Safety Consumables',
    'Site Hospitality & Meals',
    'Meals & Entertainment',
    'Travel & Per Diem',
    'Operating Supplies & Sundries',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialDraft != null) {
      _hasChosenEntryMode = true;
      final draft = widget.initialDraft!;
      _docRefNumber = draft.docRefNumber;
      _selectedDocType = _docTypes.contains(draft.docType)
          ? draft.docType
          : _mapLegacyDocType(draft.docType);
      _claimDate = draft.claimDate;
      _descController.text = draft.description;
      _lines.addAll(draft.lines);
    } else if (widget.initialScannedReceipt != null) {
      _hasChosenEntryMode = true;
      _docRefNumber = 'EXP-2026-${(100 + DateTime.now().microsecond % 900)}';
      _applyScannedReceiptToNewClaim(widget.initialScannedReceipt!);
    } else {
      _hasChosenEntryMode = false;
      _docRefNumber = 'EXP-2026-${(100 + DateTime.now().microsecond % 900)}';
      _addNewBlankLine();
    }
  }

  void _applyScannedReceiptToNewClaim(Map<String, dynamic> r) {
    if (r['justification'] != null && r['justification'].toString().isNotEmpty) {
      _descController.text = r['justification'].toString();
    }
    final cat = r['category']?.toString() ?? _categories.first;
    final inv = r['invoiceNumber']?.toString() ?? '';
    final base = (r['baseAmount'] as num?)?.toDouble() ?? 0.0;
    final vat = (r['vatAmount'] as num?)?.toDouble() ?? 0.0;
    final tot = (r['totalAmount'] as num?)?.toDouble() ?? (base + vat);
    final att = r['attachmentName']?.toString();
    final dt = (r['invoiceDate'] as DateTime?) ?? DateTime.now();

    final line = ExpenseLineItem(
      id: _uuid.v4(),
      date: dt,
      category: cat,
      invoiceNumber: inv,
      baseAmount: base,
      vatRatePercentage: 15.0,
      vatAmount: vat,
      totalAmount: tot,
      attachmentName: att,
      status: LineStatus.pending,
    );
    _lines.clear();
    _lines.add(line);
    _invoiceControllerFor(line).text = inv;
    _amountControllerFor(line).text = base > 0 ? base.toStringAsFixed(2) : '';
  }

  Future<void> _startWithOcrScan() async {
    final scannedData = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const OcrScannerScreen(),
      ),
    );
    if (scannedData != null && scannedData is Map<String, dynamic> && mounted) {
      setState(() {
        _applyScannedReceiptToNewClaim(scannedData);
        _hasChosenEntryMode = true;
      });
    }
  }

  void _addNewBlankLine() {
    final provider = context.read<ClaimDeskProvider>();
    final vatRate = provider.configuredVatPercentage;
    final newLine = ExpenseLineItem(
      id: _uuid.v4(),
      date: DateTime.now(),
      category: _categories.first,
      invoiceNumber: '',
      baseAmount: 0.0,
      vatRatePercentage: vatRate,
      vatAmount: 0.0,
      totalAmount: 0.0,
      status: LineStatus.pending,
    );
    if (mounted) {
      setState(() {
        _lines.add(newLine);
      });
    }
  }

  void _removeLine(int index) {
    if (_lines.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one line item is required')),
      );
      return;
    }
    final removedId = _lines[index].id;
    setState(() {
      _lines.removeAt(index);
    });
    _invoiceControllers?.remove(removedId)?.dispose();
    _amountControllers?.remove(removedId)?.dispose();
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
      final vat = (scannedData['vatAmount'] as num?)?.toDouble() ??
          double.parse(((base * vatRate) / 100.0).toStringAsFixed(2));
      final total = (scannedData['totalAmount'] as num?)?.toDouble() ?? (base + vat);

      if (_descController.text.trim().isEmpty &&
          scannedData['justification'] != null &&
          scannedData['justification'].toString().isNotEmpty) {
        _descController.text = scannedData['justification'].toString();
      }

      final updatedLine = _lines[index].copyWith(
        category: scannedData['category'] ?? _lines[index].category,
        invoiceNumber: scannedData['invoiceNumber'] ?? _lines[index].invoiceNumber,
        date: scannedData['invoiceDate'] ?? _lines[index].date,
        baseAmount: base,
        vatRatePercentage: vatRate,
        vatAmount: vat,
        totalAmount: total,
        attachmentName: scannedData['attachmentName'] ?? 'scanned_receipt.jpg',
      );
      _invoiceControllerFor(updatedLine).text = updatedLine.invoiceNumber;
      _amountControllerFor(updatedLine).text =
          updatedLine.baseAmount > 0 ? updatedLine.baseAmount.toStringAsFixed(2) : '';
      setState(() {
        _lines[index] = updatedLine;
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

    final provider = context.read<ClaimDeskProvider>();
    final seenInvoices = <String>{};

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
      final inv = line.invoiceNumber.trim();
      if (inv.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Line #${i + 1} is missing Invoice/Receipt Number'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
        return;
      }
      if (!seenInvoices.add(inv.toLowerCase()) ||
          provider.isDuplicateInvoice(inv, excludeClaimId: widget.initialDraft?.id)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Duplicate Invoice # detected ($inv). Each invoice can only be claimed once.'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
        return;
      }
    }

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
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                for (final c in (_invoiceControllers?.values ?? const <TextEditingController>[])) {
                  c.dispose();
                }
                for (final c in (_amountControllers?.values ?? const <TextEditingController>[])) {
                  c.dispose();
                }
                _invoiceControllers?.clear();
                _amountControllers?.clear();
                setState(() {
                  _docRefNumber = 'EXP-2026-${(100 + DateTime.now().microsecond % 900)}';
                  _descController.clear();
                  _lines.clear();
                  _hasChosenEntryMode = false;
                });
                _addNewBlankLine();
              }
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

  Widget _buildEntrySelectorView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'NEW EXPENSE CLAIM',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppTheme.textMuted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'How would you like to start?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 18),

          // Primary Recommended Option: AI OCR Scan / Upload Document
          Container(
            padding: const EdgeInsets.all(20),
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
                color: const Color(0xFFFEF08A).withValues(alpha: 0.65),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD97706).withValues(alpha: 0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
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
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.document_scanner_rounded,
                        color: Color(0xFF2563EB),
                        size: 24,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Recommended • Auto-Fill',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'AI OCR Scan or Upload Document',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Take a photo or upload a PDF/image invoice. Merchant, Invoice #, Date, Category, and 15% ZATCA VAT will be extracted and pre-filled automatically.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF475569),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.camera_alt_outlined, size: 19),
                    label: const Text(
                      'Scan or Upload Document',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                    ),
                    onPressed: _startWithOcrScan,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Divider
          const Row(
            children: [
              Expanded(child: Divider(color: Color(0xFFE2E8F0))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'OR',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Color(0xFFE2E8F0))),
            ],
          ),

          const SizedBox(height: 20),

          // Secondary Option: Manual Entry
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.edit_note_rounded, size: 22, color: Color(0xFF334155)),
              label: const Text(
                'Enter Details Manually',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              onPressed: () {
                setState(() {
                  _hasChosenEntryMode = true;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasChosenEntryMode == false) {
      return _buildEntrySelectorView(context);
    }

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
                    value: _selectedDocType,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    decoration: const InputDecoration(
                      labelText: 'Claim Purpose / Classification',
                      prefixIcon: Icon(Icons.alt_route, size: 18, color: AppTheme.textSecondary),
                    ),
                    items: {..._docTypes, _selectedDocType}.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(
                          type,
                          style: const TextStyle(fontSize: 13.5, color: AppTheme.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
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
      key: ValueKey('line_${line.id}'),
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
                    value: line.category,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: {..._categories, line.category}.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(
                          c,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
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
                    controller: _invoiceControllerFor(line),
                    textInputAction: TextInputAction.next,
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
                    controller: _amountControllerFor(line),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Base Amount (SAR)',
                      prefixText: 'SAR ',
                    ),
                    onChanged: (val) {
                      final cleaned = val.replaceAll(',', '.').trim();
                      final base = double.tryParse(cleaned) ?? 0.0;
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
            const SizedBox(height: 10),

            // Payment Source Selector (Card Swipe vs Cash Advance)
            Row(
              children: [
                const Text(
                  'Payment Source:',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Card Swipe', style: TextStyle(fontSize: 11)),
                  selected: line.paymentSource == PaymentSource.cardSwipe,
                  selectedColor: const Color(0xFFFEF3C7),
                  onSelected: (_) {
                    _updateLine(index, line.copyWith(paymentSource: PaymentSource.cardSwipe));
                  },
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('Cash Advance', style: TextStyle(fontSize: 11)),
                  selected: line.paymentSource == PaymentSource.cashAdvance,
                  selectedColor: const Color(0xFFDBEAFE),
                  onSelected: (_) {
                    _updateLine(index, line.copyWith(paymentSource: PaymentSource.cashAdvance));
                  },
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 10),

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
                TextButton.icon(
                  icon: const Icon(Icons.upload_file, size: 14),
                  onPressed: () async {
                    final doc = await DocumentPickerSheet.show(
                      context,
                      title: 'Attach Expense Receipt / Tax Invoice',
                      subtitle: 'Provide official ZATCA VAT tax invoice for audit compliance',
                      documentType: 'Receipt',
                      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
                    );
                    if (doc != null) {
                      _updateLine(
                        index,
                        line.copyWith(attachmentName: doc.name),
                      );
                    }
                  },
                  label: Text(
                    line.attachmentName == null ? 'Scan / Attach Invoice' : 'Change',
                    style: const TextStyle(fontSize: 12, color: AppTheme.primaryOrange, fontWeight: FontWeight.bold),
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
