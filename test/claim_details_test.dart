import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:claimdesk/providers/claim_desk_provider.dart';
import 'package:claimdesk/screens/claim_details_screen.dart';

void main() {
  testWidgets('ClaimDetailsScreen renders full audit ledger with ZATCA split and 4 stages', (WidgetTester tester) async {
    final provider = ClaimDeskProvider();
    final claim1021 = provider.claims.firstWhere((c) => c.id == 'CLM-1021');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
        ],
        child: MaterialApp(
          home: ClaimDetailsScreen(claim: claim1021),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify Header & Project chip
    expect(find.text('#CLM-1021'), findsOneWidget);
    expect(find.text('SR-1010 (Sadara Complex Jubail)'), findsOneWidget);
    expect(find.text('In Review (Stage 3 of 4)'), findsOneWidget);
    expect(find.text('Riyadh Marriott Hotel - Client Workshop'), findsOneWidget);

    // 2. Verify Total Authorized Reimbursable
    expect(find.text('TOTAL AUTHORIZED REIMBURSABLE'), findsOneWidget);
    expect(find.text('SAR 3,680.00'), findsWidgets);
    expect(find.text('Pre-funded Auth'), findsOneWidget);

    // 3. Verify Financial & ZATCA Tax Split
    expect(find.text('Financial & ZATCA Tax Split'), findsOneWidget);
    expect(find.text('ZATCA Phase 2 Verified'), findsOneWidget);
    expect(find.text('Net Invoiced Amount (Excl. VAT)'), findsOneWidget);
    expect(find.text('SAR 3,200.00'), findsOneWidget);
    expect(find.text('Standard KSA VAT (15%)'), findsOneWidget);
    expect(find.text('SAR 480.00'), findsOneWidget);
    expect(find.text('COST CENTER'), findsOneWidget);
    expect(find.text('GL ACCOUNT CODE'), findsOneWidget);
    expect(find.text('6250 - LODGING - CORP'), findsOneWidget);

    // 4. Verify 4-Level Approval Audit Trail
    expect(find.text('4-Level Approval Audit Trail'), findsOneWidget);
    expect(find.text('Stage 3 / 4 Active'), findsOneWidget);
    expect(find.text('Level 1: Accountant'), findsOneWidget);
    expect(find.text('ACCT VALIDATED'), findsOneWidget);
    expect(find.text('Level 2: Division Manager'), findsOneWidget);
    expect(find.text('DIV MGR SIGN-OFF'), findsOneWidget);
    expect(find.text('Level 3: Procurement Lead'), findsOneWidget);
    expect(find.text('IN REVIEW'), findsOneWidget);
    expect(find.text('Level 4: Finance Manager'), findsOneWidget);
    expect(find.text('PENDING'), findsOneWidget);

    // 5. Verify Ping Approver Button interaction
    final pingFinder = find.text('Ping Approver / Send Reminder');
    await tester.ensureVisible(pingFinder);
    expect(pingFinder, findsOneWidget);
    await tester.tap(pingFinder);
    await tester.pumpAndSettle();

    // 6. Verify Verified Attachments Shelf
    expect(find.text('Verified Attachments'), findsOneWidget);
    expect(find.text('3 Cryptographically Sealed'), findsOneWidget);
    expect(find.text('Marriott_Folio_INV902.pdf'), findsOneWidget);
    expect(find.text('ZATCA OK'), findsOneWidget);
    expect(find.text('POS_Terminal_Slip_A8492.pdf'), findsOneWidget);
    expect(find.text('AUTH 8492'), findsOneWidget);

    // 7. Verify Sticky Bottom Action Dock
    expect(find.text('Download Audit PDF'), findsOneWidget);
    expect(find.text('Message Approver'), findsOneWidget);
    expect(find.text('Request Claim Recall or Adjustment'), findsOneWidget);
  });
}
