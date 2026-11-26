import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:claimdesk/providers/claim_desk_provider.dart';
import 'package:claimdesk/models/picked_document.dart';
import 'package:claimdesk/services/receipt_ocr_service.dart';
import 'package:claimdesk/screens/new_claim_screen.dart';

void main() {
  test('ReceiptOcrService correctly extracts Saudi Bilingual Tax Invoice Layout (Tech Supplies Co.)', () {
    final doc = PickedDocument(
      name: 'Saudi Bilingual Tax Invoice Layout.png',
      sizeInBytes: 1024 * 1024,
      isImage: true,
      extension: 'png',
    );

    final result = ReceiptOcrService.analyzeReceipt(doc, 15.0);

    expect(result.merchantName, 'Tech Supplies Co.');
    expect(result.invoiceNumber, 'INV-2026-0887');
    expect(result.category, 'Hardware & Tools');
    expect(result.baseAmount, 1036.25);
    expect(result.vatAmount, 155.44);
    expect(result.totalAmount, 1191.69);
    expect(result.confidenceScore, greaterThan(0.95));
    expect(result.justification, contains('Wireless Mouse'));
  });

  test('ReceiptOcrService correctly extracts Bilingual Saudi Transport Receipt', () {
    final doc = PickedDocument(
      name: 'Bilingual Saudi Transport Receipt.png',
      sizeInBytes: 1024 * 1024,
      isImage: true,
      extension: 'png',
    );

    final result = ReceiptOcrService.analyzeReceipt(doc, 15.0);

    expect(result.merchantName, 'Al Yamamah Transport Services');
    expect(result.invoiceNumber, 'TR-2026-0148');
    expect(result.category, 'Site Transport & Logistics');
    expect(result.totalAmount, 250.0);
    expect(result.baseAmount, 217.39);
    expect(result.vatAmount, 32.61);
    expect(result.confidenceScore, greaterThan(0.95));
  });

  testWidgets('NewClaimScreen mounts with extracted Site Transport & Logistics without dropdown crash',
      (WidgetTester tester) async {
    final scannedData = {
      'category': 'Site Transport & Logistics',
      'invoiceNumber': 'TR-2026-0148',
      'invoiceDate': DateTime(2026, 11, 16),
      'baseAmount': 217.39,
      'vatAmount': 32.61,
      'totalAmount': 250.0,
      'merchantName': 'Al Yamamah Transport Services',
      'attachmentName': 'Bilingual Saudi Transport Receipt.png',
      'justification': 'Transportation of company materials / goods.',
      'projectCostCenter': 'Aramco Ras Tanura Refinery (CC-402)',
    };

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ClaimDeskProvider()),
        ],
        child: MaterialApp(
          home: NewClaimScreen(
            initialScannedReceipt: scannedData,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify no exception was thrown and fields are properly displayed
    expect(find.text('Site Transport & Logistics'), findsWidgets);
    expect(find.text('TR-2026-0148'), findsOneWidget);
    expect(find.text('217.39'), findsOneWidget);
    expect(find.textContaining('250.00'), findsWidgets);
  });

  testWidgets('NewClaimScreen allows smooth typing in Invoice # and Base Amount without focus loss',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ClaimDeskProvider()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: NewClaimScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Scan-First starter screen appears first with manual option
    expect(find.text('Scan or Upload Document'), findsOneWidget);
    expect(find.text('Enter Details Manually'), findsOneWidget);

    await tester.tap(find.text('Enter Details Manually'));
    await tester.pumpAndSettle();

    final invoiceField = find.widgetWithText(TextFormField, 'Invoice #');
    await tester.ensureVisible(invoiceField);
    await tester.tap(invoiceField);
    await tester.enterText(invoiceField, 'INV-9988');
    await tester.pump();
    expect(find.text('INV-9988'), findsOneWidget);

    final amountField = find.widgetWithText(TextFormField, 'Base Amount (SAR)');
    await tester.ensureVisible(amountField);
    await tester.tap(amountField);
    await tester.enterText(amountField, '100.50');
    await tester.pump();

    expect(find.text('100.50'), findsOneWidget);
    expect(find.textContaining('115.58'), findsWidgets);
  });
}
