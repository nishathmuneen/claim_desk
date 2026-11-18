import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/card_application.dart';
import '../providers/claim_desk_provider.dart';
import '../widgets/document_picker_sheet.dart';
import '../widgets/kinetic_background.dart';

class CardApplicationScreen extends StatefulWidget {
  const CardApplicationScreen({super.key});

  @override
  State<CardApplicationScreen> createState() => _CardApplicationScreenState();
}

class _CardApplicationScreenState extends State<CardApplicationScreen> {
  int _currentStep = 0;

  // Step 1 Controllers
  final _enNameCtrl = TextEditingController();
  final _arNameCtrl = TextEditingController();
  final _nationalityCtrl = TextEditingController(text: 'Saudi Arabia');
  final _iqamaCtrl = TextEditingController();
  final _passportCtrl = TextEditingController();
  final _mobilePersonalCtrl = TextEditingController();
  final _mobileOfficialCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  // National Address
  final _shortAddressCtrl = TextEditingController(text: 'RDMA2941');
  final _buildingCtrl = TextEditingController(text: '4812');
  final _streetCtrl = TextEditingController(text: 'King Fahd Road');
  final _districtCtrl = TextEditingController(text: 'Al-Shati');
  final _cityCtrl = TextEditingController(text: 'Dammam');
  final _postalCtrl = TextEditingController(text: '32414');

  DateTime _dob = DateTime(1992, 5, 14);
  DateTime _iqamaExpGregorian = DateTime(2028, 8, 20);
  String _iqamaExpHijri = '1450/03/01';
  final DateTime _passportIssue = DateTime(2022, 1, 10);
  final DateTime _passportExpiry = DateTime(2032, 1, 9);

  // Step 2 Controllers
  final _projectWbsCtrl = TextEditingController(text: 'Aramco-RT-9402');
  final _operatingSiteCtrl = TextEditingController(text: 'Ras Tanura Refinery Zone');
  final _embossedNameCtrl = TextEditingController();
  CardFormat _cardFormat = CardFormat.physicalPlastic;
  double _monthlyLimit = 10000.0;
  final _singleCapCtrl = TextEditingController(text: '2000');
  final _dailyCapCtrl = TextEditingController(text: '3000');
  String _deliveryPref = 'Head Office Collection (Dammam HR Desk)';
  final _siteContactNameCtrl = TextEditingController();
  final _siteContactMobileCtrl = TextEditingController();

  final List<String> _selectedCategories = [
    'Fuel & Fleet (Aramco, Naft, Sasco)',
    'Equipment Maintenance & Spare Parts',
    'Hardware & Site Tools',
  ];

  final List<String> _availableCategories = [
    'Fuel & Fleet (Aramco, Naft, Sasco)',
    'Equipment Maintenance & Spare Parts',
    'Hardware & Site Tools',
    'Courier & Freight Logistics',
    'Emergency Site Hospitality & Meals',
    'Government Portals (Balady, Muqeem)',
  ];

  // Step 3 Controllers
  String? _passportDocName;
  String? _iqamaDocName;
  String? _photoDocName;
  final _ibanCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _emergencyNameCtrl = TextEditingController();
  final _emergencyMobileCtrl = TextEditingController();
  final _emergencyRelationCtrl = TextEditingController();

  bool _agreeBusinessUse = false;
  bool _agreeZatcaInvoices = false;
  bool _agreeSalaryDeduction = false;

  // Simple signature canvas state
  final List<Offset?> _signaturePoints = [];

