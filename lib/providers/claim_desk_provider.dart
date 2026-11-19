import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/user_profile.dart';
import '../models/petty_cash_card.dart';
import '../models/expense_claim.dart';
import '../models/ocr_scan_result.dart';
import '../models/approval_stage.dart';
import '../models/card_application.dart';
import '../models/card_refill_request.dart';
import '../models/verified_attachment.dart';

class ClaimDeskProvider extends ChangeNotifier {
  final _uuid = const Uuid();

  // Active User Profile
  late UserProfile _activeUser;
  UserProfile get activeUser => _activeUser;

  // Active Assigned Petty Cash Card
  late PettyCashCard _activeCard;
  PettyCashCard get activeCard => _activeCard;

  // Top-left simulated role switcher
  String _activeRole = 'User / Custodian';
  String get activeRole => _activeRole;

  // Dynamic VAT % (BRD Section 5.7: Stored in config, not hard-coded)
  double _configuredVatPercentage = 15.0;
  double get configuredVatPercentage => _configuredVatPercentage;

  // List of all claims
  final List<ExpenseClaim> _claims = [];
  List<ExpenseClaim> get claims => List.unmodifiable(_claims);

  // Card Application & KYC state (tracked dynamically per user profile id)
  final Map<String, CardApplication> _userApplications = {};
  CardApplication? get activeCardApplication => _userApplications[_activeUser.id];
  bool hasCardApplication(String userId) => _userApplications.containsKey(userId);
  CardApplication? getApplicationForUser(String userId) => _userApplications[userId];

  // Card Refill Requests
  final List<CardRefillRequest> _refillRequests = [];
  List<CardRefillRequest> get refillRequests => List.unmodifiable(_refillRequests);

  // Counters for dashboard
  int get draftsCount =>
      _claims.where((c) => c.status == ClaimStatus.draft).length;
  int get inApprovalCount =>
      _claims.where((c) => c.status == ClaimStatus.submitted).length;
  int get actionNeededCount =>
      _claims.where((c) => c.hasRejectedLines).length;
  int get fullyClosedCount =>
      _claims.where((c) => c.status == ClaimStatus.fullyClosed).length;

  List<ExpenseClaim> get draftClaims =>
      _claims.where((c) => c.status == ClaimStatus.draft).toList();

  List<ExpenseClaim> get rejectedClaims =>
      _claims.where((c) => c.hasRejectedLines).toList();

  ClaimDeskProvider() {
    _activeUser = UserProfile.demoUsers.first;
    _syncUserEnvironment(_activeUser);
  }

  void switchUser(UserProfile user) {
    _activeUser = user;
    _syncUserEnvironment(user);
    notifyListeners();
  }

