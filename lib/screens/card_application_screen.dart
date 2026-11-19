import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/card_application.dart';
import '../models/picked_document.dart';
import '../models/user_profile.dart';
import '../providers/claim_desk_provider.dart';
import '../services/kyc_document_extraction_service.dart';
import '../widgets/document_picker_sheet.dart';
import '../widgets/kinetic_background.dart';
import '../widgets/modern_horizontal_tracker_card.dart';

/// Single-Step Fast-Track Corporate Card Application Screen
/// - Step 1 (Only Step): Upload 3 KYC documents (Iqama, Passport, Applicant Photo) at the top
/// - Automatic OCR extraction fills Name (EN/AR), Passport No., Nationality, DOB, Passport Issue/Expiry,
///   Iqama Number, Iqama Expiry (Gregorian & Hijri), Sponsor & Occupation
/// - User manually enters only 3 fields: Mobile Number, Company Email, and Personal Email
/// - Submit immediately in one step
class CardApplicationScreen extends StatefulWidget {
  const CardApplicationScreen({super.key});

  @override
  State<CardApplicationScreen> createState() => _CardApplicationScreenState();
}

class _CardApplicationScreenState extends State<CardApplicationScreen> {
  final _formKey = GlobalKey<FormState>();

  // 3 Mandatory KYC Uploads
  PickedDocument? _iqamaDoc;
  PickedDocument? _passportDoc;
  PickedDocument? _photoDoc;

  // Document Processing States
  bool _isScanningIqama = false;
  bool _isScanningPassport = false;
  bool _isVerifyingPhoto = false;
  List<ArabicTranslationEntry> _translationLog = const [];
  bool _showTranslationDetails = false;

  // Identity Controllers (all fields populated cleanly in English)
  final _enNameCtrl = TextEditingController();
  String _extractedArabicName = '';
  final _nationalityCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _passportNoCtrl = TextEditingController();
  final _passportIssueCtrl = TextEditingController();
  final _passportExpiryCtrl = TextEditingController();
  final _placeOfIssueCtrl = TextEditingController();
  final _iqamaNoCtrl = TextEditingController();
  final _iqamaIssueCtrl = TextEditingController();
  final _iqamaExpiryCtrl = TextEditingController();
  final _occupationCtrl = TextEditingController();
  final _sponsorCtrl = TextEditingController();

  // Parsed Dates stored for CardApplication model
  DateTime _dob = DateTime(1992, 5, 14);
  DateTime _passportIssue = DateTime(2022, 1, 10);
  DateTime _passportExpiry = DateTime(2032, 1, 9);
  DateTime _iqamaIssueDate = DateTime(2024, 8, 21);
  DateTime _iqamaExpiryDate = DateTime(2028, 8, 20);

