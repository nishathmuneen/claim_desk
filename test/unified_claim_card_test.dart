import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:claimdesk/models/expense_claim.dart';
import 'package:claimdesk/providers/claim_desk_provider.dart';
import 'package:claimdesk/widgets/unified_claim_card.dart';

void main() {
  group('UnifiedClaimCard Widget Tests', () {
    final provider = ClaimDeskProvider();

    testWidgets('renders #CLM-1021 card matching reference picture', (WidgetTester tester) async {
      final claim1021 = provider.claims.firstWhere((c) => c.id == 'CLM-1021');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedClaimCard(claim: claim1021),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Reference Number
      expect(find.text('#CLM-1021'), findsOneWidget);

      // Check Amount Pill with formatted comma
      expect(find.text('SAR 1,150.00'), findsOneWidget);

      // Check Description
      expect(find.text('Riyadh Marriott Hotel - Client Workshop'), findsOneWidget);

      // Check Date and Project Code
      expect(find.text('28 Oct 2026'), findsOneWidget);
      expect(find.text('SR-1010 (Sadara Complex Jubail)'), findsOneWidget);

      // Check Compliant with Policy badge
      expect(find.text('Compliant with Policy'), findsOneWidget);

      // Check Status chip
      expect(find.text('In Approval'), findsOneWidget);

      // Check Stepper stages
      expect(find.text('L1 Mgr'), findsWidgets);
    });

    testWidgets('renders Draft claim card matching reference picture', (WidgetTester tester) async {
      final draftClaim = provider.claims.firstWhere((c) => c.status == ClaimStatus.draft);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedClaimCard(claim: draftClaim),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Reference Number
      expect(find.text('#EXP-2026-0044'), findsOneWidget);

      // Check Amount Pill
      expect(find.text('SAR 345.00'), findsOneWidget);

      // Check Compliant with Policy badge
      expect(find.text('Compliant with Policy'), findsOneWidget);

      // Check Draft chip
      expect(find.text('Draft'), findsOneWidget);
    });

    testWidgets('renders Action Needed claim card with rejected status', (WidgetTester tester) async {
      final rejectedClaim = provider.claims.firstWhere((c) => c.hasRejectedLines);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedClaimCard(claim: rejectedClaim),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Reference Number
      expect(find.text('#EXP-2026-0040'), findsOneWidget);

      // Check Action Needed Chip
      expect(find.text('Action Needed'), findsOneWidget);

      // Check Action Needed Banner
      expect(find.text('Action Needed: 1 item requires resubmission'), findsOneWidget);
    });
  });
}