  @override
  void initState() {
    super.initState();
    final user = context.read<ClaimDeskProvider>().activeUser;
    final existingApp = context.read<ClaimDeskProvider>().activeCardApplication;

    _enNameCtrl.text = user.name;
    _iqamaCtrl.text = user.iqama;
    _mobilePersonalCtrl.text = user.phone;
    _emailCtrl.text = '${user.employeeId.toLowerCase()}@expertise.sa';
    _embossedNameCtrl.text = user.name.toUpperCase();

    if (existingApp != null) {
      _arNameCtrl.text = existingApp.fullNameArabic;
      _passportCtrl.text = existingApp.passportNumber;
      _mobileOfficialCtrl.text = existingApp.mobileNumberOfficial;
      _shortAddressCtrl.text = existingApp.shortAddressCode;
      _buildingCtrl.text = existingApp.buildingNumber;
      _streetCtrl.text = existingApp.streetName;
      _districtCtrl.text = existingApp.district;
      _cityCtrl.text = existingApp.city;
      _postalCtrl.text = existingApp.postalCode;
      _projectWbsCtrl.text = existingApp.projectWbsCode;
      _operatingSiteCtrl.text = existingApp.operatingSiteLocation;
      _cardFormat = existingApp.cardFormat;
      _monthlyLimit = existingApp.monthlyLimit;
      _passportDocName = existingApp.passportCopyPath;
      _iqamaDocName = existingApp.iqamaCopyPath;
      _photoDocName = existingApp.applicantPhotoPath;
      _ibanCtrl.text = existingApp.personalIban;
      _bankNameCtrl.text = existingApp.bankName;
      _emergencyNameCtrl.text = existingApp.emergencyContactName;
      _emergencyMobileCtrl.text = existingApp.emergencyContactMobile;
      _emergencyRelationCtrl.text = existingApp.emergencyRelation;
      _agreeBusinessUse = existingApp.termsAccepted;
      _agreeZatcaInvoices = existingApp.termsAccepted;
      _agreeSalaryDeduction = existingApp.termsAccepted;
    } else {
      _arNameCtrl.text = '';
      _passportCtrl.text = '';
      _mobileOfficialCtrl.text = '';
      _shortAddressCtrl.text = '';
      _buildingCtrl.text = '';
      _streetCtrl.text = '';
      _districtCtrl.text = '';
      _cityCtrl.text = '';
      _postalCtrl.text = '';
      _projectWbsCtrl.text = 'Aramco-RT-9402';
      _operatingSiteCtrl.text = user.division;
      _passportDocName = null;
      _iqamaDocName = null;
      _photoDocName = null;
      _ibanCtrl.text = '';
      _bankNameCtrl.text = '';
      _emergencyNameCtrl.text = '';
      _emergencyMobileCtrl.text = '';
      _emergencyRelationCtrl.text = '';
      _agreeBusinessUse = false;
      _agreeZatcaInvoices = false;
      _agreeSalaryDeduction = false;
    }
  }

  @override
  void dispose() {
    _enNameCtrl.dispose();
    _arNameCtrl.dispose();
    _nationalityCtrl.dispose();
    _iqamaCtrl.dispose();
    _passportCtrl.dispose();
    _mobilePersonalCtrl.dispose();
    _mobileOfficialCtrl.dispose();
    _emailCtrl.dispose();
    _shortAddressCtrl.dispose();
    _buildingCtrl.dispose();
    _streetCtrl.dispose();
    _districtCtrl.dispose();
    _cityCtrl.dispose();
    _postalCtrl.dispose();
    _projectWbsCtrl.dispose();
    _operatingSiteCtrl.dispose();
    _embossedNameCtrl.dispose();
    _singleCapCtrl.dispose();
    _dailyCapCtrl.dispose();
    _siteContactNameCtrl.dispose();
    _siteContactMobileCtrl.dispose();
    _ibanCtrl.dispose();
    _bankNameCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyMobileCtrl.dispose();
    _emergencyRelationCtrl.dispose();
    super.dispose();
  }

  void _submitApplication() {
    if (!_agreeBusinessUse || !_agreeZatcaInvoices || !_agreeSalaryDeduction) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept all corporate accountability declarations to proceed.'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
      return;
    }

    final provider = context.read<ClaimDeskProvider>();
    final user = provider.activeUser;

