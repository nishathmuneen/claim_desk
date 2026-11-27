import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:claimdesk/models/card_statement.dart';
import 'package:claimdesk/providers/claim_desk_provider.dart';
import 'package:claimdesk/screens/reconciliation_screen.dart';

void main() {
  test('Tariq Mansoor card balance, spent amount, and reconciliation balance match 100%', () {
    final provider = ClaimDeskProvider();

    expect(provider.activeUser.id, 'USR-001');
    expect(provider.activeCard.monthlyLimit, 5000.0);
    expect(provider.activeCard.currentBalance, 450.0);
    expect(provider.activeCard.spentAmount, 4550.0);
    expect(provider.reconciledCardBalance, 450.0);
    expect(provider.activeCard.currentBalance, provider.reconciledCardBalance);
    expect(provider.employeeAdvanceTotal, 1000.0);
    expect(provider.employeeCashInHandTotal, 600.0);
  });

  test('Importing ATM withdrawal auto-credits Employee Cash Advance & duplicate invoice check works', () {
    final provider = ClaimDeskProvider();
    final initialAdvance = provider.activeUserCashAdvance?.totalWithdrawn ?? 0.0;

    final imported = provider.importCardStatement([
      CardStatementTransaction(
        id: 'STX-TEST-ATM',
        cardNumber: provider.activeCard.cardNumber,
        date: DateTime(2026, 3, 1),
        merchantOrAtm: 'Al Rajhi ATM Test',
        description: 'ATM Withdrawal',
        amount: 500.0,
        type: StatementTxType.atmWithdrawal,
        employeeId: provider.activeUser.employeeId,
      ),
    ]);

    expect(imported, 1);
    expect(provider.activeUserCashAdvance!.totalWithdrawn, initialAdvance + 500.0);

    // Duplicate invoice check against seeded submitted claims
    final existingInvoice = provider.claims.first.lines.first.invoiceNumber;
    expect(provider.isDuplicateInvoice(existingInvoice), isTrue);
    expect(provider.isDuplicateInvoice('UNIQUE-INV-999999'), isFalse);
  });

  testWidgets('ReconciliationScreen renders Card and Cash Balance Statement and 5 tabs', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ClaimDeskProvider(),
        child: const MaterialApp(
          home: ReconciliationScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Card and Cash Balance Statement'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Card Detail Statement'), findsOneWidget);
    expect(find.text('Expense List'), findsOneWidget);
    expect(find.text('Deposit List'), findsOneWidget);
    expect(find.text('Summary List'), findsOneWidget);
    expect(find.text('Balance in Card'), findsOneWidget);
  });
}

