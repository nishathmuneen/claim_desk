import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:claimdesk/models/card_refill_request.dart';
import 'package:claimdesk/models/expense_claim.dart';
import 'package:claimdesk/providers/claim_desk_provider.dart';
import 'package:claimdesk/screens/approval_queue_screen.dart';
import 'package:claimdesk/screens/sap_posting_screen.dart';

void main() {
  test('Line-level rejection requires comment, and Stage 3 approval deducts Cash Advance', () {
    final provider = ClaimDeskProvider();

    // 1. Mandatory comment check
    final submitted = provider.claims.firstWhere((c) => c.id == 'CLM-1021');
    expect(
      () => provider.rejectClaimLine(submitted.id, submitted.lines.first.id, '   '),
      throwsArgumentError,
    );

    provider.rejectClaimLine(submitted.id, submitted.lines.first.id, 'Missing tax invoice stamp');
    final rejected = provider.claims.firstWhere((c) => c.id == 'CLM-1021');
    expect(rejected.status, ClaimStatus.partiallyRejected);
    expect(rejected.lines.first.rejectionComment, 'Missing tax invoice stamp');

    // 2. Submit a Cash Advance claim and approve through Stage 3
    final cashBefore = provider.employeeCashInHandTotal;
    final cashClaim = ExpenseClaim(
      id: 'CLM-CASH-TEST',
      docRefNumber: 'EXP-2026-9901',
      docType: 'Site Operations & Consumables',
      claimDate: DateTime(2026, 3, 2),
      description: 'Cash site tools',
      employeeId: provider.activeUser.employeeId,
      employeeName: provider.activeUser.name,
      costCenter: provider.activeUser.costCenter,
      cardNumber: provider.activeCard.cardNumber,
      vatRatePercentage: 15.0,
      status: ClaimStatus.submitted,
      lines: [
        ExpenseLineItem(
          id: 'LIN-CASH-1',
          date: DateTime(2026, 3, 2),
          category: 'Hardware & Tools',
          invoiceNumber: 'CASH-INV-881',
          baseAmount: 100.0,
          vatRatePercentage: 15.0,
          vatAmount: 15.0,
          totalAmount: 115.0,
          paymentSource: PaymentSource.cashAdvance,
        ),
      ],
      createdAt: DateTime(2026, 3, 2),
      updatedAt: DateTime(2026, 3, 2),
      auditTrail: const [],
    );
    provider.submitClaim(cashClaim);

    // Advance Stage 1 -> Stage 2 -> Stage 3 -> Approved
    provider.approveAllLinesInClaim('CLM-CASH-TEST');
    provider.approveAllLinesInClaim('CLM-CASH-TEST');
    provider.approveAllLinesInClaim('CLM-CASH-TEST');

    final approvedCashClaim = provider.claims.firstWhere((c) => c.id == 'CLM-CASH-TEST');
    expect(approvedCashClaim.status, ClaimStatus.approved);
    expect(provider.employeeCashInHandTotal, closeTo(cashBefore - 115.0, 0.01));

    // 3. SAP Posting locks claim as Fully Closed
    provider.postSapPaymentDetails(
      claimId: 'CLM-CASH-TEST',
      paymentStatus: 'Paid',
      paymentNumber: 'PAY-2026-900',
      sapDocRefNumber: 'SAP-19000999',
    );
    final closedClaim = provider.claims.firstWhere((c) => c.id == 'CLM-CASH-TEST');
    expect(closedClaim.status, ClaimStatus.fullyClosed);
    expect(closedClaim.sapDocRefNumber, 'SAP-19000999');
  });

  test('Approving and disbursing Card Refill increases Enhancement Deposit & Card Balance', () {
    final provider = ClaimDeskProvider();
    final initialBal = provider.reconciledCardBalance;
    final refill = provider.refillRequests.first;
    expect(refill.status, RefillStatus.requested);

    provider.approveAndDisburseRefill(refill.refillId);

    expect(provider.refillRequests.first.status, RefillStatus.fundsLoaded);
    expect(provider.enhancementDepositAmount, refill.requestedAmount);
    expect(provider.reconciledCardBalance, closeTo(initialBal + refill.requestedAmount, 0.01));
    expect(provider.activeCard.currentBalance, provider.reconciledCardBalance);
  });

  testWidgets('ApprovalQueueScreen and SapPostingScreen render cleanly', (tester) async {
    final provider = ClaimDeskProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(
          home: Scaffold(body: ApprovalQueueScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('APPROVAL QUEUE'), findsOneWidget);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(
          home: Scaffold(body: SapPostingScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('SAP & Payment Posting'), findsOneWidget);
    expect(find.text('Card Refill Queue'), findsOneWidget);
  });
}
