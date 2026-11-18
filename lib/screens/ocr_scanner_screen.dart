import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/claim_desk_provider.dart';
import '../models/ocr_scan_result.dart';
import '../models/picked_document.dart';
import '../services/document_upload_service.dart';
import '../services/receipt_ocr_service.dart';
import '../widgets/document_picker_sheet.dart';
import '../widgets/kinetic_background.dart';

class OcrScannerScreen extends StatefulWidget {
  const OcrScannerScreen({super.key});

  @override
  State<OcrScannerScreen> createState() => _OcrScannerScreenState();
}

class _OcrScannerScreenState extends State<OcrScannerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _laserController;
  bool _isScanning = false;
  OcrScanResult? _scanResult;
  PickedDocument? _selectedDocument;
  bool _isRecalculating = false;

  // Editable Controllers for scanned result
  final _merchantController = TextEditingController();
  final _invoiceNumController = TextEditingController();
  final _baseAmountController = TextEditingController();
  final _vatAmountController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _notesController = TextEditingController(text: 'Transportation of company materials / goods.');
  String _selectedProject = 'Aramco Ras Tanura Refinery (CC-402)';
  DateTime _invoiceDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _baseAmountController.addListener(_onBaseAmountChanged);
    _totalAmountController.addListener(_onTotalAmountChanged);
  }

  void _onBaseAmountChanged() {
    if (_isRecalculating) return;
    final base = double.tryParse(_baseAmountController.text);
    if (base != null && mounted) {
      _isRecalculating = true;
      final vatRate = context.read<ClaimDeskProvider>().configuredVatPercentage;
      final vat = (base * vatRate) / 100.0;
      final total = base + vat;
      _vatAmountController.text = vat.toStringAsFixed(2);
      _totalAmountController.text = total.toStringAsFixed(2);
      _isRecalculating = false;
    }
  }

  void _onTotalAmountChanged() {
    if (_isRecalculating) return;
    final total = double.tryParse(_totalAmountController.text);
    if (total != null && mounted) {
      _isRecalculating = true;
      final vatRate = context.read<ClaimDeskProvider>().configuredVatPercentage;
      final base = total / (1.0 + (vatRate / 100.0));
      final vat = total - base;
      _baseAmountController.text = base.toStringAsFixed(2);
      _vatAmountController.text = vat.toStringAsFixed(2);
      _isRecalculating = false;
    }
  }

  @override
  void dispose() {
    _laserController.dispose();
    _merchantController.dispose();
    _invoiceNumController.dispose();
    _baseAmountController.dispose();
    _vatAmountController.dispose();
    _totalAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Uint8List? _getPreviewBytes(PickedDocument? doc) {
    if (doc == null || doc.base64Data == null || !doc.isImage) return null;
    try {
      final raw = doc.base64Data!;
      final b64 = raw.contains(',') ? raw.split(',').last : raw;
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  // Pick genuine receipt file from device storage / gallery
  Future<void> _pickFromGallery() async {
    final picked = await DocumentUploadService.pickDocument(
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (picked == null) return; // User closed picker without selecting; don't auto-add!

    setState(() {
      _selectedDocument = picked;
      _isScanning = true;
      _scanResult = null;
    });

    // Intelligent AI OCR reading the selected receipt file
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    final vatRate = context.read<ClaimDeskProvider>().configuredVatPercentage;
    final result = ReceiptOcrService.analyzeReceipt(picked, vatRate);

    setState(() {
      _isScanning = false;
      _scanResult = result;
      _isRecalculating = true;
      _merchantController.text = result.merchantName;
      _invoiceNumController.text = result.invoiceNumber;
      _baseAmountController.text = result.baseAmount.toStringAsFixed(2);
      _vatAmountController.text = result.vatAmount.toStringAsFixed(2);
      _totalAmountController.text = result.totalAmount.toStringAsFixed(2);
      _invoiceDate = result.invoiceDate;
      if (result.justification != null) {
        _notesController.text = result.justification!;
      }
      if (result.projectCostCenter != null) {
        _selectedProject = result.projectCostCenter!;
      }
      _isRecalculating = false;
    });
  }

  // Capture real receipt scan with camera viewfinder
  Future<void> _captureWithCamera() async {
    final scanned = await DocumentPickerSheet.show(
      context,
      title: 'Scan Expense Receipt / Invoice',
      subtitle: 'Align physical bill inside the camera frame',
      documentType: 'Receipt',
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (scanned == null) return; // Cancelled

    setState(() {
      _selectedDocument = scanned;
      _isScanning = true;
      _scanResult = null;
    });

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    final vatRate = context.read<ClaimDeskProvider>().configuredVatPercentage;
    final result = ReceiptOcrService.analyzeReceipt(scanned, vatRate);

    setState(() {
      _isScanning = false;
      _scanResult = result;
      _isRecalculating = true;
      _merchantController.text = result.merchantName;
      _invoiceNumController.text = result.invoiceNumber;
      _baseAmountController.text = result.baseAmount.toStringAsFixed(2);
      _vatAmountController.text = result.vatAmount.toStringAsFixed(2);
      _totalAmountController.text = result.totalAmount.toStringAsFixed(2);
      _invoiceDate = result.invoiceDate;
      if (result.justification != null) {
        _notesController.text = result.justification!;
      }
      if (result.projectCostCenter != null) {
        _selectedProject = result.projectCostCenter!;
      }
      _isRecalculating = false;
    });
  }

  void _applyToLine() {
    if (_scanResult == null) return;
    final base = double.tryParse(_baseAmountController.text) ?? _scanResult!.baseAmount;
    final vat = double.tryParse(_vatAmountController.text) ?? _scanResult!.vatAmount;
    final total = double.tryParse(_totalAmountController.text) ?? _scanResult!.totalAmount;

    Navigator.pop(context, {
      'category': _scanResult!.category,
      'invoiceNumber': _invoiceNumController.text.trim(),
      'invoiceDate': _invoiceDate,
      'baseAmount': base,
      'vatAmount': vat,
      'totalAmount': total,
      'merchantName': _merchantController.text.trim(),
      'attachmentName': _selectedDocument?.name ?? _scanResult!.sampleReceiptImage,
      'justification': _notesController.text.trim(),
      'projectCostCenter': _selectedProject,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('AI / OCR Receipt Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: AppTheme.primaryOrange),
            onPressed: () {},
          ),
        ],
      ),
      body: KineticBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: AppTheme.primaryOrange),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Position invoice/receipt inside frame. OCR will detect Merchant, Date, Tax Invoice #, and VAT breakdown.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Camera / Scanning Viewfinder Frame
            Container(
              height: 260,
              decoration: BoxDecoration(
                color: AppTheme.navyDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryOrange, width: 2.0),
              ),
              child: Stack(
                children: [
                  // Receipt Graphic or Real Loaded Document
                  Center(
                    child: _selectedDocument != null
                        ? Builder(
                            builder: (context) {
                              final previewBytes = _getPreviewBytes(_selectedDocument);
                              if (previewBytes != null) {
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        color: Colors.white,
                                        padding: const EdgeInsets.all(4),
                                        child: Image.memory(
                                          previewBytes,
                                          height: 220,
                                          width: 320,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.8),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: AppTheme.primaryOrange.withValues(alpha: 0.6)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.check_circle, size: 12, color: AppTheme.successGreen),
                                            const SizedBox(width: 5),
                                            Text(
                                              _selectedDocument!.name,
                                              style: const TextStyle(fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }

                              return Container(
                                width: 220,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _selectedDocument!.isPdf ? Icons.picture_as_pdf : Icons.image,
                                      size: 40,
                                      color: _selectedDocument!.isPdf ? AppTheme.dangerRed : AppTheme.primaryOrange,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _selectedDocument!.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.textPrimary),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedDocument!.formattedSize,
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppTheme.successLight,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check_circle, size: 12, color: AppTheme.successGreen),
                                          SizedBox(width: 4),
                                          Text('Receipt Loaded', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.successGreen)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        : Opacity(
                            opacity: 0.75,
                            child: Container(
                              width: 190,
                              height: 220,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black54, blurRadius: 10)
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(height: 10, width: 70, color: Colors.black45),
                                  const SizedBox(height: 6),
                                  Container(height: 6, width: 140, color: Colors.black26),
                                  const SizedBox(height: 12),
                                  const Divider(color: Colors.black38, height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(height: 7, width: 50, color: Colors.black38),
                                      Container(height: 7, width: 30, color: Colors.black38),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(height: 7, width: 60, color: Colors.black38),
                                      Container(height: 7, width: 30, color: Colors.black38),
                                    ],
                                  ),
                                  const Spacer(),
                                  const Divider(color: Colors.black38, height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(height: 9, width: 45, color: Colors.black87),
                                      Container(height: 9, width: 45, color: AppTheme.primaryOrange),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),

                  // Laser scanning line animation
                  if (_isScanning)
                    AnimatedBuilder(
                      animation: _laserController,
                      builder: (context, child) {
                        return Positioned(
                          top: _laserController.value * 230 + 10,
                          left: 20,
                          right: 20,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryOrange,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryOrange.withValues(alpha: 0.8),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  // Viewfinder corners
                  _cornerMark(Alignment.topLeft),
                  _cornerMark(Alignment.topRight),
                  _cornerMark(Alignment.bottomLeft),
                  _cornerMark(Alignment.bottomRight),

                  if (_isScanning)
                    Container(
                      color: Colors.black54,
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.navySurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.primaryOrange.withValues(alpha: 0.5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryOrange),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'AI OCR Reading ZATCA Tax Fields...',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Scan Trigger Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: Text(_isScanning ? 'Scanning...' : 'Capture & Scan'),
                    onPressed: _isScanning ? null : _captureWithCamera,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppTheme.border, width: 1.2),
                    ),
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('From Gallery'),
                    onPressed: _isScanning ? null : _pickFromGallery,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Extracted OCR Review Card
            if (_scanResult != null) ...[
              Card(
                color: AppTheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'EXTRACTED INVOICE DATA',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textMuted,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (_scanResult!.isHighConfidence ? AppTheme.successGreen : AppTheme.primaryOrange).withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _scanResult!.isHighConfidence ? Icons.verified : Icons.warning_amber,
                                  size: 13,
                                  color: _scanResult!.isHighConfidence ? AppTheme.successGreen : AppTheme.orangeDark,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${(_scanResult!.confidenceScore * 100).toInt()}% Match',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _scanResult!.isHighConfidence ? AppTheme.successGreen : AppTheme.orangeDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      TextField(
                        controller: _merchantController,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(labelText: 'Merchant / Vendor Name'),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _invoiceNumController,
                              style: const TextStyle(color: AppTheme.textPrimary),
                              decoration: const InputDecoration(labelText: 'Invoice / Tax Receipt #'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _baseAmountController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: AppTheme.textPrimary),
                              decoration: const InputDecoration(labelText: 'Base Amount (SAR)'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _vatAmountController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: AppTheme.textPrimary),
                              decoration: const InputDecoration(labelText: 'Extracted VAT (SAR)'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _totalAmountController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: AppTheme.textPrimary),
                              decoration: const InputDecoration(labelText: 'Total Amount (SAR)'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Two-Tone Cost vs. VAT Ratio Bar (from Stitch inspiration)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'AUTO COST / VAT RATIO (15% ZATCA)',
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('✓ Cryptographic QR Valid', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF065F46))),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 87,
                                    child: Container(height: 7, color: const Color(0xFF1E2B45)),
                                  ),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    flex: 13,
                                    child: Container(height: 7, color: AppTheme.primaryOrange),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Subtotal (Net): SAR ${_baseAmountController.text.isNotEmpty ? _baseAmountController.text : "217.39"}',
                                  style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary),
                                ),
                                Text(
                                  'Input VAT (15%): SAR ${_vatAmountController.text.isNotEmpty ? _vatAmountController.text : "32.61"}',
                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.primaryOrange),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Project / WBS Cost Center Allocation
                      DropdownButtonFormField<String>(
                        value: _selectedProject,
                        decoration: const InputDecoration(labelText: 'Project / WBS Cost Center'),
                        items: {
                          'Aramco Ras Tanura Refinery (CC-402)',
                          'Jubail Commercial Port Upgrade (CC-108)',
                          'SABIC Kemya Petrochemical Turnaround (CC-204)',
                          'SABIC Jubail Complex (CC-101)',
                          'Jafurah Gas Plant Site (CC-305)',
                          'Headquarters Corporate Admin (CC-001)',
                          _selectedProject,
                        }.map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p, style: const TextStyle(fontSize: 12.5)),
                        )).toList(),
                        onChanged: (v) => setState(() => _selectedProject = v!),
                      ),
                      const SizedBox(height: 10),

                      // Audit Justification Note
                      TextField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Audit Rationale / Justification',
                          hintText: 'e.g. Approved diesel refill for generator unit',
                        ),
                        style: const TextStyle(fontSize: 12.5),
                      ),
                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successGreen,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Apply to Expense Line'),
                          onPressed: _applyToLine,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ] else ...[
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.document_scanner_outlined, size: 36, color: AppTheme.primaryOrange),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Ready to Scan Receipt',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap "Capture & Scan" or "From Gallery" above to upload your invoice.\nAI OCR will automatically detect Merchant, Tax Invoice #, and 15% ZATCA VAT breakdown.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    ),
  );
}

  Widget _cornerMark(Alignment align) {
    return Align(
      alignment: align,
      child: Container(
        width: 22,
        height: 22,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border(
            top: align.y == -1.0 ? const BorderSide(color: AppTheme.primaryOrange, width: 3) : BorderSide.none,
            bottom: align.y == 1.0 ? const BorderSide(color: AppTheme.primaryOrange, width: 3) : BorderSide.none,
            left: align.x == -1.0 ? const BorderSide(color: AppTheme.primaryOrange, width: 3) : BorderSide.none,
            right: align.x == 1.0 ? const BorderSide(color: AppTheme.primaryOrange, width: 3) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
