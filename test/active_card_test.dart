import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:claimdesk/widgets/active_card_card.dart';
import 'package:claimdesk/models/petty_cash_card.dart';

void main() {
  final sampleCard = PettyCashCard(
    cardNumber: '4821-8890-1120-9901',
    cardholderName: 'Tariq Mansoor',
    employeeId: 'EMP-9021',
    company: 'Expertise Contracting Co.',
    division: 'Eastern Region (Dammam)',
    department: 'Logistics & Fleet',
    designation: 'Site Operations Lead',
    costCenter: 'CC-101',
    iqama: '2491823401',
    phone: '+966 50 123 4567',
    startDate: DateTime(2026, 1, 1),
    endDate: DateTime(2028, 9, 30),
    monthlyLimit: 5000.0,
    currentBalance: 450.0,
    spentAmount: 4550.0,
    minimumThreshold: 1000.0,
  );

  testWidgets('ActiveCardCard matches exact luxury ivory and gold card layout', (WidgetTester tester) async {
    bool tapped = false;
    bool refilled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ActiveCardCard(
              card: sampleCard,
              onTap: () => tapped = true,
              onRequestRefill: () => refilled = true,
            ),
          ),
        ),
      ),
    );

    // Verify Title & Subtitles
    expect(find.text('CORPORATE PRE-FUNDED'), findsOneWidget);
    expect(find.text('Executive Mobility'), findsOneWidget);

    // Verify Card Number initially masked
    expect(find.text('••••  ••••  ••••  9901'), findsOneWidget);

    // Verify Custodian & Validity
    expect(find.text('CARD CUSTODIAN'), findsOneWidget);
    expect(find.text('TARIQ MANSOOR'), findsOneWidget);
    expect(find.text('VALID THRU'), findsOneWidget);
    expect(find.text('09/28'), findsOneWidget);

    // Verify Status & Progress
    expect(find.text('91% THRESHOLD'), findsOneWidget);

    // Verify Bottom Ribbon (Remaining & Limit)
    expect(find.text('Remaining: '), findsOneWidget);
    expect(find.text('SAR 450'), findsOneWidget);
    expect(find.text('Limit: '), findsOneWidget);
    expect(find.text('SAR 5000'), findsOneWidget);

    // Toggle card number visibility
    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pumpAndSettle();

    expect(find.text('4821  8890  1120  9901'), findsOneWidget);
    expect(find.byIcon(Icons.visibility_off), findsOneWidget);

    // Verify Refill action button
    final refillBtn = find.text('Submit Invoices & Request Refill');
    expect(refillBtn, findsOneWidget);
    await tester.tap(refillBtn);
    expect(refilled, isTrue);

    // Verify card onTap
    await tester.tap(find.text('Executive Mobility'));
    expect(tapped, isTrue);
  });
}