  void _syncUserEnvironment(UserProfile user) {
    _refillRequests.clear();
    _claims.clear();

    if (user.id == 'USR-001') {
      // Tariq Mansoor: Active Custodian with low balance & claims
      _activeCard = PettyCashCard(
        cardNumber: user.assignedCardNumber,
        cardholderName: user.name,
        employeeId: user.employeeId,
        company: user.company,
        division: user.division,
        department: user.department,
        designation: user.designation,
        costCenter: user.costCenter,
        iqama: user.iqama,
        phone: user.phone,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31),
        monthlyLimit: 5000.0,
        currentBalance: 450.0, // Low balance (< 1000 threshold) to show alert
        spentAmount: 4550.0,
        minimumThreshold: 1000.0,
        singleTransactionCap: 2000.0,
        activeRefillStatus: 'Refill of SAR 5,000 in Finance Review',
      );
      _seedRefillForTariq();
      _seedMockClaims();
    } else if (user.id == 'USR-003') {
      // Majid Al-Dossary: New Employee without pre-seeded application (Ready to Upload Details)
      _activeCard = PettyCashCard(
        cardNumber: 'NOT_APPLIED',
        cardholderName: user.name,
        employeeId: user.employeeId,
        company: user.company,
        division: user.division,
        department: user.department,
        designation: user.designation,
        costCenter: user.costCenter,
        iqama: user.iqama,
        phone: user.phone,
        isInactive: true,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 365)),
        monthlyLimit: 0.0,
        currentBalance: 0.0,
        spentAmount: 0.0,
      );
      // Clean slate: starts with no active application
    } else {
      // Salman Farooq or any other default
      _activeCard = PettyCashCard(
        cardNumber: user.assignedCardNumber,
        cardholderName: user.name,
        employeeId: user.employeeId,
        company: user.company,
        division: user.division,
        department: user.department,
        designation: user.designation,
        costCenter: user.costCenter,
        iqama: user.iqama,
        phone: user.phone,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31),
        monthlyLimit: 7500.0,
        currentBalance: 3200.0,
        spentAmount: 4300.0,
        minimumThreshold: 1000.0,
        singleTransactionCap: 2000.0,
      );
      _seedMockClaims();
    }
  }

  void _seedRefillForTariq() {
    _refillRequests.add(
      CardRefillRequest(
        refillId: 'RFL-2026-0018',
        cardNumber: _activeUser.assignedCardNumber,
        custodianId: _activeUser.employeeId,
        custodianName: _activeUser.name,
        currentBalance: 450.0,
        requestedAmount: 5000.0,
        urgency: RefillUrgency.urgent,
        businessJustification: 'Emergency purchase of high-pressure hydraulic hose & fuel for Jubail heavy generator.',
        status: RefillStatus.requested,
        requestDate: DateTime(2026, 11, 15, 14, 30),
      ),
    );
  }

  void switchRole(String role) {
    _activeRole = role;
    notifyListeners();
  }

  void updateConfiguredVatRate(double newRate) {
    _configuredVatPercentage = newRate;
    notifyListeners();
  }

  void submitCardApplication(CardApplication application) {
    _userApplications[_activeUser.id] = application;
    notifyListeners();
  }

  void deleteCardApplication([String? userId]) {
    final targetId = userId ?? _activeUser.id;
    _userApplications.remove(targetId);
    notifyListeners();
  }

  void requestCardRefill({
    required double requestedAmount,
    required RefillUrgency urgency,
    required String justification,
  }) {
    final request = CardRefillRequest(
      refillId: 'RFL-2026-${_refillRequests.length + 20}',
      cardNumber: _activeCard.cardNumber,
      custodianId: _activeUser.employeeId,
      custodianName: _activeUser.name,
      currentBalance: _activeCard.currentBalance,
      requestedAmount: requestedAmount,
      urgency: urgency,
      businessJustification: justification,
      status: RefillStatus.requested,
      requestDate: DateTime.now(),
    );

    _refillRequests.insert(0, request);
    _activeCard = _activeCard.copyWith(
      activeRefillStatus: 'Refill of SAR ${requestedAmount.toStringAsFixed(0)} in Finance Review',
    );
    notifyListeners();
  }

  void saveClaimAsDraft(ExpenseClaim claim) {
    final index = _claims.indexWhere((c) => c.id == claim.id);
    final updated = claim.copyWith(
      status: ClaimStatus.draft,
      updatedAt: DateTime.now(),
      auditTrail: [
        ...claim.auditTrail,
        'Saved as draft on ${_formatDate(DateTime.now())} by ${_activeUser.name}'
      ],
    );
    if (index >= 0) {
      _claims[index] = updated;
    } else {
      _claims.insert(0, updated);
    }
    notifyListeners();
  }

  void submitClaim(ExpenseClaim claim) {
    final index = _claims.indexWhere((c) => c.id == claim.id);
    final now = DateTime.now();

    final stages = [
      ApprovalWorkflowStage(
        stageOrder: 1,
        roleTitle: 'Reporting Manager Review',
        approverName: 'Rajesh M. Shetty',
        approverDesignation: 'Accounts Manager',
        status: ApprovalStatus.pending,
      ),
      const ApprovalWorkflowStage(
        stageOrder: 2,
        roleTitle: 'Division Head Approval',
        approverName: 'Sivakumar Rajagopal',
        approverDesignation: 'Head IT & Infrastructure',
        status: ApprovalStatus.waiting,
      ),
      const ApprovalWorkflowStage(
        stageOrder: 3,
        roleTitle: 'Section Head - AP',
        approverName: 'Ganesh P. Shetty',
        approverDesignation: 'Section Head - AP & Finance',
        status: ApprovalStatus.waiting,
      ),
      const ApprovalWorkflowStage(
        stageOrder: 4,
        roleTitle: 'SAP Financial Posting',
        approverName: 'Aamir Iqbal',
        approverDesignation: 'Senior Manager SAP & ERP',
        status: ApprovalStatus.waiting,
      ),
    ];

    final updated = claim.copyWith(
      status: ClaimStatus.submitted,
      updatedAt: now,
      approvalStages: stages,
      auditTrail: [
        ...claim.auditTrail,
        'Submitted for multi-level approval on ${_formatDate(now)} by ${_activeUser.name}'
      ],
    );

    if (index >= 0) {
      _claims[index] = updated;
    } else {
      _claims.insert(0, updated);
    }
    notifyListeners();
  }

  // BRD Section 5.4: Resubmit rejected line creating a BRAND-NEW reference number
  ExpenseClaim resubmitRejectedLine({
    required String originalClaimId,
    required String lineId,
    required double updatedBaseAmount,
    required String updatedInvoiceNumber,
    required String? updatedAttachmentName,
  }) {
    final origIndex = _claims.indexWhere((c) => c.id == originalClaimId);
    if (origIndex < 0) throw Exception('Original claim not found');

    final original = _claims[origIndex];
    final lineIndex = original.lines.indexWhere((l) => l.id == lineId);
    if (lineIndex < 0) throw Exception('Line item not found');

    final origLine = original.lines[lineIndex];
    final newVat = (updatedBaseAmount * original.vatRatePercentage) / 100.0;
    final newTotal = updatedBaseAmount + newVat;

    final updatedLine = origLine.copyWith(
      baseAmount: updatedBaseAmount,
      invoiceNumber: updatedInvoiceNumber,
      vatAmount: newVat,
      totalAmount: newTotal,
      attachmentName: updatedAttachmentName ?? origLine.attachmentName,
      status: LineStatus.pending,
      rejectionComment: null,
      isResubmitted: true,
    );

    // Update original claim: mark this line as resubmitted
    final updatedOriginalLines = List<ExpenseLineItem>.from(original.lines);
    updatedOriginalLines[lineIndex] = origLine.copyWith(
      status: LineStatus.pending,
      isResubmitted: true,
    );
    _claims[origIndex] = original.copyWith(
      lines: updatedOriginalLines,
      status: ClaimStatus.submitted,
      auditTrail: [
        ...original.auditTrail,
        'Line #${lineIndex + 1} resubmitted into new reference by ${_activeUser.name} on ${_formatDate(DateTime.now())}'
      ],
    );

    // BRD Section 5.4 CRITICAL RULE: Generate a brand-new Document / Reference Number
    final countR = _claims.where((c) => c.originalRefNumber == original.docRefNumber).length + 1;
    final newRefNumber = '${original.docRefNumber}-R$countR';

    final resubmittedStages = [
      ApprovalWorkflowStage(
        stageOrder: 1,
        roleTitle: 'Reporting Manager Review',
        approverName: 'Rajesh M. Shetty',
        approverDesignation: 'Accounts Manager',
        status: ApprovalStatus.pending,
      ),
      const ApprovalWorkflowStage(
        stageOrder: 2,
        roleTitle: 'Division Head Approval',
        approverName: 'Sivakumar Rajagopal',
        approverDesignation: 'Head IT & Infrastructure',
        status: ApprovalStatus.waiting,
      ),
      const ApprovalWorkflowStage(
        stageOrder: 3,
        roleTitle: 'Section Head - AP',
        approverName: 'Ganesh P. Shetty',
        approverDesignation: 'Section Head - AP & Finance',
        status: ApprovalStatus.waiting,
      ),
      const ApprovalWorkflowStage(
        stageOrder: 4,
        roleTitle: 'SAP Financial Posting',
        approverName: 'Aamir Iqbal',
        approverDesignation: 'Senior Manager SAP & ERP',
        status: ApprovalStatus.waiting,
      ),
    ];

    final newClaim = ExpenseClaim(
      id: _uuid.v4(),
      docRefNumber: newRefNumber,
      docType: original.docType,
      claimDate: DateTime.now(),
      description: 'Resubmission for ${original.docRefNumber} (Line #${lineIndex + 1})',
      employeeId: original.employeeId,
      employeeName: original.employeeName,
      costCenter: original.costCenter,
      cardNumber: original.cardNumber,
      vatRatePercentage: original.vatRatePercentage,
      status: ClaimStatus.submitted,
      lines: [updatedLine],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      originalRefNumber: original.docRefNumber,
      auditTrail: [
        'Created via BRD Section 5.4 Line Resubmission from ${original.docRefNumber}',
        'Prior approver feedback: "${origLine.rejectionComment ?? 'None'}"',
        'Submitted on ${_formatDate(DateTime.now())} by ${_activeUser.name}'
      ],
      approvalStages: resubmittedStages,
    );

    _claims.insert(0, newClaim);
    notifyListeners();
    return newClaim;
  }

  Future<OcrScanResult> simulateOcrScan() async {
    await Future.delayed(const Duration(milliseconds: 1400));
    final base = 350.0;
    final vat = (base * _configuredVatPercentage) / 100.0;
    return OcrScanResult(
      merchantName: 'Saudi Aramco Fuel Service #402',
      invoiceNumber: 'INV-SA-${DateTime.now().microsecond % 8000 + 1000}',
      invoiceDate: DateTime.now(),
      baseAmount: base,
      vatAmount: vat,
      totalAmount: base + vat,
      category: 'Fuel & Fleet',
      confidenceScore: 0.98,
      isHighConfidence: true,
      sampleReceiptImage: 'receipt_aramco_zatca_tax.pdf',
    );
  }

  /// Enterprise Approver Ping / Reminder
  void pingApprover(String claimId, int stageOrder) {
    final idx = _claims.indexWhere((c) => c.id == claimId || c.docRefNumber == claimId);
    if (idx != -1) {
      final claim = _claims[idx];
      final now = DateTime.now();
      final updatedStages = claim.approvalStages.map((st) {
        if (st.stageOrder == stageOrder) {
          return st.copyWith(canPing: false);
        }
        return st;
      }).toList();
      final updatedLogs = [
        '⚡ Reminder ping dispatched to Stage $stageOrder approver at ${_formatDate(now)} by ${_activeUser.name}',
        ...claim.systemLogs,
      ];
      _claims[idx] = claim.copyWith(
        approvalStages: updatedStages,
        systemLogs: updatedLogs,
      );
      notifyListeners();
    }
  }

  /// Request Claim Recall or Adjustment
  void recallClaim(String claimId) {
    final idx = _claims.indexWhere((c) => c.id == claimId || c.docRefNumber == claimId);
    if (idx != -1) {
      final claim = _claims[idx];
      final now = DateTime.now();
      final updatedLogs = [
        '🔒 Claim recall requested by ${_activeUser.name} on ${_formatDate(now)}. Routing halted for edit.',
        ...claim.systemLogs,
      ];
      _claims[idx] = claim.copyWith(
        status: ClaimStatus.draft,
        systemLogs: updatedLogs,
        isRecallable: false,
      );
      notifyListeners();
    }
  }

  /// Dispatch communication note to approver
  void sendApproverMessage(String claimId, String message) {
    final idx = _claims.indexWhere((c) => c.id == claimId || c.docRefNumber == claimId);
    if (idx != -1) {
      final claim = _claims[idx];
      final now = DateTime.now();
      final updatedLogs = [
        '💬 Message sent to approver by ${_activeUser.name}: "$message" (${_formatDate(now)})',
        ...claim.systemLogs,
      ];
      _claims[idx] = claim.copyWith(systemLogs: updatedLogs);
      notifyListeners();
    }
  }

  void _seedMockClaims() {
    final now = DateTime.now();

    // 0. FEATURED AUDIT LEDGER CLAIM (#CLM-1021 - Matches corporate ledger spec)
    _claims.add(
      ExpenseClaim(
        id: 'CLM-1021',
        docRefNumber: '#CLM-1021',
        docType: 'Travel & Lodging',
        claimDate: DateTime(2026, 10, 28, 20, 45),
        description: 'Riyadh Marriott Hotel - Client Workshop',
        employeeId: _activeUser.employeeId,
        employeeName: _activeUser.name,
        costCenter: 'CC-402 (EP Ops - Petro...)',
        cardNumber: '**** 8492',
        projectCode: 'SR-1010 (Sadara Complex Jubail)',
        glAccountCode: '6250 - LODGING - CORP',
        preFundedAuth: true,
        isZatcaVerified: true,
        vatRatePercentage: 15.0,
        status: ClaimStatus.submitted,
        createdAt: DateTime(2026, 10, 28, 20, 45),
        updatedAt: DateTime(2026, 10, 29, 14, 30),
        lines: [
          ExpenseLineItem(
            id: 'LIN-1021',
            date: DateTime(2026, 10, 28, 20, 45),
            category: 'Travel & Lodging',
            invoiceNumber: 'MAR-99021',
            baseAmount: 3200.0,
            vatRatePercentage: 15.0,
            vatAmount: 480.0,
            totalAmount: 3680.0,
            attachmentName: 'Marriott_Folio_INV902.pdf',
            status: LineStatus.pending,
          ),
        ],
        auditTrail: [
          'Submitted on Oct 28, 2026 • 08:45 PM by Tariq Mansoor',
          'Accountant validation completed by Sara Al-Otaibi on Oct 29, 2026',
          'Division Manager sign-off completed by Eng. Khalid Mansoor on Oct 29, 2026',
          'Currently in Stage 3: Procurement Lead review',
        ],
        approvalStages: [
          ApprovalWorkflowStage(
            stageOrder: 1,
            roleTitle: 'Accountant',
            approverName: 'Sara Al-Otaibi',
            approverDesignation: 'Senior Financial Auditor (Jubail Hub)',
            status: ApprovalStatus.approved,
            badgeLabel: 'ACCT VALIDATED',
            timestamp: DateTime(2026, 10, 29, 10, 14),
            comments: 'All receipts verified against card terminal auth SAR 3,680.00. Tax ID matches ZATCA registry.',
          ),
          ApprovalWorkflowStage(
            stageOrder: 2,
            roleTitle: 'Division Manager',
            approverName: 'Eng. Khalid Mansoor',
            approverDesignation: 'VP Operations Jubail Complexes',
            status: ApprovalStatus.approved,
            badgeLabel: 'DIV MGR SIGN-OFF',
            timestamp: DateTime(2026, 10, 29, 14, 30),
            comments: 'Approved under Client Workshop Budget FY26-Q4. Valid business case.',
          ),
          const ApprovalWorkflowStage(
            stageOrder: 3,
            roleTitle: 'Procurement Lead',
            approverName: 'Fahad Al-Zahrani',
            approverDesignation: 'Strategic Sourcing & Procurement Lead',
            status: ApprovalStatus.pending,
            badgeLabel: 'IN REVIEW',
            remainingSlaHours: 4,
            canPing: true,
            comments: 'Under policy price cap verification for corporate hospitality tiers.',
          ),
          const ApprovalWorkflowStage(
            stageOrder: 4,
            roleTitle: 'Finance Manager',
            approverName: 'Dr. Tariq Al-Ghamdi',
            approverDesignation: 'CFO Delegate / Treasury Release',
            status: ApprovalStatus.waiting,
            badgeLabel: 'PENDING',
            upstreamDependency: 'Upstream Stage',
            comments: 'Awaiting Level 3 Procurement endorsement prior to final corporate card credit replenishment.',
          ),
        ],
        verifiedAttachments: const [
          VerifiedAttachment(
            id: 'ATT-1021-01',
            fileName: 'Marriott_Folio_INV902.pdf',
            fileType: 'Tax Invoice',
            badgeText: 'ZATCA OK',
            badgeColor: Color(0xFF059669),
            summary: 'ZATCA QR Scanned • 1.4 MB • Cryptographic Match',
            size: '1.4 MB',
          ),
          VerifiedAttachment(
            id: 'ATT-1021-02',
            fileName: 'POS_Terminal_Slip_A8492.pdf',
            fileType: 'Terminal Slip',
            badgeText: 'AUTH 8492',
            badgeColor: Color(0xFF2563EB),
            summary: 'Merchant Terminal Copy • SAR 3,680.00 Auth',
            size: '320 KB',
          ),
          VerifiedAttachment(
            id: 'ATT-1021-03',
            fileName: 'Workshop_Attendance_Roster.pdf',
            fileType: 'Attendee Roster',
            badgeText: 'ROSTER',
            badgeColor: Color(0xFF475569),
            summary: 'Signed by 14 PetroKemya Delegates • 840 KB',
            size: '840 KB',
          ),
        ],
        systemLogs: const [
          'OCR Ingestion: 11 items recognized with 99.4% ZATCA cryptographic validation rate.',
          'Policy Validation: Auto-matched to Travel Lodging Matrix Jubail Complex FY26.',
        ],
      ),
    );

    // 1. DRAFT CLAIM (This week - WTD)
    _claims.add(
      ExpenseClaim(
        id: 'CLM-001',
        docRefNumber: 'EXP-2026-0044',
        docType: 'Petty Cash Reimbursement',
        claimDate: now.subtract(const Duration(days: 1)),
        description: 'Dammam Workshop Urgent Consumables & Fasteners',
        employeeId: _activeUser.employeeId,
        employeeName: _activeUser.name,
        costCenter: _activeUser.costCenter,
        cardNumber: _activeUser.assignedCardNumber,
        vatRatePercentage: 15.0,
        status: ClaimStatus.draft,
        lines: [
          ExpenseLineItem(
            id: 'LIN-01',
            date: now.subtract(const Duration(days: 1)),
            category: 'Hardware & Tools',
            invoiceNumber: 'INV-SACO-9912',
            baseAmount: 480.0,
            vatRatePercentage: 15.0,
            vatAmount: 72.0,
            totalAmount: 552.0,
            attachmentName: 'saco_tax_invoice.pdf',
            status: LineStatus.pending,
          ),
          ExpenseLineItem(
            id: 'LIN-02',
            date: now.subtract(const Duration(days: 1)),
            category: 'Safety Consumables',
            invoiceNumber: 'INV-SAFETY-4421',
            baseAmount: 260.0,
            vatRatePercentage: 15.0,
            vatAmount: 39.0,
            totalAmount: 299.0,
            attachmentName: 'gloves_masks_vat.pdf',
            status: LineStatus.pending,
          ),
        ],
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
        auditTrail: [
          'Created as draft on ${_formatDate(now.subtract(const Duration(days: 1)))} by ${_activeUser.name}',
          'VAT rate 15.0% dynamically applied from app configuration (BRD 5.7)',
        ],
      ),
    );

    // 2. SUBMITTED CLAIM (This week - WTD) with 4-level approval pipeline
    _claims.add(
      ExpenseClaim(
        id: 'CLM-002',
        docRefNumber: 'EXP-2026-0043',
        docType: 'Local Travel & Fuel Claim',
        claimDate: now.subtract(const Duration(days: 2)),
        description: 'Ras Tanura Pipeline Fleet Fuel & Site Refreshments',
        employeeId: _activeUser.employeeId,
        employeeName: _activeUser.name,
        costCenter: _activeUser.costCenter,
        cardNumber: _activeUser.assignedCardNumber,
        vatRatePercentage: 15.0,
        status: ClaimStatus.submitted,
        lines: [
          ExpenseLineItem(
            id: 'LIN-03',
            date: now.subtract(const Duration(days: 2)),
            category: 'Fuel & Fleet',
            invoiceNumber: 'NAFT-99214',
            baseAmount: 620.0,
            vatRatePercentage: 15.0,
            vatAmount: 93.0,
            totalAmount: 713.0,
            attachmentName: 'naft_diesel_zatca.pdf',
            status: LineStatus.pending,
          ),
        ],
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 1)),
        auditTrail: [
          'Submitted on ${_formatDate(now.subtract(const Duration(days: 2)))} by ${_activeUser.name}',
          'Level 1 approved by Rajesh M. Shetty on ${_formatDate(now.subtract(const Duration(days: 1)))}',
          'Awaiting Level 2 approval by Sivakumar Rajagopal',
        ],
        approvalStages: [
          ApprovalWorkflowStage(
            stageOrder: 1,
            roleTitle: 'Reporting Manager Review',
            approverName: 'Rajesh M. Shetty',
            approverDesignation: 'Accounts Manager',
            status: ApprovalStatus.approved,
            timestamp: now.subtract(const Duration(days: 1)),
            comments: 'Approved fleet fuel logs verified against GPS tracker.',
          ),
          ApprovalWorkflowStage(
            stageOrder: 2,
            roleTitle: 'Division Head Approval',
            approverName: 'Sivakumar Rajagopal',
            approverDesignation: 'Head IT & Infrastructure',
            status: ApprovalStatus.pending,
          ),
          const ApprovalWorkflowStage(
            stageOrder: 3,
            roleTitle: 'Section Head - AP',
            approverName: 'Ganesh P. Shetty',
            approverDesignation: 'Section Head - AP & Finance',
            status: ApprovalStatus.waiting,
          ),
          const ApprovalWorkflowStage(
            stageOrder: 4,
            roleTitle: 'SAP Financial Posting',
            approverName: 'Aamir Iqbal',
            approverDesignation: 'Senior Manager SAP & ERP',
            status: ApprovalStatus.waiting,
          ),
        ],
      ),
    );

    // 3. ACTION NEEDED CLAIM (Earlier this month - MTD) with a REJECTED LINE
    _claims.add(
      ExpenseClaim(
        id: 'CLM-003',
        docRefNumber: 'EXP-2026-0040',
        docType: 'Urgent Equipment Maintenance',
        claimDate: now.subtract(const Duration(days: 6)),
        description: 'Jubail Heavy Generator Emergency Spare Parts',
        employeeId: _activeUser.employeeId,
        employeeName: _activeUser.name,
        costCenter: _activeUser.costCenter,
        cardNumber: _activeUser.assignedCardNumber,
        vatRatePercentage: 15.0,
        status: ClaimStatus.partiallyRejected,
        lines: [
          ExpenseLineItem(
            id: 'LIN-04',
            date: now.subtract(const Duration(days: 6)),
            category: 'Maintenance & Parts',
            invoiceNumber: 'INV-JUB-7781',
            baseAmount: 1450.0,
            vatRatePercentage: 15.0,
            vatAmount: 217.5,
            totalAmount: 1667.5,
            attachmentName: 'engine_filter_receipt.pdf',
            status: LineStatus.approved,
          ),
          ExpenseLineItem(
            id: 'LIN-05',
            date: now.subtract(const Duration(days: 6)),
            category: 'Courier & Freight',
            invoiceNumber: 'INV-DHL-3392',
            baseAmount: 380.0,
            vatRatePercentage: 15.0,
            vatAmount: 57.0,
            totalAmount: 437.0,
            attachmentName: 'dhl_blurry_scan.png',
            status: LineStatus.rejected,
            rejectionComment: 'Receipt amount does not match invoice total. Tax breakdown missing. Please re-check and upload clearer copy.',
          ),
        ],
        createdAt: now.subtract(const Duration(days: 6)),
        updatedAt: now.subtract(const Duration(days: 4)),
        auditTrail: [
          'Submitted on ${_formatDate(now.subtract(const Duration(days: 6)))}',
          'Line #1 Approved by Rajesh M. Shetty',
          'Line #2 Rejected by Sivakumar Rajagopal: "Receipt amount does not match invoice total. Tax breakdown missing."',
          'Awaiting resubmission under BRD Section 5.4 rule'
        ],
        approvalStages: [
          ApprovalWorkflowStage(
            stageOrder: 1,
            roleTitle: 'Reporting Manager Review',
            approverName: 'Rajesh M. Shetty',
            approverDesignation: 'Accounts Manager',
            status: ApprovalStatus.approved,
            timestamp: now.subtract(const Duration(days: 5)),
          ),
          ApprovalWorkflowStage(
            stageOrder: 2,
            roleTitle: 'Division Head Approval',
            approverName: 'Sivakumar Rajagopal',
            approverDesignation: 'Head IT & Infrastructure',
            status: ApprovalStatus.rejected,
            timestamp: now.subtract(const Duration(days: 4)),
            comments: 'Line #2 Courier receipt is unreadable. Please upload a clear copy.',
          ),
          const ApprovalWorkflowStage(
            stageOrder: 3,
            roleTitle: 'Section Head - AP',
            approverName: 'Ganesh P. Shetty',
            approverDesignation: 'Section Head - AP & Finance',
            status: ApprovalStatus.waiting,
          ),
          const ApprovalWorkflowStage(
            stageOrder: 4,
            roleTitle: 'SAP Financial Posting',
            approverName: 'Aamir Iqbal',
            approverDesignation: 'Senior Manager SAP & ERP',
            status: ApprovalStatus.waiting,
          ),
        ],
      ),
    );

    // 4. FULLY CLOSED CLAIM (Earlier this year - YTD) with full SAP reference and all 4 stages approved in GREEN
    _claims.add(
      ExpenseClaim(
        id: 'CLM-004',
        docRefNumber: 'EXP-2026-0012',
        docType: 'Petty Cash Reimbursement',
        claimDate: DateTime(2026, 2, 10),
        description: 'First Aid Restock & Site Safety Boots',
        employeeId: _activeUser.employeeId,
        employeeName: _activeUser.name,
        costCenter: _activeUser.costCenter,
        cardNumber: _activeUser.assignedCardNumber,
        vatRatePercentage: 15.0,
        status: ClaimStatus.fullyClosed,
        paymentStatus: 'Paid',
        paymentNumber: 'PAY-2026-8819',
        sapDocRefNumber: 'SAP-19000452',
        lines: [
          ExpenseLineItem(
            id: 'LIN-06',
            date: DateTime(2026, 2, 10),
            category: 'Safety Consumables',
            invoiceNumber: 'REDCRESCENT-1044',
            baseAmount: 1800.0,
            vatRatePercentage: 15.0,
            vatAmount: 270.0,
            totalAmount: 2070.0,
            attachmentName: 'first_aid_meds.pdf',
            status: LineStatus.approved,
          ),
        ],
        createdAt: DateTime(2026, 2, 10),
        updatedAt: DateTime(2026, 2, 15),
        auditTrail: [
          'Submitted on 10/02/2026 by ${_activeUser.name}',
          'Level 1 Manager Approved by Rajesh M. Shetty on 11/02/2026',
          'Level 2 Division Head Approved by Sivakumar Rajagopal on 12/02/2026',
          'Level 3 AP Financial Audit Completed by Ganesh P. Shetty on 14/02/2026',
          'BRD Section 5.6 Financial Updates: Payment Status Paid, Payment # PAY-2026-8819, SAP Ref # SAP-19000452',
          'Status set to Fully Closed (no further edits allowed) on 15/02/2026 by Aamir Iqbal'
        ],
        approvalStages: [
          ApprovalWorkflowStage(
            stageOrder: 1,
            roleTitle: 'Reporting Manager Review',
            approverName: 'Rajesh M. Shetty',
            approverDesignation: 'Accounts Manager',
            status: ApprovalStatus.approved,
            timestamp: DateTime(2026, 2, 11, 9, 30),
          ),
          ApprovalWorkflowStage(
            stageOrder: 2,
            roleTitle: 'Division Head Approval',
            approverName: 'Sivakumar Rajagopal',
            approverDesignation: 'Head IT & Infrastructure',
            status: ApprovalStatus.approved,
            timestamp: DateTime(2026, 2, 12, 14, 15),
          ),
          ApprovalWorkflowStage(
            stageOrder: 3,
            roleTitle: 'Section Head - AP',
            approverName: 'Ganesh P. Shetty',
            approverDesignation: 'Section Head - AP & Finance',
            status: ApprovalStatus.approved,
            timestamp: DateTime(2026, 2, 14, 11, 0),
          ),
          ApprovalWorkflowStage(
            stageOrder: 4,
            roleTitle: 'SAP Financial Posting',
            approverName: 'Aamir Iqbal',
            approverDesignation: 'Senior Manager SAP & ERP',
            status: ApprovalStatus.approved,
            timestamp: DateTime(2026, 2, 15, 16, 45),
            comments: 'SAP doc posted: SAP-19000452',
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
