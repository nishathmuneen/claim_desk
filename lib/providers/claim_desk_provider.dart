import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/user_profile.dart';
import '../models/petty_cash_card.dart';
import '../models/expense_claim.dart';
import '../models/ocr_scan_result.dart';

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
    _syncCardForActiveUser();
    _seedMockClaims();
  }

  void _syncCardForActiveUser() {
    _activeCard = PettyCashCard(
      cardNumber: _activeUser.assignedCardNumber,
      cardholderName: _activeUser.name,
      employeeId: _activeUser.employeeId,
      company: _activeUser.company,
      division: _activeUser.division,
      department: _activeUser.department,
      designation: _activeUser.designation,
      costCenter: _activeUser.costCenter,
      iqama: _activeUser.iqama,
      phone: _activeUser.phone,
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 12, 31),
      monthlyLimit: 15000.0,
      currentBalance: 11250.0,
      spentAmount: 3750.0,
    );
  }

  void switchUser(UserProfile user) {
    _activeUser = user;
    _syncCardForActiveUser();
    notifyListeners();
  }

  void switchRole(String role) {
    _activeRole = role;
    notifyListeners();
  }

  void updateConfiguredVatRate(double newRate) {
    _configuredVatPercentage = newRate;
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
    final submitted = claim.copyWith(
      status: ClaimStatus.submitted,
      updatedAt: DateTime.now(),
      auditTrail: [
        ...claim.auditTrail,
        'Submitted to approval workflow on ${_formatDate(DateTime.now())} by ${_activeUser.name}'
      ],
    );
    if (index >= 0) {
      _claims[index] = submitted;
    } else {
      _claims.insert(0, submitted);
    }
    notifyListeners();
  }

  /// BRD Section 5.4: Rejected lines resubmission creates a NEW Document/Reference Number
  void resubmitRejectedLine({
    required String originalClaimId,
    required ExpenseLineItem updatedLine,
  }) {
    final originalIndex = _claims.indexWhere((c) => c.id == originalClaimId);
    if (originalIndex < 0) return;

    final original = _claims[originalIndex];

    // Mark line as resubmitted in original claim
    final updatedOriginalLines = original.lines.map((l) {
      if (l.id == updatedLine.id) {
        return l.copyWith(isResubmitted: true);
      }
      return l;
    }).toList();

    _claims[originalIndex] = original.copyWith(
      lines: updatedOriginalLines,
      status: original.lines.every((l) => l.isResubmitted || l.status == LineStatus.approved)
          ? ClaimStatus.approved
          : ClaimStatus.partiallyRejected,
      auditTrail: [
        ...original.auditTrail,
        'Line ${updatedLine.category} was revised and split into a new submission on ${_formatDate(DateTime.now())}',
      ],
    );

    // Create BRAND NEW Document with its own Reference Number
    final newRefNumber = '${original.docRefNumber}-R1';
    final newClaim = ExpenseClaim(
      id: _uuid.v4(),
      docRefNumber: newRefNumber,
      docType: original.docType,
      claimDate: DateTime.now(),
      description: 'Resubmission of revised line for ${updatedLine.category} (Ref: ${original.docRefNumber})',
      employeeId: _activeUser.employeeId,
      employeeName: _activeUser.name,
      costCenter: _activeUser.costCenter,
      cardNumber: _activeCard.cardNumber,
      vatRatePercentage: _configuredVatPercentage,
      status: ClaimStatus.submitted,
      lines: [
        updatedLine.copyWith(
          id: _uuid.v4(),
          status: LineStatus.pending,
          rejectionComment: null,
          isResubmitted: false,
        ),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      originalRefNumber: original.docRefNumber,
      auditTrail: [
        'Created automatically on ${_formatDate(DateTime.now())} as resubmission of rejected line from ${original.docRefNumber}',
        'Submitted to approval workflow on ${_formatDate(DateTime.now())}',
      ],
    );

    _claims.insert(0, newClaim);
    notifyListeners();
  }

  // Realistic OCR receipt samples for simulation
  static final List<OcrScanResult> _mockReceipts = [
    OcrScanResult(
      merchantName: 'Aramco Fuel Service Station #42',
      invoiceDate: DateTime.now().subtract(const Duration(days: 1)),
      invoiceNumber: 'INV-ARAMCO-9841',
      baseAmount: 180.00,
      vatAmount: 27.00,
      totalAmount: 207.00,
      confidenceScore: 0.96,
      isHighConfidence: true,
      category: 'Fuel & Fleet',
      sampleReceiptImage: 'fuel_receipt.jpg',
    ),
    OcrScanResult(
      merchantName: 'Jarir Bookstore & Office Supplies',
      invoiceDate: DateTime.now().subtract(const Duration(days: 3)),
      invoiceNumber: 'INV-JARIR-23091',
      baseAmount: 320.00,
      vatAmount: 48.00,
      totalAmount: 368.00,
      confidenceScore: 0.94,
      isHighConfidence: true,
      category: 'Office Supplies',
      sampleReceiptImage: 'jarir_receipt.jpg',
    ),
    OcrScanResult(
      merchantName: 'Al-Tamimi Equipment Spares & Hardware',
      invoiceDate: DateTime.now().subtract(const Duration(days: 2)),
      invoiceNumber: 'INV-ALTAMIMI-5012',
      baseAmount: 450.00,
      vatAmount: 67.50,
      totalAmount: 517.50,
      confidenceScore: 0.88,
      isHighConfidence: false, // Needs user verification
      category: 'Maintenance & Parts',
      sampleReceiptImage: 'hardware_receipt.jpg',
    ),
  ];

  int _ocrIndex = 0;
  Future<OcrScanResult> simulateOcrScan() async {
    await Future.delayed(const Duration(milliseconds: 1400));
    final result = _mockReceipts[_ocrIndex % _mockReceipts.length];
    _ocrIndex++;
    return result;
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _seedMockClaims() {
    _claims.addAll([
      // 1. Rejected Line Claim (BRD Section 5.4 Demo)
      ExpenseClaim(
        id: 'CLM-001',
        docRefNumber: 'EXP-2026-0040',
        docType: 'Petty Cash Reimbursement',
        claimDate: DateTime(2026, 11, 10),
        description: 'Jubail Field Workshop Emergency Spares & Courier',
        employeeId: _activeUser.employeeId,
        employeeName: _activeUser.name,
        costCenter: _activeUser.costCenter,
        cardNumber: _activeCard.cardNumber,
        vatRatePercentage: 15.0,
        status: ClaimStatus.partiallyRejected,
        lines: [
          ExpenseLineItem(
            id: 'LIN-101',
            date: DateTime(2026, 11, 8),
            category: 'Courier & Freight',
            invoiceNumber: 'SPL-8821-CR',
            baseAmount: 120.00,
            vatRatePercentage: 15.0,
            vatAmount: 18.00,
            totalAmount: 138.00,
            attachmentName: 'courier_slip.pdf',
            status: LineStatus.approved,
          ),
          ExpenseLineItem(
            id: 'LIN-102',
            date: DateTime(2026, 11, 9),
            category: 'Maintenance & Parts',
            invoiceNumber: 'SP-FILTER-491',
            baseAmount: 345.00,
            vatRatePercentage: 15.0,
            vatAmount: 51.75,
            totalAmount: 396.75,
            attachmentName: 'handwritten_bill.jpg',
            status: LineStatus.rejected,
            rejectionComment:
                'ZATCA tax invoice missing. Handwritten slip is not accepted by Accounts Payable as per policy. Please re-upload official VAT invoice.',
          ),
        ],
        createdAt: DateTime(2026, 11, 10, 10, 15),
        updatedAt: DateTime(2026, 11, 11, 14, 30),
        auditTrail: [
          'Claim created on 10/11/2026 by Tariq Mansoor',
          'Submitted to approval workflow on 10/11/2026',
          'Line #1 Approved by Rajesh M Shetty (Accounts Manager) on 11/11/2026',
          'Line #2 REJECTED by Ganesh P Shetty (Section Head - AP) with comment: "ZATCA tax invoice missing..." on 11/11/2026',
        ],
      ),

      // 2. Draft Claim (BRD Section 5.3 Demo)
      ExpenseClaim(
        id: 'CLM-002',
        docRefNumber: 'EXP-2026-0041',
        docType: 'Petty Cash Reimbursement',
        claimDate: DateTime(2026, 11, 12),
        description: 'Site Office Safety Consumables & First Aid Restock',
        employeeId: _activeUser.employeeId,
        employeeName: _activeUser.name,
        costCenter: _activeUser.costCenter,
        cardNumber: _activeCard.cardNumber,
        vatRatePercentage: 15.0,
        status: ClaimStatus.draft,
        lines: [
          ExpenseLineItem(
            id: 'LIN-201',
            date: DateTime(2026, 11, 12),
            category: 'Safety Consumables',
            invoiceNumber: 'SAF-9901-SA',
            baseAmount: 260.00,
            vatRatePercentage: 15.0,
            vatAmount: 39.00,
            totalAmount: 299.00,
            attachmentName: 'safety_firstaid_tax_inv.pdf',
            status: LineStatus.pending,
          ),
        ],
        createdAt: DateTime(2026, 11, 12, 09, 00),
        updatedAt: DateTime(2026, 11, 12, 09, 15),
        auditTrail: ['Saved as draft on 12/11/2026 by Tariq Mansoor'],
      ),

      // 3. Submitted Claim under Review
      ExpenseClaim(
        id: 'CLM-003',
        docRefNumber: 'EXP-2026-0039',
        docType: 'Petty Cash Reimbursement',
        claimDate: DateTime(2026, 11, 7),
        description: 'Highway Tolls and Emergency Fleet Fuel Top-up',
        employeeId: _activeUser.employeeId,
        employeeName: _activeUser.name,
        costCenter: _activeUser.costCenter,
        cardNumber: _activeCard.cardNumber,
        vatRatePercentage: 15.0,
        status: ClaimStatus.submitted,
        lines: [
          ExpenseLineItem(
            id: 'LIN-301',
            date: DateTime(2026, 11, 6),
            category: 'Fuel & Fleet',
            invoiceNumber: 'SASCO-FUEL-1029',
            baseAmount: 410.00,
            vatRatePercentage: 15.0,
            vatAmount: 61.50,
            totalAmount: 471.50,
            attachmentName: 'sasco_vat_receipt.jpg',
            status: LineStatus.pending,
          ),
        ],
        createdAt: DateTime(2026, 11, 7, 11, 40),
        updatedAt: DateTime(2026, 11, 7, 11, 45),
        auditTrail: [
          'Created on 07/11/2026 by Tariq Mansoor',
          'Submitted to Approval Workflow (Routing: Flexible Workflow)',
        ],
      ),

      // 4. Fully Closed Claim (BRD Section 5.6 Demo - SAP Reference & Payment Closure)
      ExpenseClaim(
        id: 'CLM-004',
        docRefNumber: 'EXP-2026-0031',
        docType: 'Petty Cash Reimbursement',
        claimDate: DateTime(2026, 10, 24),
        description: 'Monthly Office Stationeries & Printing Inks',
        employeeId: _activeUser.employeeId,
        employeeName: _activeUser.name,
        costCenter: _activeUser.costCenter,
        cardNumber: _activeCard.cardNumber,
        vatRatePercentage: 15.0,
        status: ClaimStatus.fullyClosed,
        paymentStatus: 'Paid',
        paymentNumber: 'PAY-2026-8819',
        sapDocRefNumber: 'SAP-19000452',
        lines: [
          ExpenseLineItem(
            id: 'LIN-401',
            date: DateTime(2026, 10, 22),
            category: 'Office Supplies',
            invoiceNumber: 'JARIR-PRINT-771',
            baseAmount: 550.00,
            vatRatePercentage: 15.0,
            vatAmount: 82.50,
            totalAmount: 632.50,
            attachmentName: 'jarir_receipt.pdf',
            status: LineStatus.approved,
          ),
        ],
        createdAt: DateTime(2026, 10, 24, 08, 30),
        updatedAt: DateTime(2026, 10, 29, 16, 20),
        auditTrail: [
          'Created on 24/10/2026 by Tariq Mansoor',
          'Submitted on 24/10/2026',
          'Approved by Rajesh M Shetty on 26/10/2026',
          'Post-Approval Financial Update completed by Authorized Finance User on 29/10/2026',
          'Payment Status: Paid | Payment #: PAY-2026-8819 | SAP Doc Ref #: SAP-19000452',
          'Document status marked as FULLY CLOSED (No further edits allowed)',
        ],
      ),
    ]);
  }
}

