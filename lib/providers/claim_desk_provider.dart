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
import '../models/card_statement.dart';

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

  // Imported Card Statement Transactions, Cash Advances & Sub-Custodians (BRD V2)
  final List<CardStatementTransaction> _statementTransactions = [];
  List<CardStatementTransaction> get statementTransactions =>
      List.unmodifiable(_statementTransactions);

  final List<CashAdvanceLedger> _cashAdvances = [];
  List<CashAdvanceLedger> get cashAdvances => List.unmodifiable(_cashAdvances);

  final List<SubCustodian> _subCustodians = [];
  List<SubCustodian> get subCustodians => List.unmodifiable(_subCustodians);

  CashAdvanceLedger? get activeUserCashAdvance {
    try {
      return _cashAdvances.firstWhere((a) => a.employeeId == _activeUser.employeeId);
    } catch (_) {
      return null;
    }
  }

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
    _statementTransactions.clear();
    _cashAdvances.clear();
    _subCustodians.clear();

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
        currentBalance: 450.0,
        spentAmount: 4550.0,
        minimumThreshold: 1000.0,
        singleTransactionCap: 2000.0,
        activeRefillStatus: 'Refill of SAR 5,000 in Finance Review',
      );
      _seedStatementAndAdvances(user, initialDeposit: 5000.0);
      _seedRefillForTariq();
      _seedMockClaims();
      _syncCardBalanceWithReconciliation();
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
        currentBalance: 2950.0,
        spentAmount: 4550.0,
        minimumThreshold: 1000.0,
        singleTransactionCap: 2000.0,
      );
      _seedStatementAndAdvances(user, initialDeposit: 7500.0);
      _seedMockClaims();
      _syncCardBalanceWithReconciliation();
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
    _syncCardBalanceWithReconciliation();
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
    _syncCardBalanceWithReconciliation();
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
        docType: 'Client & Site Hospitality',
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
            baseAmount: 1000.0,
            vatRatePercentage: 15.0,
            vatAmount: 150.0,
            totalAmount: 1150.0,
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
            comments: 'All receipts verified against card terminal auth SAR 1,150.00. Tax ID matches ZATCA registry.',
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
            summary: 'Merchant Terminal Copy • SAR 1,150.00 Auth',
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
        docType: 'Site Operations & Consumables',
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
            baseAmount: 200.0,
            vatRatePercentage: 15.0,
            vatAmount: 30.0,
            totalAmount: 230.0,
            attachmentName: 'saco_tax_invoice.pdf',
            status: LineStatus.pending,
            paymentSource: PaymentSource.cashAdvance,
          ),
          ExpenseLineItem(
            id: 'LIN-02',
            date: now.subtract(const Duration(days: 1)),
            category: 'Safety Consumables',
            invoiceNumber: 'INV-SAFETY-4421',
            baseAmount: 100.0,
            vatRatePercentage: 15.0,
            vatAmount: 15.0,
            totalAmount: 115.0,
            attachmentName: 'gloves_masks_vat.pdf',
            status: LineStatus.pending,
            paymentSource: PaymentSource.cashAdvance,
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
            baseAmount: 300.0,
            vatRatePercentage: 15.0,
            vatAmount: 45.0,
            totalAmount: 345.0,
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
        docType: 'Equipment Maintenance & Repairs',
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
            baseAmount: 400.0,
            vatRatePercentage: 15.0,
            vatAmount: 60.0,
            totalAmount: 460.0,
            attachmentName: 'engine_filter_receipt.pdf',
            status: LineStatus.approved,
          ),
          ExpenseLineItem(
            id: 'LIN-05',
            date: now.subtract(const Duration(days: 6)),
            category: 'Courier & Freight',
            invoiceNumber: 'INV-DHL-3392',
            baseAmount: 100.0,
            vatRatePercentage: 15.0,
            vatAmount: 15.0,
            totalAmount: 115.0,
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
        docType: 'Site Operations & Consumables',
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
            baseAmount: 1043.48,
            vatRatePercentage: 15.0,
            vatAmount: 156.52,
            totalAmount: 1200.0,
            attachmentName: 'first_aid_meds.pdf',
            status: LineStatus.approved,
            paymentSource: PaymentSource.cardSwipe,
          ),
          ExpenseLineItem(
            id: 'LIN-07',
            date: DateTime(2026, 2, 12),
            category: 'Site Hospitality & Meals',
            invoiceNumber: 'CASH-SITE-2091',
            baseAmount: 347.83,
            vatRatePercentage: 15.0,
            vatAmount: 52.17,
            totalAmount: 400.0,
            attachmentName: 'site_cash_voucher.pdf',
            status: LineStatus.approved,
            paymentSource: PaymentSource.cashAdvance,
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

  // --- BRD V2 Phase 1: Statement Import, Cash Advance, Duplicate Validation & Reconciliation ---

  void _syncCardBalanceWithReconciliation() {
    if (!_activeUser.hasActiveCard) return;
    final balance = reconciledCardBalance;
    final totalFunding = _activeCard.monthlyLimit + enhancementDepositAmount;
    final spent = (totalFunding - balance).clamp(0.0, double.infinity);
    _activeCard = _activeCard.copyWith(
      currentBalance: double.parse(balance.toStringAsFixed(2)),
      spentAmount: double.parse(spent.toStringAsFixed(2)),
    );
  }

  void _seedStatementAndAdvances(UserProfile user, {double initialDeposit = 5000.0}) {
    final cardNum = user.assignedCardNumber;
    _statementTransactions.addAll([
      CardStatementTransaction(
        id: 'STX-001',
        cardNumber: cardNum,
        companyCode: 'COMP-1000',
        date: DateTime(2026, 2, 1),
        merchantOrAtm: 'Treasury Opening Deposit',
        description: 'Initial Petty Cash Card Funding',
        amount: initialDeposit,
        type: StatementTxType.deposit,
        employeeId: user.employeeId,
        isSubmitted: true,
      ),
      CardStatementTransaction(
        id: 'STX-002',
        cardNumber: cardNum,
        companyCode: 'COMP-1000',
        date: DateTime(2026, 2, 10),
        merchantOrAtm: 'Al Rajhi ATM - Dammam Hub',
        description: 'ATM Cash Withdrawal for Site Petty Cash',
        amount: 1000.00,
        type: StatementTxType.atmWithdrawal,
        employeeId: user.employeeId,
        isSubmitted: true,
      ),
      CardStatementTransaction(
        id: 'STX-003',
        cardNumber: cardNum,
        companyCode: 'COMP-1000',
        date: DateTime(2026, 2, 14),
        merchantOrAtm: 'Sasco Fuel Station #402',
        description: 'POS Swipe — Unsubmitted Fuel Receipt',
        amount: 180.00,
        type: StatementTxType.posSwipe,
        employeeId: user.employeeId,
        isSubmitted: false,
      ),
      CardStatementTransaction(
        id: 'STX-004',
        cardNumber: cardNum,
        companyCode: 'COMP-1000',
        date: DateTime(2026, 2, 16),
        merchantOrAtm: 'Jarir Bookstore Online',
        description: 'Online Card Purchase — Site Stationery',
        amount: 100.00,
        type: StatementTxType.online,
        employeeId: user.employeeId,
        isSubmitted: false,
      ),
    ]);

    _cashAdvances.add(
      CashAdvanceLedger(
        id: 'ADV-001',
        employeeId: user.employeeId,
        employeeName: user.name,
        parentCardNumber: cardNum,
        totalWithdrawn: 1000.00,
        totalDeducted: 400.00,
        entries: [
          CashAdvanceEntry(
            id: 'ADVE-1',
            date: DateTime(2026, 2, 10),
            description: 'ATM Withdrawal (Al Rajhi ATM - Dammam Hub)',
            amount: 1000.00,
            isWithdrawal: true,
          ),
          CashAdvanceEntry(
            id: 'ADVE-2',
            date: DateTime(2026, 2, 12),
            description: 'Approved Cash Expense Reconciled',
            amount: 400.00,
            isWithdrawal: false,
          ),
        ],
      ),
    );
  }

  /// Imports parsed card statement rows:
  /// - ATM withdrawals automatically create/credit Employee Cash Advance
  /// - POS/Online transactions are added as unsubmitted transactions ready for draft claim creation
  int importCardStatement(List<CardStatementTransaction> incoming) {
    int importedCount = 0;
    for (final tx in incoming) {
      if (_statementTransactions.any((e) => e.id == tx.id)) continue;
      _statementTransactions.insert(0, tx);
      importedCount++;

      if (tx.type == StatementTxType.atmWithdrawal) {
        _creditCashAdvance(
          employeeId: tx.employeeId,
          employeeName: _resolveEmployeeName(tx.employeeId),
          cardNumber: tx.cardNumber,
          amount: tx.amount,
          date: tx.date,
          description: 'ATM Withdrawal (${tx.merchantOrAtm})',
        );
      }
    }
    if (importedCount > 0) {
      _syncCardBalanceWithReconciliation();
      notifyListeners();
    }
    return importedCount;
  }

  void _creditCashAdvance({
    required String employeeId,
    required String employeeName,
    required String cardNumber,
    required double amount,
    required DateTime date,
    required String description,
  }) {
    final idx = _cashAdvances.indexWhere((a) => a.employeeId == employeeId);
    final entry = CashAdvanceEntry(
      id: _uuid.v4(),
      date: date,
      description: description,
      amount: amount,
      isWithdrawal: true,
    );

    if (idx != -1) {
      final existing = _cashAdvances[idx];
      _cashAdvances[idx] = existing.copyWith(
        totalWithdrawn: existing.totalWithdrawn + amount,
        entries: [entry, ...existing.entries],
      );
    } else {
      _cashAdvances.add(
        CashAdvanceLedger(
          id: _uuid.v4(),
          employeeId: employeeId,
          employeeName: employeeName,
          parentCardNumber: cardNumber,
          totalWithdrawn: amount,
          totalDeducted: 0.0,
          entries: [entry],
        ),
      );
    }
  }

  void deductCashAdvance({
    required String employeeId,
    required double amount,
    required String claimRef,
  }) {
    final idx = _cashAdvances.indexWhere((a) => a.employeeId == employeeId);
    if (idx == -1 || amount <= 0) return;
    final existing = _cashAdvances[idx];
    final entry = CashAdvanceEntry(
      id: _uuid.v4(),
      date: DateTime.now(),
      description: 'Reconciled against approved claim $claimRef',
      amount: amount,
      isWithdrawal: false,
    );
    _cashAdvances[idx] = existing.copyWith(
      totalDeducted: existing.totalDeducted + amount,
      entries: [entry, ...existing.entries],
    );
    notifyListeners();
  }

  /// Creates a Draft ExpenseClaim directly from an unsubmitted POS/Online statement transaction
  ExpenseClaim createDraftFromStatementTx(CardStatementTransaction tx) {
    final vatRate = _configuredVatPercentage;
    final base = double.parse((tx.amount / (1.0 + vatRate / 100.0)).toStringAsFixed(2));
    final vat = double.parse((tx.amount - base).toStringAsFixed(2));
    final lineId = _uuid.v4();

    final draft = ExpenseClaim(
      id: _uuid.v4(),
      docRefNumber: 'EXP-2026-${(100 + DateTime.now().microsecond % 900)}',
      docType: 'Site Operations & Consumables',
      claimDate: tx.date,
      description: '${tx.merchantOrAtm} — ${tx.description}',
      employeeId: _activeUser.employeeId,
      employeeName: _activeUser.name,
      costCenter: _activeUser.costCenter,
      cardNumber: _activeCard.cardNumber,
      vatRatePercentage: vatRate,
      status: ClaimStatus.draft,
      lines: [
        ExpenseLineItem(
          id: lineId,
          date: tx.date,
          category: 'Fuel & Fleet',
          invoiceNumber: tx.id,
          baseAmount: base,
          vatRatePercentage: vatRate,
          vatAmount: vat,
          totalAmount: tx.amount,
          paymentSource: PaymentSource.cardSwipe,
          statementTxId: tx.id,
        ),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      auditTrail: [
        'Draft auto-created from imported statement transaction ${tx.id} by ${_activeUser.name}'
      ],
    );

    _claims.insert(0, draft);
    final txIdx = _statementTransactions.indexWhere((t) => t.id == tx.id);
    if (txIdx != -1) {
      _statementTransactions[txIdx] = _statementTransactions[txIdx].copyWith(
        isSubmitted: true,
        linkedClaimLineId: lineId,
      );
    }
    notifyListeners();
    return draft;
  }

  void addSubCustodian({
    required String name,
    required String employeeId,
    required String costCenter,
  }) {
    final cleanId = employeeId.trim();
    if (_subCustodians.any((s) => s.employeeId.toLowerCase() == cleanId.toLowerCase())) {
      return;
    }
    _subCustodians.add(
      SubCustodian(
        id: _uuid.v4(),
        name: name.trim(),
        employeeId: cleanId,
        parentCardNumber: _activeCard.cardNumber,
        costCenter: costCenter.trim().isEmpty ? _activeUser.costCenter : costCenter.trim(),
      ),
    );
    notifyListeners();
  }

  String _resolveEmployeeName(String employeeId) {
    if (employeeId == _activeUser.employeeId) return _activeUser.name;
    try {
      return _subCustodians.firstWhere((s) => s.employeeId == employeeId).name;
    } catch (_) {
      return employeeId;
    }
  }

  /// BRD Section 3: Duplicate Invoice Validation across existing non-draft claims
  bool isDuplicateInvoice(String invoiceNumber, {String? excludeClaimId}) {
    final normalized = invoiceNumber.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    for (final claim in _claims) {
      if (claim.id == excludeClaimId) continue;
      if (claim.status == ClaimStatus.draft) continue;
      for (final line in claim.lines) {
        if (line.invoiceNumber.trim().toLowerCase() == normalized) {
          return true;
        }
      }
    }
    return false;
  }

  // --- Reconciliation Overview Calculations (BRD V2 Screenshot Sections A–F) ---

  double get initialDepositAmount => _statementTransactions
      .where((t) => t.type == StatementTxType.deposit)
      .fold(0.0, (s, t) => s + t.amount);

  double get enhancementDepositAmount => _refillRequests
      .where((r) => r.status == RefillStatus.fundsLoaded)
      .fold(0.0, (s, r) => s + r.requestedAmount);

  double get approvedSwipeTotal => _claims
      .where((c) => c.status == ClaimStatus.approved || c.status == ClaimStatus.fullyClosed)
      .expand((c) => c.lines)
      .where((l) => l.paymentSource == PaymentSource.cardSwipe)
      .fold(0.0, (s, l) => s + l.totalAmount);

  double get approvedCashTotal => _claims
      .where((c) => c.status == ClaimStatus.approved || c.status == ClaimStatus.fullyClosed)
      .expand((c) => c.lines)
      .where((l) => l.paymentSource == PaymentSource.cashAdvance)
      .fold(0.0, (s, l) => s + l.totalAmount);

  double get approvedTotal => approvedSwipeTotal + approvedCashTotal;

  double get inApprovalSwipeTotal => _claims
      .where((c) => c.status == ClaimStatus.submitted || c.status == ClaimStatus.partiallyRejected)
      .expand((c) => c.lines)
      .where((l) => l.paymentSource == PaymentSource.cardSwipe)
      .fold(0.0, (s, l) => s + l.totalAmount);

  double get inApprovalCashTotal => _claims
      .where((c) => c.status == ClaimStatus.submitted || c.status == ClaimStatus.partiallyRejected)
      .expand((c) => c.lines)
      .where((l) => l.paymentSource == PaymentSource.cashAdvance)
      .fold(0.0, (s, l) => s + l.totalAmount);

  double get inApprovalTotal => inApprovalSwipeTotal + inApprovalCashTotal;

  double get notSubmittedSwipeTotal => _statementTransactions
      .where((t) =>
          (t.type == StatementTxType.posSwipe || t.type == StatementTxType.online) &&
          !t.isSubmitted)
      .fold(0.0, (s, t) => s + t.amount);

  double get notSubmittedCashTotal => _claims
      .where((c) => c.status == ClaimStatus.draft)
      .expand((c) => c.lines)
      .where((l) => l.paymentSource == PaymentSource.cashAdvance)
      .fold(0.0, (s, l) => s + l.totalAmount);

  double get notSubmittedTotal => notSubmittedSwipeTotal + notSubmittedCashTotal;

  double get employeeAdvanceTotal =>
      _cashAdvances.fold(0.0, (s, a) => s + a.totalWithdrawn);

  double get employeeReimbursementTotal => approvedTotal + inApprovalTotal;

  double get employeeCashInHandTotal =>
      _cashAdvances.fold(0.0, (s, a) => s + a.remainingBalance);

  double get reconciledCardBalance =>
      (initialDepositAmount + enhancementDepositAmount) -
      (approvedSwipeTotal + inApprovalSwipeTotal + notSubmittedSwipeTotal + employeeAdvanceTotal);

  // --- BRD V2 Phase 2: Line-Level Approval/Rejection, SAP Posting & Refill Disbursement ---

  List<ExpenseClaim> get pendingApprovalClaims => _claims
      .where((c) => c.status == ClaimStatus.submitted || c.status == ClaimStatus.partiallyRejected)
      .toList();

  List<ExpenseClaim> get approvedPendingSapClaims =>
      _claims.where((c) => c.status == ClaimStatus.approved).toList();

  List<ExpenseClaim> get fullyClosedClaims =>
      _claims.where((c) => c.status == ClaimStatus.fullyClosed).toList();

  /// Approves a single line item and advances the claim's approval stage if all lines are approved.
  void approveClaimLine(String claimId, String lineId) {
    final idx = _claims.indexWhere((c) => c.id == claimId);
    if (idx < 0) return;
    final claim = _claims[idx];
    if (claim.status == ClaimStatus.fullyClosed) return;

    final updatedLines = claim.lines.map((l) {
      if (l.id == lineId) {
        return l.copyWith(status: LineStatus.approved, rejectionComment: null);
      }
      return l;
    }).toList();

    final allApproved = updatedLines.every((l) => l.status == LineStatus.approved);
    var updatedClaim = claim.copyWith(
      lines: updatedLines,
      updatedAt: DateTime.now(),
      auditTrail: [
        ...claim.auditTrail,
        'Line approved on ${_formatDate(DateTime.now())} by $_activeRole',
      ],
    );

    if (allApproved) {
      updatedClaim = _advanceClaimStage(updatedClaim);
    }

    _claims[idx] = updatedClaim;
    _syncCardBalanceWithReconciliation();
    notifyListeners();
  }

  /// Approves all pending/rejected lines in a claim and advances its approval stage.
  void approveAllLinesInClaim(String claimId) {
    final idx = _claims.indexWhere((c) => c.id == claimId);
    if (idx < 0) return;
    final claim = _claims[idx];
    if (claim.status == ClaimStatus.fullyClosed) return;

    final updatedLines = claim.lines
        .map((l) => l.copyWith(status: LineStatus.approved, rejectionComment: null))
        .toList();

    final updatedClaim = _advanceClaimStage(
      claim.copyWith(
        lines: updatedLines,
        updatedAt: DateTime.now(),
        auditTrail: [
          ...claim.auditTrail,
          'All lines approved on ${_formatDate(DateTime.now())} by $_activeRole',
        ],
      ),
    );

    _claims[idx] = updatedClaim;
    _syncCardBalanceWithReconciliation();
    notifyListeners();
  }

  ExpenseClaim _advanceClaimStage(ExpenseClaim claim) {
    final stages = List<ApprovalWorkflowStage>.from(claim.approvalStages);
    final pendingIdx = stages.indexWhere((s) => s.status == ApprovalStatus.pending);

    if (pendingIdx != -1) {
      stages[pendingIdx] = ApprovalWorkflowStage(
        stageOrder: stages[pendingIdx].stageOrder,
        roleTitle: stages[pendingIdx].roleTitle,
        approverName: stages[pendingIdx].approverName,
        approverDesignation: stages[pendingIdx].approverDesignation,
        status: ApprovalStatus.approved,
        badgeLabel: 'APPROVED',
        timestamp: DateTime.now(),
        comments: 'Verified and approved.',
      );

      // Unlock next stage up to Stage 3 (Stage 4 is SAP Financial Posting)
      if (pendingIdx + 1 < stages.length) {
        final next = stages[pendingIdx + 1];
        stages[pendingIdx + 1] = ApprovalWorkflowStage(
          stageOrder: next.stageOrder,
          roleTitle: next.roleTitle,
          approverName: next.approverName,
          approverDesignation: next.approverDesignation,
          status: ApprovalStatus.pending,
          badgeLabel: next.stageOrder == 4 ? 'READY FOR SAP' : 'IN REVIEW',
        );
      }
    }

    // If Stage 3 (or last pre-SAP stage) was just approved, mark claim Approved & reconcile cash advance
    final stage3Approved = stages.length >= 3 &&
        stages[2].status == ApprovalStatus.approved;
    final newStatus = stage3Approved ? ClaimStatus.approved : ClaimStatus.submitted;

    if (newStatus == ClaimStatus.approved && claim.status != ClaimStatus.approved) {
      final cashTotal = claim.lines
          .where((l) => l.paymentSource == PaymentSource.cashAdvance)
          .fold(0.0, (s, l) => s + l.totalAmount);
      if (cashTotal > 0) {
        deductCashAdvance(
          employeeId: claim.employeeId,
          amount: cashTotal,
          claimRef: claim.docRefNumber,
        );
      }
    }

    return claim.copyWith(
      status: newStatus,
      approvalStages: stages,
      auditTrail: [
        ...claim.auditTrail,
        if (newStatus == ClaimStatus.approved)
          'All pre-SAP approvals completed on ${_formatDate(DateTime.now())}. Ready for Finance SAP Posting.',
      ],
    );
  }

  /// BRD Section 5.4: Rejects a specific line item with a mandatory comment.
  void rejectClaimLine(String claimId, String lineId, String comment) {
    final trimmed = comment.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Rejection comment is mandatory (BRD Section 5.4).');
    }

    final idx = _claims.indexWhere((c) => c.id == claimId);
    if (idx < 0) return;
    final claim = _claims[idx];
    if (claim.status == ClaimStatus.fullyClosed) return;

    final updatedLines = claim.lines.map((l) {
      if (l.id == lineId) {
        return l.copyWith(status: LineStatus.rejected, rejectionComment: trimmed);
      }
      return l;
    }).toList();

    final stages = List<ApprovalWorkflowStage>.from(claim.approvalStages);
    final pendingIdx = stages.indexWhere((s) => s.status == ApprovalStatus.pending);
    if (pendingIdx != -1) {
      stages[pendingIdx] = ApprovalWorkflowStage(
        stageOrder: stages[pendingIdx].stageOrder,
        roleTitle: stages[pendingIdx].roleTitle,
        approverName: stages[pendingIdx].approverName,
        approverDesignation: stages[pendingIdx].approverDesignation,
        status: ApprovalStatus.rejected,
        badgeLabel: 'REJECTED',
        timestamp: DateTime.now(),
        comments: trimmed,
      );
    }

    _claims[idx] = claim.copyWith(
      lines: updatedLines,
      status: ClaimStatus.partiallyRejected,
      approvalStages: stages,
      updatedAt: DateTime.now(),
      auditTrail: [
        ...claim.auditTrail,
        'Line rejected on ${_formatDate(DateTime.now())} with comment: "$trimmed"',
      ],
    );
    _syncCardBalanceWithReconciliation();
    notifyListeners();
  }

  /// BRD Section 5.6: Post Payment & SAP Reference Number and lock claim as Fully Closed.
  void postSapPaymentDetails({
    required String claimId,
    required String paymentStatus,
    required String paymentNumber,
    required String sapDocRefNumber,
  }) {
    final idx = _claims.indexWhere((c) => c.id == claimId);
    if (idx < 0) return;
    final claim = _claims[idx];
    if (claim.status == ClaimStatus.fullyClosed) return;

    final stages = List<ApprovalWorkflowStage>.from(claim.approvalStages);
    if (stages.length >= 4) {
      stages[3] = ApprovalWorkflowStage(
        stageOrder: 4,
        roleTitle: 'SAP Financial Posting',
        approverName: stages[3].approverName,
        approverDesignation: stages[3].approverDesignation,
        status: ApprovalStatus.approved,
        badgeLabel: 'SAP POSTED',
        timestamp: DateTime.now(),
        comments: 'SAP doc posted: ${sapDocRefNumber.trim()}',
      );
    }

    _claims[idx] = claim.copyWith(
      paymentStatus: paymentStatus.trim(),
      paymentNumber: paymentNumber.trim(),
      sapDocRefNumber: sapDocRefNumber.trim(),
      status: ClaimStatus.fullyClosed,
      approvalStages: stages,
      updatedAt: DateTime.now(),
      auditTrail: [
        ...claim.auditTrail,
        'BRD Section 5.6 Financial Updates: Payment Status $paymentStatus, Payment # $paymentNumber, SAP Ref # $sapDocRefNumber',
        'Status set to Fully Closed (no further edits allowed) on ${_formatDate(DateTime.now())}',
      ],
    );
    _syncCardBalanceWithReconciliation();
    notifyListeners();
  }

  /// Approves and disburses a pending Card Refill Request, increasing Card Balance.
  void approveAndDisburseRefill(String refillId) {
    final idx = _refillRequests.indexWhere((r) => r.refillId == refillId);
    if (idx < 0) return;
    final req = _refillRequests[idx];
    if (req.status == RefillStatus.fundsLoaded) return;

    _refillRequests[idx] = CardRefillRequest(
      refillId: req.refillId,
      cardNumber: req.cardNumber,
      custodianId: req.custodianId,
      custodianName: req.custodianName,
      currentBalance: req.currentBalance,
      requestedAmount: req.requestedAmount,
      urgency: req.urgency,
      businessJustification: req.businessJustification,
      status: RefillStatus.fundsLoaded,
      requestDate: req.requestDate,
      completedDate: DateTime.now(),
    );

    _activeCard = _activeCard.copyWith(
      activeRefillStatus: 'Refill of SAR ${req.requestedAmount.toStringAsFixed(0)} Loaded',
    );
    _syncCardBalanceWithReconciliation();
    notifyListeners();
  }
}