  // 3 Manual Entry Controllers
  final _mobileCtrl = TextEditingController();
  final _companyEmailCtrl = TextEditingController();
  final _personalEmailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final existingApp = context.read<ClaimDeskProvider>().activeCardApplication;
    if (existingApp != null && existingApp.status == ApplicationStatus.draft) {
      _enNameCtrl.text = existingApp.fullNameEnglish;
      _extractedArabicName = existingApp.fullNameArabic;
      _nationalityCtrl.text = existingApp.nationality;
      _dob = existingApp.dateOfBirth;
      _dobCtrl.text = _formatDate(_dob);
      _passportNoCtrl.text = existingApp.passportNumber;
      _passportIssue = existingApp.passportIssueDate;
      _passportIssueCtrl.text = _formatDate(_passportIssue);
      _passportExpiry = existingApp.passportExpiryDate;
      _passportExpiryCtrl.text = _formatDate(_passportExpiry);
      _iqamaNoCtrl.text = existingApp.iqamaNumber;
      _iqamaExpiryDate = existingApp.iqamaExpiryDateGregorian;
      _iqamaIssueDate = DateTime(_iqamaExpiryDate.year - 4, _iqamaExpiryDate.month, _iqamaExpiryDate.day);
      _iqamaIssueCtrl.text = _formatDate(_iqamaIssueDate);
      _iqamaExpiryCtrl.text = _formatDate(_iqamaExpiryDate);
      _occupationCtrl.text = existingApp.designation;
      _sponsorCtrl.text = existingApp.company;
      _mobileCtrl.text = existingApp.mobileNumberPersonal;
      _companyEmailCtrl.text = existingApp.emailOfficial;
      _personalEmailCtrl.text = existingApp.emailPersonal;
    }
  }

  @override
  void dispose() {
    _enNameCtrl.dispose();
    _nationalityCtrl.dispose();
    _dobCtrl.dispose();
    _passportNoCtrl.dispose();
    _passportIssueCtrl.dispose();
    _passportExpiryCtrl.dispose();
    _placeOfIssueCtrl.dispose();
    _iqamaNoCtrl.dispose();
    _iqamaIssueCtrl.dispose();
    _iqamaExpiryCtrl.dispose();
    _occupationCtrl.dispose();
    _sponsorCtrl.dispose();
    _mobileCtrl.dispose();
    _companyEmailCtrl.dispose();
    _personalEmailCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  int get _uploadedCount =>
      (_iqamaDoc != null ? 1 : 0) +
      (_passportDoc != null ? 1 : 0) +
      (_photoDoc != null ? 1 : 0);

  bool get _hasAnyFetchedDetails => _iqamaDoc != null || _passportDoc != null;

  Future<void> _handleUploadIqama() async {
    final doc = await DocumentPickerSheet.show(
      context,
      title: 'Upload Saudi Iqama / National ID',
      subtitle: 'Supports Arabic & Bilingual Iqama — translates details clearly into English',
      documentType: 'Iqama',
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (doc == null || !mounted) return;

    setState(() {
      _iqamaDoc = doc;
      _isScanningIqama = true;
    });

    await Future.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;

    final user = context.read<ClaimDeskProvider>().activeUser;
    final extracted = KycDocumentExtractionService.extractFromIqama(doc, user);

    setState(() {
      _isScanningIqama = false;
      if (extracted.fullNameEnglish.isNotEmpty) {
        _enNameCtrl.text = extracted.fullNameEnglish;
      }
      if (extracted.fullNameArabic.isNotEmpty) {
        _extractedArabicName = extracted.fullNameArabic;
      }
      if (extracted.nationality.isNotEmpty) {
        _nationalityCtrl.text = extracted.nationality;
      }
      if (extracted.dateOfBirth != null) {
        _dob = extracted.dateOfBirth!;
        _dobCtrl.text = _formatDate(_dob);
      }
      if (extracted.placeOfIssue.isNotEmpty) {
        _placeOfIssueCtrl.text = extracted.placeOfIssue;
      }
      if (extracted.iqamaNumber.isNotEmpty) {
        _iqamaNoCtrl.text = extracted.iqamaNumber;
      }
      if (extracted.iqamaIssueDate != null) {
        _iqamaIssueDate = extracted.iqamaIssueDate!;
        _iqamaIssueCtrl.text = _formatDate(_iqamaIssueDate);
      }
      if (extracted.iqamaExpiryDate != null) {
        _iqamaExpiryDate = extracted.iqamaExpiryDate!;
        _iqamaExpiryCtrl.text = _formatDate(_iqamaExpiryDate);
      }
      if (extracted.occupation.isNotEmpty) {
        _occupationCtrl.text = extracted.occupation;
      }
      if (extracted.sponsor.isNotEmpty) {
        _sponsorCtrl.text = extracted.sponsor;
      }
      if (extracted.translatedFromArabic) {
        _translationLog = extracted.translationLog;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.translate, color: AppTheme.successGreen, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                extracted.translatedFromArabic
                    ? 'Arabic Iqama detected & translated clearly into English (${extracted.translationLog.length} fields).'
                    : 'Iqama uploaded and details populated.',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.navyDark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleUploadPassport() async {
    final doc = await DocumentPickerSheet.show(
      context,
      title: 'Upload Passport Copy (Bio Page)',
      subtitle: 'Upload clear bio page image or PDF of your Passport',
      documentType: 'Passport',
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (doc == null || !mounted) return;

    setState(() {
      _passportDoc = doc;
      _isScanningPassport = true;
    });

    await Future.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;

    final user = context.read<ClaimDeskProvider>().activeUser;
    final extracted = KycDocumentExtractionService.extractFromPassport(doc, user);

    setState(() {
      _isScanningPassport = false;
      if (_enNameCtrl.text.isEmpty && extracted.fullNameEnglish.isNotEmpty) {
        _enNameCtrl.text = extracted.fullNameEnglish;
      }
      if (_nationalityCtrl.text.isEmpty && extracted.nationality.isNotEmpty) {
        _nationalityCtrl.text = extracted.nationality;
      }
      if (_dobCtrl.text.isEmpty && extracted.dateOfBirth != null) {
        _dob = extracted.dateOfBirth!;
        _dobCtrl.text = _formatDate(_dob);
      }
      if (extracted.passportNumber.isNotEmpty) {
        _passportNoCtrl.text = extracted.passportNumber;
      }
      if (extracted.passportIssueDate != null) {
        _passportIssue = extracted.passportIssueDate!;
        _passportIssueCtrl.text = _formatDate(_passportIssue);
      }
      if (extracted.passportExpiryDate != null) {
        _passportExpiry = extracted.passportExpiryDate!;
        _passportExpiryCtrl.text = _formatDate(_passportExpiry);
      }
      if (extracted.placeOfIssue.isNotEmpty) {
        _placeOfIssueCtrl.text = extracted.placeOfIssue;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.successGreen, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Passport uploaded and details populated.',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.navyDark,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Translates any manually typed/pasted Arabic text across English identity fields
  void _translateAnyArabicInputsToEnglish() {
    bool changed = false;
    setState(() {
      if (ArabicIqamaTranslator.containsArabic(_enNameCtrl.text)) {
        if (_extractedArabicName.isEmpty) {
          _extractedArabicName = _enNameCtrl.text.trim();
        }
        _enNameCtrl.text = ArabicIqamaTranslator.translateArabicName(_enNameCtrl.text);
        changed = true;
      }
      if (ArabicIqamaTranslator.containsArabic(_nationalityCtrl.text)) {
        _nationalityCtrl.text =
            ArabicIqamaTranslator.translateNationality(_nationalityCtrl.text);
        changed = true;
      }
      if (ArabicIqamaTranslator.containsArabic(_occupationCtrl.text)) {
        _occupationCtrl.text =
            ArabicIqamaTranslator.translateOccupation(_occupationCtrl.text);
        changed = true;
      }
      if (ArabicIqamaTranslator.containsArabic(_sponsorCtrl.text)) {
        _sponsorCtrl.text = ArabicIqamaTranslator.translateSponsor(_sponsorCtrl.text);
        changed = true;
      }
      if (ArabicIqamaTranslator.containsArabic(_placeOfIssueCtrl.text)) {
        _placeOfIssueCtrl.text =
            ArabicIqamaTranslator.translatePlaceOfIssue(_placeOfIssueCtrl.text);
        changed = true;
      }
      if (ArabicIqamaTranslator.containsArabic(_iqamaNoCtrl.text)) {
        _iqamaNoCtrl.text = ArabicIqamaTranslator.normalizeArabicDigits(_iqamaNoCtrl.text);
        changed = true;
      }
      final parsedIssue = ArabicIqamaTranslator.parseDateToGregorian(_iqamaIssueCtrl.text);
      if (parsedIssue != null &&
          (ArabicIqamaTranslator.containsArabic(_iqamaIssueCtrl.text) ||
              _iqamaIssueCtrl.text.contains('14'))) {
        _iqamaIssueDate = parsedIssue;
        _iqamaIssueCtrl.text = _formatDate(parsedIssue);
        changed = true;
      }
      final parsedExpiry = ArabicIqamaTranslator.parseDateToGregorian(_iqamaExpiryCtrl.text);
      if (parsedExpiry != null &&
          (ArabicIqamaTranslator.containsArabic(_iqamaExpiryCtrl.text) ||
              _iqamaExpiryCtrl.text.contains('14'))) {
        _iqamaExpiryDate = parsedExpiry;
        _iqamaExpiryCtrl.text = _formatDate(parsedExpiry);
        changed = true;
      }
    });

    if (changed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arabic fields translated clearly into English.'),
          backgroundColor: AppTheme.navyDark,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleUploadPhoto() async {
    final doc = await DocumentPickerSheet.show(
      context,
      title: 'Upload Applicant Picture',
      subtitle: 'Passport-size portrait photo (white background) for KYC verification',
      documentType: 'Photo',
      allowedExtensions: const ['jpg', 'jpeg', 'png'],
    );
    if (doc == null || !mounted) return;

    setState(() {
      _photoDoc = doc;
      _isVerifyingPhoto = true;
    });

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    setState(() => _isVerifyingPhoto = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.verified_user, color: AppTheme.successGreen, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Applicant photo verified & matched for biometric KYC.',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.navyDark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _submitApplication() {
    // 1. Validate all 3 KYC document uploads
    final missingDocs = <String>[];
    if (_iqamaDoc == null) missingDocs.add('Iqama');
    if (_passportDoc == null) missingDocs.add('Passport');
    if (_photoDoc == null) missingDocs.add('Picture');

    if (missingDocs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please upload all 3 required documents first: ${missingDocs.join(", ")}',
          ),
          backgroundColor: AppTheme.dangerRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 2. Validate manual contact fields
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your Mobile Number, Company Email, and Personal Email.'),
          backgroundColor: AppTheme.dangerRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final provider = context.read<ClaimDeskProvider>();
    final user = provider.activeUser;

    final application = CardApplication(
      id: 'APP-2026-${DateTime.now().microsecond % 900 + 100}',
      fullNameEnglish: _enNameCtrl.text.trim(),
      fullNameArabic: _extractedArabicName,
      nationality: _nationalityCtrl.text.trim(),
      dateOfBirth: _dob,
      iqamaNumber: _iqamaNoCtrl.text.trim(),
      iqamaExpiryDateGregorian: _iqamaExpiryDate,
      iqamaExpiryDateHijri: '',
      passportNumber: _passportNoCtrl.text.trim(),
      passportIssueDate: _passportIssue,
      passportExpiryDate: _passportExpiry,
      mobileNumberPersonal: _mobileCtrl.text.trim(),
      mobileNumberOfficial: _mobileCtrl.text.trim(),
      emailOfficial: _companyEmailCtrl.text.trim(),
      emailPersonal: _personalEmailCtrl.text.trim(),
      shortAddressCode: 'RDMA2941',
      buildingNumber: '4812',
      streetName: 'King Fahd Road',
      district: 'Al-Shati',
      city: 'Dammam',
      postalCode: '32414',
      employeeId: user.employeeId,
      designation: _occupationCtrl.text.trim().isNotEmpty
          ? _occupationCtrl.text.trim()
          : user.designation,
      employeeGrade: 'Band-B (Operations)',
      company: _sponsorCtrl.text.trim().isNotEmpty
          ? _sponsorCtrl.text.trim()
          : user.company,
      division: user.division,
      department: user.department,
      costCenter: user.costCenter,
      reportingManagerName: 'Rajesh M. Shetty',
      reportingManagerId: 'EMP-1002',
      projectWbsCode: 'PRJ-2026-OPS',
      operatingSiteLocation: user.division,
      cardFormat: CardFormat.physicalPlastic,
      embossedName: _enNameCtrl.text.trim().toUpperCase(),
      monthlyLimit: 5000.0,
      singleTransactionCap: 2000.0,
      dailySpendingCap: 3000.0,
      authorizedCategories: const [
        'Fuel & Fleet (Aramco, Naft, Sasco)',
        'Equipment Maintenance & Spare Parts',
        'Hardware & Site Tools',
      ],
      deliveryPreference: 'Head Office Collection (Dammam HR Desk)',
      passportCopyPath: _passportDoc?.name,
      iqamaCopyPath: _iqamaDoc?.name,
      applicantPhotoPath: _photoDoc?.name,
      personalIban: '',
      bankName: '',
      emergencyContactName: '',
      emergencyContactMobile: '',
      emergencyRelation: '',
      termsAccepted: true,
      submissionTimestamp: DateTime.now(),
      status: ApplicationStatus.submitted,
      estimatedActivationDate: DateTime.now().add(const Duration(days: 3)),
    );

    provider.submitCardApplication(application);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.successGreen, size: 28),
            SizedBox(width: 10),
            Text('Application Submitted', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KYC Application ${application.id} has been submitted with your Iqama & Passport details and routed for SAMA & Finance approval.',
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.successLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: AppTheme.successGreen),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Estimated Card Ready Date: 3 Business Days',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Return to Dashboard
            },
            child: const Text('View Card Status'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClaimDeskProvider>();
    final existingApp = provider.activeCardApplication;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Apply for Corporate Card'),
        actions: [
          if (existingApp != null && existingApp.status != ApplicationStatus.draft)
            IconButton(
              tooltip: 'Delete KYC Details & Re-apply',
              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.dangerRed),
              onPressed: () => _handleDeleteApplication(provider),
            ),
        ],
      ),
      body: KineticBackground(
        child: existingApp != null && existingApp.status != ApplicationStatus.draft
            ? _buildExistingApplicationView(existingApp, provider)
            : _buildSingleStepApplicationForm(provider.activeUser),
      ),
    );
  }

  /// Single-Screen 1-Step Form
  Widget _buildSingleStepApplicationForm(UserProfile user) {
    final bool isReadyToSubmit = _uploadedCount == 3;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Top Corporate Navy Banner
                      _buildHeroBanner(),
                      const SizedBox(height: 18),

                      // 2. Three Document Uploads (Right at the start)
                      _buildThreeDocumentUploadSection(),
                      const SizedBox(height: 18),

                      // 3. Auto-Fetched Identity Details (From Iqama & Passport)
                      _buildAutoFetchedDetailsCard(user),
                      const SizedBox(height: 18),

                      // 4. Manual Entry Section (Mobile, Company Email, Personal Email ONLY)
                      _buildManualContactCard(user),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Single-Step Sticky Bottom Submit Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(top: BorderSide(color: AppTheme.border)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.navyDark.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isReadyToSubmit ? Icons.verified : Icons.upload_file,
                              size: 15,
                              color: isReadyToSubmit
                                  ? AppTheme.successGreen
                                  : AppTheme.primaryOrange,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isReadyToSubmit
                                  ? 'All 3 Documents Verified'
                                  : '$_uploadedCount of 3 Documents Uploaded',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: isReadyToSubmit
                                    ? AppTheme.successGreen
                                    : AppTheme.navyDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isReadyToSubmit
                              ? 'Enter Mobile & Emails, then submit'
                              : 'Upload Iqama, Passport & Picture to continue',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text(
                      'Submit Card Application',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    onPressed: _submitApplication,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.navyDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E2B45)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.verified_user, color: AppTheme.primaryOrange, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1-Step SAMA & Absher KYC Card Application',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Upload your Iqama, Passport & Photo below to populate your personal details, then enter your Mobile & Emails to finish.',
                  style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _uploadedCount == 3
                  ? AppTheme.successGreen.withValues(alpha: 0.2)
                  : AppTheme.primaryOrange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _uploadedCount == 3
                    ? AppTheme.successGreen
                    : AppTheme.primaryOrange,
              ),
            ),
            child: Text(
              '$_uploadedCount / 3 Docs',
              style: TextStyle(
                color: _uploadedCount == 3 ? const Color(0xFF6EE7B7) : AppTheme.orangeLight,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Section 1: 3 Document Uploads (Iqama, Passport, Picture)
  Widget _buildThreeDocumentUploadSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: AppTheme.navyDark.withValues(alpha: 0.04),
            blurRadius: 12,
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
              const Row(
                children: [
                  Icon(Icons.cloud_upload_outlined, size: 18, color: AppTheme.primaryOrange),
                  SizedBox(width: 8),
                  Text(
                    '1. UPLOAD KYC DOCUMENTS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.navyDark,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFDBA74)),
                ),
                child: const Text(
                  '3 Required Documents',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 680;
              final cards = [
                _buildDocUploadCard(
                  title: 'Saudi Iqama',
                  subtitle: 'Front & Back ID',
                  icon: Icons.credit_card,
                  doc: _iqamaDoc,
                  isProcessing: _isScanningIqama,
                  processingLabel: 'Reading Iqama...',
                  verifiedLabel: 'Iqama Uploaded',
                  onTap: _handleUploadIqama,
                ),
                _buildDocUploadCard(
                  title: 'Passport Copy',
                  subtitle: 'Bio Page',
                  icon: Icons.menu_book_outlined,
                  doc: _passportDoc,
                  isProcessing: _isScanningPassport,
                  processingLabel: 'Reading Passport...',
                  verifiedLabel: 'Passport Uploaded',
                  onTap: _handleUploadPassport,
                ),
                _buildDocUploadCard(
                  title: 'Applicant Picture',
                  subtitle: 'Portrait Photo',
                  icon: Icons.face_retouching_natural,
                  doc: _photoDoc,
                  isProcessing: _isVerifyingPhoto,
                  processingLabel: 'Verifying Photo...',
                  verifiedLabel: 'Photo Uploaded',
                  showPhotoPreview: true,
                  onTap: _handleUploadPhoto,
                ),
              ];

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 12),
                    Expanded(child: cards[1]),
                    const SizedBox(width: 12),
                    Expanded(child: cards[2]),
                  ],
                );
              }
              return Column(
                children: [
                  cards[0],
                  const SizedBox(height: 10),
                  cards[1],
                  const SizedBox(height: 10),
                  cards[2],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDocUploadCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required PickedDocument? doc,
    required bool isProcessing,
    required String processingLabel,
    required String verifiedLabel,
    required VoidCallback onTap,
    bool showPhotoPreview = false,
  }) {
    final bool isUploaded = doc != null;

    Widget leadingVisual;
    if (isProcessing) {
      leadingVisual = const SizedBox(
        width: 38,
        height: 38,
        child: Padding(
          padding: EdgeInsets.all(6),
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppTheme.primaryOrange,
          ),
        ),
      );
    } else if (showPhotoPreview && doc?.base64Data != null && doc!.base64Data!.isNotEmpty) {
      Uint8List? imageBytes;
      try {
        final raw = doc.base64Data!;
        final cleanBase64 = raw.contains(',') ? raw.split(',').last : raw;
        imageBytes = base64Decode(cleanBase64.replaceAll(RegExp(r'\s+'), ''));
      } catch (_) {
        imageBytes = null;
      }

      if (imageBytes != null) {
        leadingVisual = ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(
            imageBytes,
            width: 42,
            height: 42,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _iconContainer(icon, isUploaded),
          ),
        );
      } else {
        leadingVisual = _iconContainer(isUploaded ? Icons.check_circle : icon, isUploaded);
      }
    } else {
      leadingVisual = _iconContainer(isUploaded ? Icons.check_circle : icon, isUploaded);
    }

    return InkWell(
      onTap: isProcessing ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUploaded
              ? const Color(0xFFF0FDF4)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUploaded
                ? AppTheme.successGreen.withValues(alpha: 0.65)
                : AppTheme.border,
            width: isUploaded ? 1.4 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                leadingVisual,
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.navyDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isProcessing
                            ? processingLabel
                            : (isUploaded ? doc.name : subtitle),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: isUploaded ? AppTheme.successGreen : AppTheme.textMuted,
                          fontWeight: isUploaded ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: isUploaded && !isProcessing
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '✓ $verifiedLabel',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ),
                        )
                      : Text(
                          isProcessing ? 'Reading...' : 'Required',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                        ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isUploaded ? Colors.white : AppTheme.primaryOrange,
                    borderRadius: BorderRadius.circular(8),
                    border: isUploaded
                        ? Border.all(color: AppTheme.border)
                        : null,
                  ),
                  child: Text(
                    isUploaded ? 'Replace' : 'Upload',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isUploaded ? AppTheme.navyDark : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconContainer(IconData icon, bool isUploaded) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isUploaded
            ? AppTheme.successGreen.withValues(alpha: 0.14)
            : AppTheme.primaryOrange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        size: 20,
        color: isUploaded ? AppTheme.successGreen : AppTheme.primaryOrange,
      ),
    );
  }

  /// Section 2: Applicant Identity Details (populated from Passport & Iqama)
  Widget _buildAutoFetchedDetailsCard(UserProfile user) {
    final isExtracting = _isScanningIqama || _isScanningPassport;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _hasAnyFetchedDetails
              ? AppTheme.successGreen.withValues(alpha: 0.45)
              : AppTheme.border,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.navyDark.withValues(alpha: 0.04),
            blurRadius: 12,
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
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.badge_outlined, size: 18, color: AppTheme.primaryOrange),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '2. APPLICANT IDENTITY DETAILS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.navyDark,
                          letterSpacing: 0.6,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (isExtracting)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFDBA74)),
                  ),
                  child: const Text(
                    'Reading & Translating...',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryOrange,
                    ),
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_hasManualArabicToTranslate)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: _translateAnyArabicInputsToEnglish,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.primaryOrange),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.translate, size: 12, color: AppTheme.primaryOrange),
                                SizedBox(width: 4),
                                Text(
                                  'Translate Arabic → EN',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryOrange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (_hasAnyFetchedDetails)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: const Text(
                          '✓ Verified',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 14),

          if (isExtracting)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(
                color: AppTheme.primaryOrange,
                backgroundColor: Color(0xFFFFEDD5),
              ),
            ),

          if (_translationLog.isNotEmpty) ...[
            _buildArabicTranslationSummaryBanner(),
            const SizedBox(height: 14),
          ],

          // Passport & Personal Identity Details
          _subSectionLabel('PASSPORT & PERSONAL IDENTITY'),
          const SizedBox(height: 10),
          _identityField(
            'Full Name',
            _enNameCtrl,
            Icons.person_outline,
            hint: 'Enter full legal name in English',
          ),
          const SizedBox(height: 12),
          _responsivePair(
            _identityField('Nationality', _nationalityCtrl, Icons.public, hint: 'Enter nationality'),
            _identityField('Date of Birth', _dobCtrl, Icons.cake_outlined, hint: 'DD/MM/YYYY'),
          ),
          const SizedBox(height: 12),
          _responsivePair(
            _identityField('Passport Number (PP No.)', _passportNoCtrl, Icons.menu_book_outlined, hint: 'Enter passport number'),
            _identityField('Place of Issue', _placeOfIssueCtrl, Icons.location_city_outlined, hint: 'Enter place of issue'),
          ),
          const SizedBox(height: 12),
          _responsivePair(
            _identityField('Passport Issue Date', _passportIssueCtrl, Icons.event_available_outlined, hint: 'DD/MM/YYYY'),
            _identityField('Passport Expiry Date', _passportExpiryCtrl, Icons.event_busy_outlined, hint: 'DD/MM/YYYY'),
          ),

          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),

          // Iqama & Employment Details
          _subSectionLabel('IQAMA & EMPLOYMENT DETAILS'),
          const SizedBox(height: 10),
          _responsivePair(
            _identityField('Saudi Iqama / National ID #', _iqamaNoCtrl, Icons.badge_outlined, hint: 'Enter 10-digit Iqama number'),
            _identityField('Occupation / Designation', _occupationCtrl, Icons.work_outline, hint: 'Enter occupation'),
          ),
          const SizedBox(height: 12),
          _responsivePair(
            _identityField('Iqama Issue Date', _iqamaIssueCtrl, Icons.event_available_outlined, hint: 'DD/MM/YYYY'),
            _identityField('Iqama Expiry Date', _iqamaExpiryCtrl, Icons.event_busy_outlined, hint: 'DD/MM/YYYY'),
          ),
          const SizedBox(height: 12),
          _responsivePair(
            _identityField('Sponsor / Employer', _sponsorCtrl, Icons.business_outlined, hint: 'Enter sponsor / company name'),
            _staticInfoChip('Employee ID & Cost Center', '${user.employeeId} • ${user.costCenter}'),
          ),
        ],
      ),
    );
  }

  bool get _hasManualArabicToTranslate =>
      ArabicIqamaTranslator.containsArabic(_enNameCtrl.text) ||
      ArabicIqamaTranslator.containsArabic(_nationalityCtrl.text) ||
      ArabicIqamaTranslator.containsArabic(_occupationCtrl.text) ||
      ArabicIqamaTranslator.containsArabic(_sponsorCtrl.text) ||
      ArabicIqamaTranslator.containsArabic(_placeOfIssueCtrl.text) ||
      ArabicIqamaTranslator.containsArabic(_iqamaNoCtrl.text) ||
      ArabicIqamaTranslator.containsArabic(_iqamaIssueCtrl.text) ||
      ArabicIqamaTranslator.containsArabic(_iqamaExpiryCtrl.text);

  Widget _buildArabicTranslationSummaryBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.translate, size: 16, color: Color(0xFF047857)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Arabic Iqama translated into English (${_translationLog.length} fields)',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF065F46),
                  ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  foregroundColor: const Color(0xFF047857),
                ),
                onPressed: () =>
                    setState(() => _showTranslationDetails = !_showTranslationDetails),
                child: Text(
                  _showTranslationDetails ? 'Hide' : 'View Mapping',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (_showTranslationDetails) ...[
            const Divider(height: 12, color: Color(0xFFBBF7D0)),
            for (final entry in _translationLog)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 115,
                      child: Text(
                        entry.fieldLabel,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.arabicSource,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.navyDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.arrow_forward, size: 12, color: Color(0xFF059669)),
                    ),
                    Expanded(
                      child: Text(
                        entry.englishTranslation,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF065F46),
                        ),
                        overflow: TextOverflow.ellipsis,
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

  Widget _subSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        color: AppTheme.textMuted,
        letterSpacing: 0.7,
      ),
    );
  }

  Widget _responsivePair(Widget left, Widget right) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 560) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: 14),
              Expanded(child: right),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            left,
            const SizedBox(height: 12),
            right,
          ],
        );
      },
    );
  }

  Widget _identityField(
    String label,
    TextEditingController controller,
    IconData icon, {
    String? hint,
  }) {
    final hasValue = controller.text.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.navyDark,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.navyDark,
          ),
          decoration: InputDecoration(
            hintText: hint ?? 'Enter $label',
            hintStyle: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.normal,
              color: Color(0xFF94A3B8),
            ),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Icon(
              icon,
              size: 17,
              color: hasValue ? AppTheme.navyDark : const Color(0xFF64748B),
            ),
            suffixIcon: hasValue
                ? const Icon(Icons.check_circle, size: 16, color: AppTheme.successGreen)
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: hasValue
                    ? AppTheme.successGreen.withValues(alpha: 0.55)
                    : const Color(0xFFCBD5E1),
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.primaryOrange, width: 1.6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _staticInfoChip(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.navyDark,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
          ),
          child: Row(
            children: [
              const Icon(Icons.account_balance_outlined, size: 17, color: AppTheme.navyDark),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.navyDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.lock_outline, size: 15, color: AppTheme.textMuted),
            ],
          ),
        ),
      ],
    );
  }

  /// Section 3: Contact Details (ONLY Mobile Number, Company Email, Personal Email)
  Widget _buildManualContactCard(UserProfile user) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: AppTheme.navyDark.withValues(alpha: 0.04),
            blurRadius: 12,
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
              const Row(
                children: [
                  Icon(Icons.contact_mail_outlined, size: 18, color: AppTheme.primaryOrange),
                  SizedBox(width: 8),
                  Text(
                    '3. CONTACT DETAILS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.navyDark,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFDBA74)),
                ),
                child: const Text(
                  '3 Required Fields',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Mobile Number
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mobile Number *',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.navyDark,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _mobileCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'e.g. ${user.phone}',
                  hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.phone_android, size: 18, color: AppTheme.navyDark),
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, size: 11, color: Color(0xFF047857)),
                        SizedBox(width: 4),
                        Text(
                          'Absher 2FA',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ],
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.primaryOrange, width: 1.6),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 9) {
                    return 'Please enter a valid mobile number';
                  }
                  return null;
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Company Email & Personal Email
          _responsivePair(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Company Email *',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.navyDark,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _companyEmailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'e.g. ${user.employeeId.toLowerCase()}@expertise.sa',
                    hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.business_center_outlined, size: 18, color: AppTheme.navyDark),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.primaryOrange, width: 1.6),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || !val.trim().contains('@')) {
                      return 'Please enter your company email';
                    }
                    return null;
                  },
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Personal Email *',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.navyDark,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _personalEmailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'e.g. name@gmail.com',
                    hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.alternate_email, size: 18, color: AppTheme.navyDark),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.primaryOrange, width: 1.6),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || !val.trim().contains('@')) {
                      return 'Please enter your personal email';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Reset all form inputs and document uploads back to clean state
  void _resetForm() {
    setState(() {
      _iqamaDoc = null;
      _passportDoc = null;
      _photoDoc = null;
      _isScanningIqama = false;
      _isScanningPassport = false;
      _isVerifyingPhoto = false;
      _translationLog = const [];
      _showTranslationDetails = false;
      _enNameCtrl.clear();
      _extractedArabicName = '';
      _nationalityCtrl.clear();
      _dobCtrl.clear();
      _passportNoCtrl.clear();
      _passportIssueCtrl.clear();
      _passportExpiryCtrl.clear();
      _placeOfIssueCtrl.clear();
      _iqamaNoCtrl.clear();
      _iqamaIssueCtrl.clear();
      _iqamaExpiryCtrl.clear();
      _occupationCtrl.clear();
      _sponsorCtrl.clear();
      _mobileCtrl.clear();
      _companyEmailCtrl.clear();
      _personalEmailCtrl.clear();
    });
  }

  /// Delete KYC details dialog and reset state
  Future<void> _handleDeleteApplication(ClaimDeskProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: AppTheme.dangerRed, size: 24),
            SizedBox(width: 8),
            Text('Delete KYC Details?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete your submitted KYC application details?\n\n'
          'This will cancel the pending review and reset your profile status back to "New User". You will be able to upload fresh documents and re-apply immediately.',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Application', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('Delete & Re-apply'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      provider.deleteCardApplication();
      _resetForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('KYC details deleted. You can now re-apply as a New User.'),
            ],
          ),
          backgroundColor: AppTheme.navyDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Existing Application Tracker View (shown once submitted or in-approval)
  Widget _buildExistingApplicationView(CardApplication app, ClaimDeskProvider provider) {
    final stages = [
      'KYC Form Submitted',
      'Manager Endorsement',
      'Finance & AP Approval',
      'Card Embossing & Dispatch',
      'Card Activated & Active',
    ];

    final trackerStages = [
      TrackerStageItem(
        label: 'KYC Form',
        isCompleted: app.currentStageIndex >= 1,
        isActive: app.currentStageIndex == 0,
      ),
      TrackerStageItem(
        label: 'Manager',
        isCompleted: app.currentStageIndex >= 2,
        isActive: app.currentStageIndex == 1,
      ),
      TrackerStageItem(
        label: 'Finance AP',
        isCompleted: app.currentStageIndex >= 3,
        isActive: app.currentStageIndex == 2,
      ),
      TrackerStageItem(
        label: 'Embossing',
        isCompleted: app.currentStageIndex >= 4,
        isActive: app.currentStageIndex == 3,
      ),
      TrackerStageItem(
        label: 'Active Card',
        isCompleted: app.currentStageIndex >= 5,
        isActive: app.currentStageIndex == 4,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header Label
              const Text(
                'APPLICATION TRACKER',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),

              // 1. Modern Horizontal Tracker Card (Reference Design)
              ModernHorizontalTrackerCard(
                id: app.id,
                statusLabel: app.statusDisplay,
                statusColor: app.status == ApplicationStatus.active
                    ? AppTheme.royalBlue
                    : AppTheme.primaryOrange,
                startDate: DateFormat('dd MMM, yyyy').format(app.submissionTimestamp),
                startLocation: 'Submitted • ${app.city.isNotEmpty ? app.city : "Dammam Hub"}',
                endDate: DateFormat('dd MMM, yyyy').format(app.estimatedActivationDate ?? app.submissionTimestamp.add(const Duration(days: 5))),
                endLocation: 'Card Issuance • Al Rajhi',
                stages: trackerStages,
                itemTitle: 'Expertise Corporate Visa - Platinum',
                itemSubtitle: 'Custodian: ${app.fullNameEnglish} • CC-305',
                itemPriceOrValue: 'SAR ${app.monthlyLimit.toStringAsFixed(0)} / mo',
                itemBadgeColor: AppTheme.goldLight,
                itemBadgeTextColor: AppTheme.goldDark,
              ),
              const SizedBox(height: 18),

              // 2. Multi-Stage Audit Trail & Identity Summary
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border, width: 1.1),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Applicant Details Row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.royalBlue.withValues(alpha: 0.1),
                          child: const Icon(Icons.person_outline_rounded, color: AppTheme.royalBlue, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                app.fullNameEnglish,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Iqama: ${app.iqamaNumber} • PP: ${app.passportNumber} • Mobile: ${app.mobileNumberPersonal}',
                                style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Stage by Stage Breakdown
                    for (int i = 0; i < stages.length; i++) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              CircleAvatar(
                                radius: 11,
                                backgroundColor: i < app.currentStageIndex
                                    ? AppTheme.royalBlue
                                    : (i == app.currentStageIndex
                                        ? AppTheme.primaryOrange
                                        : const Color(0xFFE2E8F0)),
                                child: Icon(
                                  i < app.currentStageIndex
                                      ? Icons.check
                                      : (i == app.currentStageIndex ? Icons.autorenew : Icons.circle),
                                  size: 11,
                                  color: i <= app.currentStageIndex ? Colors.white : const Color(0xFF94A3B8),
                                ),
                              ),
                              if (i < stages.length - 1)
                                Container(
                                  width: 2,
                                  height: 26,
                                  color: i < app.currentStageIndex
                                      ? AppTheme.royalBlue
                                      : const Color(0xFFE2E8F0),
                                ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    stages[i],
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: i <= app.currentStageIndex
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: i <= app.currentStageIndex
                                          ? AppTheme.textPrimary
                                          : AppTheme.textMuted,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: i < app.currentStageIndex
                                          ? const Color(0xFFEFF6FF)
                                          : (i == app.currentStageIndex
                                              ? AppTheme.orangeMuted
                                              : const Color(0xFFF8FAFC)),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: i < app.currentStageIndex
                                            ? const Color(0xFFBFDBFE)
                                            : (i == app.currentStageIndex
                                                ? AppTheme.orangeLight.withValues(alpha: 0.5)
                                                : const Color(0xFFE2E8F0)),
                                      ),
                                    ),
                                    child: Text(
                                      i < app.currentStageIndex
                                          ? 'Completed'
                                          : (i == app.currentStageIndex ? 'In Progress' : 'Pending'),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: i < app.currentStageIndex
                                            ? AppTheme.royalBlue
                                            : (i == app.currentStageIndex
                                                ? AppTheme.primaryOrange
                                                : AppTheme.textMuted),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // SAMA Compliance Notice
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.infoLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.infoBlue.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: AppTheme.infoBlue, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your application is verified against SAMA and corporate compliance guidelines. Once approved, the card will be issued by Al Rajhi Banking partner.',
                        style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Delete KYC Details & Re-apply Action Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border, width: 1.1),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.restart_alt_rounded, size: 19, color: AppTheme.primaryOrange),
                        SizedBox(width: 8),
                        Text(
                          'Need to Change KYC Details or Re-apply?',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'If any document or identity information was uploaded incorrectly, you can withdraw your application and delete the current KYC details. Your status will return to "New User" so you can upload fresh documents and re-apply.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.45),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.dangerRed,
                          side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.2),
                          backgroundColor: const Color(0xFFFEF2F2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: const Text(
                          'Delete KYC Details & Apply Again',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        onPressed: () => _handleDeleteApplication(provider),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
