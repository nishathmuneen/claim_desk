import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:claimdesk/main.dart';
import 'package:claimdesk/providers/claim_desk_provider.dart';

void main() {
  testWidgets('ClaimDesk app loads splash and navigates to login', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ClaimDeskProvider()),
        ],
        child: const ClaimDeskApp(),
      ),
    );

    // Initial frame on splash screen
    expect(find.text('Inspiring Excellence'), findsOneWidget);

    // Settle splash timer (2.3s) and navigate to Login
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verifies Login screen is loaded with User / Custodian selection only
    expect(find.text('Select Employee (Card Custodian)'), findsOneWidget);
    expect(find.text('Sign In to ClaimDesk'), findsOneWidget);
  });
}
