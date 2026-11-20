import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:claimdesk/providers/claim_desk_provider.dart';
import 'package:claimdesk/screens/claims_history_screen.dart';

void main() {
  testWidgets('ClaimsHistoryScreen renders search field and luxury status filter pills', (tester) async {
    final provider = ClaimDeskProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<ClaimDeskProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: Scaffold(
            body: ClaimsHistoryScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Search Field presence
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Search by Ref # or description...'), findsOneWidget);

    // Verify Status Filter Pills
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Drafts'), findsOneWidget);
    expect(find.text('In Review'), findsOneWidget);
    expect(find.text('Needs Action'), findsOneWidget);

    // Initially "All" is selected with check icon
    expect(find.byIcon(Icons.check), findsOneWidget);

    // Tap "Drafts" pill
    await tester.tap(find.text('Drafts'));
    await tester.pumpAndSettle();

    // Check that check icon is still present (now on Drafts)
    expect(find.byIcon(Icons.check), findsOneWidget);

    // Type query into search field
    await tester.enterText(find.byType(TextField), 'EXP-2026-0044');
    await tester.pumpAndSettle();

    // Clear icon appears and can be tapped
    expect(find.byIcon(Icons.clear), findsOneWidget);
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();

    expect(find.text('Search by Ref # or description...'), findsOneWidget);
  });
}