    final application = CardApplication(
      id: 'APP-2026-${DateTime.now().microsecond % 900 + 100}',
      fullNameEnglish: _enNameCtrl.text.trim(),
      fullNameArabic: _arNameCtrl.text.trim(),
      nationality: _nationalityCtrl.text.trim(),
      dateOfBirth: _dob,
      iqamaNumber: _iqamaCtrl.text.trim(),
      iqamaExpiryDateGregorian: _iqamaExpGregorian,
      iqamaExpiryDateHijri: _iqamaExpHijri,
      passportNumber: _passportCtrl.text.trim(),
      passportIssueDate: _passportIssue,
      passportExpiryDate: _passportExpiry,
      mobileNumberPersonal: _mobilePersonalCtrl.text.trim(),
      mobileNumberOfficial: _mobileOfficialCtrl.text.trim(),
      emailOfficial: _emailCtrl.text.trim(),
      shortAddressCode: _shortAddressCtrl.text.trim(),
      buildingNumber: _buildingCtrl.text.trim(),
      streetName: _streetCtrl.text.trim(),
      district: _districtCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      postalCode: _postalCtrl.text.trim(),
      employeeId: user.employeeId,
      designation: user.designation,
      employeeGrade: 'Band-B (Senior Operations)',
      company: user.company,
      division: user.division,
      department: user.department,
      costCenter: user.costCenter,
      reportingManagerName: 'Rajesh M. Shetty',
      reportingManagerId: 'EMP-1002',
      projectWbsCode: _projectWbsCtrl.text.trim(),
      operatingSiteLocation: _operatingSiteCtrl.text.trim(),
      cardFormat: _cardFormat,
      embossedName: _embossedNameCtrl.text.trim(),
      monthlyLimit: _monthlyLimit,
      singleTransactionCap: double.tryParse(_singleCapCtrl.text) ?? 2000.0,
      dailySpendingCap: double.tryParse(_dailyCapCtrl.text) ?? 3000.0,
      authorizedCategories: _selectedCategories,
      deliveryPreference: _deliveryPref,
      siteReceivingContactName: _siteContactNameCtrl.text.trim(),
      siteReceivingContactMobile: _siteContactMobileCtrl.text.trim(),
      passportCopyPath: _passportDocName,
      iqamaCopyPath: _iqamaDocName,
      applicantPhotoPath: _photoDocName,
      signatureSpecimenPath: 'digital_canvas_signed.png',
      personalIban: _ibanCtrl.text.trim(),
      bankName: _bankNameCtrl.text.trim(),
      emergencyContactName: _emergencyNameCtrl.text.trim(),
      emergencyContactMobile: _emergencyMobileCtrl.text.trim(),
      emergencyRelation: _emergencyRelationCtrl.text.trim(),
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
              'KYC Application ${application.id} has been submitted for SAMA compliance and routed to Line Manager & AP Finance.',
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
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
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
        title: const Text('Apply for Petty Cash Card'),
      ),
      body: KineticBackground(
        child: existingApp != null && existingApp.status != ApplicationStatus.draft
            ? _buildExistingApplicationView(existingApp)
            : _buildWizardForm(),
      ),
    );
  }

  Widget _buildExistingApplicationView(CardApplication app) {
    final stages = [
      'KYC Form Submitted',
      'Manager Endorsement',
      'Finance & AP Approval',
      'Card Embossing & Dispatch',
      'Card Activated & Active',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.navyDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      app.id,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryOrange),
                      ),
                      child: Text(
                        app.statusDisplay,
                        style: const TextStyle(color: AppTheme.orangeLight, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Requested Limit: SAR ${app.monthlyLimit.toStringAsFixed(0)} • ${app.cardFormat == CardFormat.physicalPlastic ? "Physical Plastic" : "Virtual Digital"}',
                  style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12.5),
                ),
                const SizedBox(height: 4),
                Text(
                  'Project: ${app.projectWbsCode} • Site: ${app.operatingSiteLocation}',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Multi-Stage Tracker
          const Text(
            'APPLICATION TRACKER',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 0.8),
          ),
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                children: [
                  for (int i = 0; i < stages.length; i++) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: i <= app.currentStageIndex
                                  ? AppTheme.successGreen
                                  : (i == app.currentStageIndex + 1 ? AppTheme.primaryOrange : const Color(0xFFE2E8F0)),
                              child: Icon(
                                i <= app.currentStageIndex ? Icons.check : Icons.circle,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                            if (i < stages.length - 1)
                              Container(
                                width: 2,
                                height: 32,
                                color: i < app.currentStageIndex
                                    ? AppTheme.successGreen
                                    : const Color(0xFFE2E8F0),
                              ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stages[i],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: i <= app.currentStageIndex ? FontWeight.bold : FontWeight.normal,
                                  color: i <= app.currentStageIndex ? AppTheme.textPrimary : AppTheme.textMuted,
                                ),
                              ),
                              Text(
                                i < app.currentStageIndex
                                    ? 'Completed'
                                    : (i == app.currentStageIndex ? 'In Progress' : 'Pending'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: i == app.currentStageIndex ? AppTheme.primaryOrange : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

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
        ],
      ),
    );
  }

  Widget _buildWizardForm() {
    return Column(
      children: [
        // Top Stepper Bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _stepIndicator(0, '1. Personal & KYC'),
              _stepDivider(0),
              _stepIndicator(1, '2. Card Controls'),
              _stepDivider(1),
              _stepIndicator(2, '3. Uploads & Sign'),
            ],
          ),
        ),
        const Divider(height: 1),

        // Wizard Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_currentStep == 0) _buildStep1Personal(),
                if (_currentStep == 1) _buildStep2Controls(),
                if (_currentStep == 2) _buildStep3Uploads(),
              ],
            ),
          ),
        ),

        // Bottom Navigation Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppTheme.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentStep > 0)
                OutlinedButton.icon(
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Previous'),
                  onPressed: () => setState(() => _currentStep--),
                )
              else
                const SizedBox.shrink(),
              ElevatedButton.icon(
                icon: Icon(_currentStep == 2 ? Icons.check : Icons.arrow_forward, size: 16),
                label: Text(_currentStep == 2 ? 'Submit KYC Application' : 'Next Step'),
                onPressed: () {
                  if (_currentStep < 2) {
                    setState(() => _currentStep++);
                  } else {
                    _submitApplication();
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepIndicator(int stepIndex, String title) {
    final isActive = _currentStep == stepIndex;
    final isDone = _currentStep > stepIndex;
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: isDone
                ? AppTheme.successGreen
                : (isActive ? AppTheme.primaryOrange : const Color(0xFFE2E8F0)),
            child: isDone
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : Text(
                    '${stepIndex + 1}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? AppTheme.primaryOrange : AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepDivider(int stepIndex) {
    return Container(
      width: 16,
      height: 1.5,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: _currentStep > stepIndex ? AppTheme.successGreen : AppTheme.border,
    );
  }

  // STEP 1: Personal & Legal Identity
  Widget _buildStep1Personal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SAMA Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.navyDark,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified_user, color: AppTheme.primaryOrange, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Saudi Central Bank (SAMA) Compliance & Absher KYC onboarding.',
                  style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        const Text('APPLICANT LEGAL IDENTITY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
        const SizedBox(height: 12),
        TextField(controller: _enNameCtrl, decoration: const InputDecoration(labelText: 'Full Legal Name (as in Passport)')),
        const SizedBox(height: 10),
        TextField(controller: _arNameCtrl, decoration: const InputDecoration(labelText: 'Full Name in Arabic (as in Iqama)')),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: TextField(controller: _nationalityCtrl, decoration: const InputDecoration(labelText: 'Nationality'))),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dob,
                    firstDate: DateTime(1960),
                    lastDate: DateTime(2010),
                  );
                  if (picked != null) setState(() => _dob = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Date of Birth'),
                  child: Text('${_dob.day}/${_dob.month}/${_dob.year}', style: const TextStyle(fontSize: 13)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: TextField(controller: _iqamaCtrl, decoration: const InputDecoration(labelText: 'Saudi Iqama / National ID #'))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _passportCtrl, decoration: const InputDecoration(labelText: 'Passport Number'))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _iqamaExpGregorian,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) setState(() => _iqamaExpGregorian = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Iqama Expiry (Gregorian)'),
                  child: Text('${_iqamaExpGregorian.day}/${_iqamaExpGregorian.month}/${_iqamaExpGregorian.year}', style: const TextStyle(fontSize: 13)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(labelText: 'Iqama Expiry (Hijri)'),
                controller: TextEditingController(text: _iqamaExpHijri),
                onChanged: (v) => _iqamaExpHijri = v,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _mobilePersonalCtrl,
                decoration: InputDecoration(
                  labelText: 'Personal Mobile (Absher)',
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, size: 11, color: Color(0xFF065F46)),
                        SizedBox(width: 3),
                        Text('Absher 2FA', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF065F46))),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _mobileOfficialCtrl, decoration: const InputDecoration(labelText: 'Work Mobile'))),
          ],
        ),
        const SizedBox(height: 10),
        TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Official Corporate Email')),
        const SizedBox(height: 20),

        // National Address Section
        const Text('SAUDI NATIONAL ADDRESS (SPL)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: TextField(controller: _shortAddressCtrl, decoration: const InputDecoration(labelText: 'Short Address Code (e.g. RDMA2941)'))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _buildingCtrl, decoration: const InputDecoration(labelText: 'Building #'))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: TextField(controller: _streetCtrl, decoration: const InputDecoration(labelText: 'Street Name'))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _districtCtrl, decoration: const InputDecoration(labelText: 'District'))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: TextField(controller: _cityCtrl, decoration: const InputDecoration(labelText: 'City'))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _postalCtrl, decoration: const InputDecoration(labelText: 'Postal Code'))),
          ],
        ),
      ],
    );
  }

  // STEP 2: Corporate Allocation & Card Spending Controls
  Widget _buildStep2Controls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PROJECT & COST CENTER ALLOCATION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
        const SizedBox(height: 12),
        TextField(controller: _projectWbsCtrl, decoration: const InputDecoration(labelText: 'Project Name / WBS Code (e.g. Aramco-RT-9402)')),
        const SizedBox(height: 10),
        TextField(controller: _operatingSiteCtrl, decoration: const InputDecoration(labelText: 'Operating Site / Refinery Zone')),
        const SizedBox(height: 20),

        const Text('CARD FORMAT & EMBOSSED NAME', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: RadioListTile<CardFormat>(
                value: CardFormat.physicalPlastic,
                groupValue: _cardFormat,
                title: const Text('Physical Plastic', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text('POS swipe & fuel stations', style: TextStyle(fontSize: 11)),
                onChanged: (v) => setState(() => _cardFormat = v!),
              ),
            ),
            Expanded(
              child: RadioListTile<CardFormat>(
                value: CardFormat.virtualDigital,
                groupValue: _cardFormat,
                title: const Text('Virtual Digital', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text('Instant in-app card', style: TextStyle(fontSize: 11)),
                onChanged: (v) => setState(() => _cardFormat = v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _embossedNameCtrl,
          maxLength: 24,
          decoration: const InputDecoration(labelText: 'Embossed Name on Card (Max 24 chars)'),
        ),
        const SizedBox(height: 16),

        const Text('MONTHLY SPENDING LIMIT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('SAR ${_monthlyLimit.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryOrange)),
            Text('${(_monthlyLimit / 1000).toInt()}k SAR', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
        Slider(
          value: _monthlyLimit,
          min: 2000,
          max: 30000,
          divisions: 28,
          activeColor: AppTheme.primaryOrange,
          onChanged: (val) => setState(() => _monthlyLimit = val),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: TextField(controller: _singleCapCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Single Swipe Cap (SAR)'))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _dailyCapCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Daily Spending Cap (SAR)'))),
          ],
        ),
        const SizedBox(height: 20),

        const Text('AUTHORIZED EXPENSE CATEGORIES (MCC)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
        const SizedBox(height: 8),
        for (final cat in _availableCategories)
          CheckboxListTile(
            dense: true,
            title: Text(cat, style: const TextStyle(fontSize: 12.5)),
            value: _selectedCategories.contains(cat),
            activeColor: AppTheme.primaryOrange,
            onChanged: (checked) {
              setState(() {
                if (checked == true) {
                  _selectedCategories.add(cat);
                } else {
                  _selectedCategories.remove(cat);
                }
              });
            },
          ),
        const SizedBox(height: 16),

        const Text('CARD DELIVERY PREFERENCE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _deliveryPref,
          decoration: const InputDecoration(labelText: 'Collection Method'),
          items: const [
            DropdownMenuItem(value: 'Head Office Collection (Dammam HR Desk)', child: Text('Head Office (Dammam HR Desk)')),
            DropdownMenuItem(value: 'Jubail Operations Hub Collection', child: Text('Jubail Operations Hub')),
            DropdownMenuItem(value: 'Site Courier Dispatch', child: Text('Courier Dispatch to Remote Site')),
          ],
          onChanged: (val) => setState(() => _deliveryPref = val!),
        ),
      ],
    );
  }

  // STEP 3: Document Uploads, Digital Signature & Legal Undertaking
  Widget _buildStep3Uploads() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('BANK-GRADE KYC DOCUMENT UPLOADS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
        const SizedBox(height: 12),
        _uploadTile(
          'Passport Copy (Bio Page)',
          _passportDocName,
          Icons.badge,
          () async {
            final doc = await DocumentPickerSheet.show(
              context,
              title: 'Upload Passport Copy',
              subtitle: 'Select bio page with clear photograph & signature',
              documentType: 'Passport',
              allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
            );
            if (doc != null) {
              setState(() => _passportDocName = doc.name);
            }
          },
        ),
        _uploadTile(
          'Saudi Iqama / ID (Front & Back)',
          _iqamaDocName,
          Icons.credit_card,
          () async {
            final doc = await DocumentPickerSheet.show(
              context,
              title: 'Upload Saudi Iqama / Muqeem ID',
              subtitle: 'Ensure Iqama number and expiry date are fully legible',
              documentType: 'Iqama',
              allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
            );
            if (doc != null) {
              setState(() => _iqamaDocName = doc.name);
            }
          },
        ),
        _uploadTile(
          'Recent Passport-Size Photo (White BG)',
          _photoDocName,
          Icons.face,
          () async {
            final doc = await DocumentPickerSheet.show(
              context,
              title: 'Upload Applicant Photo',
              subtitle: 'Official white background portrait photo or selfie',
              documentType: 'Photo',
              allowedExtensions: const ['jpg', 'jpeg', 'png'],
            );
            if (doc != null) {
              setState(() => _photoDocName = doc.name);
            }
          },
        ),
        const SizedBox(height: 20),

        const Text('DIGITAL SIGNATURE SPECIMEN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
        const SizedBox(height: 8),
        Container(
          height: 130,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border, width: 1.2),
          ),
          child: Stack(
            children: [
              GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    final renderBox = context.findRenderObject() as RenderBox?;
                    if (renderBox != null) {
                      _signaturePoints.add(details.localPosition);
                    }
                  });
                },
                onPanEnd: (_) => _signaturePoints.add(null),
                child: CustomPaint(
                  painter: _SignaturePainter(_signaturePoints),
                  size: Size.infinite,
                ),
              ),
              if (_signaturePoints.isEmpty)
                const Center(
                  child: Text(
                    'Draw your signature here with finger',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                ),
              Positioned(
                top: 6,
                right: 6,
                child: IconButton(
                  icon: const Icon(Icons.refresh, size: 18, color: AppTheme.textSecondary),
                  onPressed: () => setState(() => _signaturePoints.clear()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text('BACKUP SETTLEMENT IBAN (FOR OVERFLOW EXPENSES)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
        const SizedBox(height: 10),
        TextField(controller: _ibanCtrl, decoration: const InputDecoration(labelText: 'Personal Saudi IBAN (SA...)')),
        const SizedBox(height: 10),
        TextField(controller: _bankNameCtrl, decoration: const InputDecoration(labelText: 'Bank Name')),
        const SizedBox(height: 20),

        const Text('EMERGENCY CONTACT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: TextField(controller: _emergencyNameCtrl, decoration: const InputDecoration(labelText: 'Contact Name'))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _emergencyMobileCtrl, decoration: const InputDecoration(labelText: 'Mobile Number'))),
          ],
        ),
        const SizedBox(height: 20),

        const Text('CUSTODIAN LEGAL UNDERTAKINGS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
        const SizedBox(height: 8),
        CheckboxListTile(
          dense: true,
          title: const Text('I understand this card is strictly for authorized Expertise Company operational expenses. Personal use is prohibited.', style: TextStyle(fontSize: 12)),
          value: _agreeBusinessUse,
          activeColor: AppTheme.primaryOrange,
          onChanged: (v) => setState(() => _agreeBusinessUse = v!),
        ),
        CheckboxListTile(
          dense: true,
          title: const Text('I agree to upload official ZATCA-compliant VAT tax invoices for all transactions within 48 hours.', style: TextStyle(fontSize: 12)),
          value: _agreeZatcaInvoices,
          activeColor: AppTheme.primaryOrange,
          onChanged: (v) => setState(() => _agreeZatcaInvoices = v!),
        ),
        CheckboxListTile(
          dense: true,
          title: const Text('I acknowledge that unverified or unauthorized card transactions may be deducted from my monthly payroll.', style: TextStyle(fontSize: 12)),
          value: _agreeSalaryDeduction,
          activeColor: AppTheme.primaryOrange,
          onChanged: (v) => setState(() => _agreeSalaryDeduction = v!),
        ),
      ],
    );
  }

  Widget _uploadTile(String title, String? fileName, IconData icon, VoidCallback onUpload) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: fileName != null ? AppTheme.successGreen.withValues(alpha: 0.6) : AppTheme.border,
          width: fileName != null ? 1.4 : 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  fileName != null ? Icons.check_circle : icon,
                  size: 22,
                  color: fileName != null ? AppTheme.successGreen : AppTheme.primaryOrange,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      const SizedBox(height: 2),
                      if (fileName != null)
                        Text(
                          fileName,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.successGreen),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        const Text('Not uploaded yet (Scan or Choose file)', style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: fileName != null ? AppTheme.surfaceElevated : AppTheme.primaryOrange,
              foregroundColor: fileName != null ? AppTheme.textPrimary : Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              side: fileName != null ? const BorderSide(color: AppTheme.border) : BorderSide.none,
            ),
            icon: Icon(fileName != null ? Icons.refresh : Icons.file_upload_outlined, size: 14),
            onPressed: onUpload,
            label: Text(fileName != null ? 'Change' : 'Scan / Add', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  _SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}

