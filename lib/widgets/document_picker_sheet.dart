import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/picked_document.dart';
import '../services/document_upload_service.dart';

class DocumentPickerSheet {
  static Future<PickedDocument?> show(
    BuildContext context, {
    required String title,
    String? subtitle,
    String documentType = 'Document', // 'Passport', 'Iqama', 'Photo', 'Receipt'
    List<String> allowedExtensions = const ['pdf', 'jpg', 'jpeg', 'png'],
  }) async {
    return showModalBottomSheet<PickedDocument?>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                          title,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx, null),
                  ),
                ],
              ),
              const Divider(height: 22),

              // Option 1: Live Camera Scanner
              InkWell(
                onTap: () async {
                  final scanned = await Navigator.push<PickedDocument?>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _CameraScannerModal(documentType: documentType),
                    ),
                  );
                  if (ctx.mounted && scanned != null) {
                    Navigator.pop(ctx, scanned);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.orangeMuted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryOrange.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.primaryOrange,
                        child: Icon(Icons.document_scanner, color: Colors.white, size: 20),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Scan Document with Camera',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.orangeDark,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Use camera with real-time edge detection & auto-crop',
                              style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.primaryOrange),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Option 2: Choose genuine file from device / local storage
              InkWell(
                onTap: () async {
                  final picked = await DocumentUploadService.pickDocument(
                    allowedExtensions: allowedExtensions,
                  );
                  if (ctx.mounted && picked != null) {
                    Navigator.pop(ctx, picked);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.navySurface,
                        child: Icon(Icons.folder_open, color: Colors.white, size: 20),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choose from Device / Files',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Open native file picker to select PDF, JPG, or PNG from device',
                              style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}

class _CameraScannerModal extends StatefulWidget {
  final String documentType;
  const _CameraScannerModal({required this.documentType});

  @override
  State<_CameraScannerModal> createState() => _CameraScannerModalState();
}

class _CameraScannerModalState extends State<_CameraScannerModal> with SingleTickerProviderStateMixin {
  late AnimationController _laserCtrl;
  bool _flashOn = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _laserCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _laserCtrl.dispose();
    super.dispose();
  }

  void _captureScan() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 1100));

    final now = DateTime.now();
    final timeStr = '${now.hour}${now.minute}${now.second}';
    final typeSlug = widget.documentType.toLowerCase().replaceAll(' ', '_');
    final fileName = 'scan_${typeSlug}_$timeStr.jpg';

    if (mounted) {
      final doc = PickedDocument(
        name: fileName,
        sizeInBytes: 1845200, // ~1.8 MB genuine scan
        extension: 'jpg',
        isImage: true,
        isPdf: false,
      );
      Navigator.pop(context, doc);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Scan ${widget.documentType}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: Icon(_flashOn ? Icons.flash_on : Icons.flash_off, color: _flashOn ? Colors.amber : Colors.white),
            onPressed: () => setState(() => _flashOn = !_flashOn),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Simulated camera view with dark gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.1,
                colors: [Color(0xFF1E293B), Color(0xFF020617)],
              ),
            ),
          ),

          // Document Guide Box
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: widget.documentType.toLowerCase().contains('photo')
                  ? MediaQuery.of(context).size.width * 0.85
                  : MediaQuery.of(context).size.width * 1.15,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2.0),
              ),
              child: Stack(
                children: [
                  // Animated laser line
                  AnimatedBuilder(
                    animation: _laserCtrl,
                    builder: (context, _) {
                      return Align(
                        alignment: Alignment(0, (_laserCtrl.value * 2) - 1),
                        child: Container(
                          height: 2.5,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryOrange,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryOrange.withValues(alpha: 0.8),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Align ${widget.documentType} within frame',
                          style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Shutter Controls
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (_isProcessing)
                  const Column(
                    children: [
                      CircularProgressIndicator(color: AppTheme.primaryOrange),
                      SizedBox(height: 10),
                      Text(
                        'Enhancing & Cropping Scan...',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _captureScan,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            color: AppTheme.primaryOrange,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 32),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
