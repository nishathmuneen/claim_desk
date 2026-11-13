import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/claim_desk_provider.dart';
import '../models/ocr_scan_result.dart';

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

  // Editable Controllers for scanned result
  final _merchantController = TextEditingController();
  final _invoiceNumController = TextEditingController();
  final _baseAmountController = TextEditingController();
  final _vatAmountController = TextEditingController();
  final _totalAmountController = TextEditingController();
  DateTime _invoiceDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _laserController.dispose();
    _merchantController.dispose();
    _invoiceNumController.dispose();
    _baseAmountController.dispose();
    _vatAmountController.dispose();
    _totalAmountController.dispose();
    super.dispose();
  }

  Future<void> _startOcrScan() async {
    setState(() {
      _isScanning = true;
      _scanResult = null;
    });

    final provider = context.read<ClaimDeskProvider>();
    final result = await provider.simulateOcrScan();

    setState(() {
      _isScanning = false;
      _scanResult = result;
      _merchantController.text = result.merchantName;
      _invoiceNumController.text = result.invoiceNumber;
      _baseAmountController.text = result.baseAmount.toStringAsFixed(2);
      _vatAmountController.text = result.vatAmount.toStringAsFixed(2);
      _totalAmountController.text = result.totalAmount.toStringAsFixed(2);
      _invoiceDate = result.invoiceDate;
    });
  }

  void _applyToLine() {
    if (_scanResult == null) return;
    final base = double.tryParse(_baseAmountController.text) ?? _scanResult!.baseAmount;
    final total = double.tryParse(_totalAmountController.text) ?? _scanResult!.totalAmount;

    Navigator.pop(context, {
      'category': _scanResult!.category,
      'invoiceNumber': _invoiceNumController.text.trim(),
      'invoiceDate': _invoiceDate,
      'baseAmount': base,
      'totalAmount': total,
      'attachmentName': _scanResult!.sampleReceiptImage,
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
      body: SingleChildScrollView(
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
                  // Receipt Mock Graphic
                  Center(
                    child: Opacity(
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
                    onPressed: _isScanning ? null : _startOcrScan,
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
                    onPressed: _isScanning ? null : _startOcrScan,
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
            ],
          ],
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
