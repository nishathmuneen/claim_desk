import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:claimdesk/widgets/custom_date_range_sheet.dart';
import 'package:claimdesk/widgets/period_filter_bar.dart';

void main() {
  group('CustomDateRangeSheet Widget Tests', () {
    testWidgets('renders header, date summary card, month headers, and action buttons', (tester) async {
      final initialRange = DateTimeRange(
        start: DateTime(2026, 10, 21),
        end: DateTime(2026, 11, 20),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomDateRangeSheet(
              initialRange: initialRange,
            ),
          ),
        ),
      );

      // Verify Header
      expect(find.text('Select Range'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Verify Date Range Summary Card
      expect(find.text('Date Range'), findsOneWidget);
      expect(find.text('Oct 21 – Nov 20'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

      // Verify Month Headers
      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('November 2026'), findsOneWidget);

      // Verify Action Buttons
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);
    });

    testWidgets('tapping day dates updates selection and Apply returns DateTimeRange', (tester) async {
      DateTimeRange? returnedRange;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  returnedRange = await CustomDateRangeSheet.show(
                    context,
                    initialRange: DateTimeRange(
                      start: DateTime(2026, 10, 21),
                      end: DateTime(2026, 11, 20),
                    ),
                  );
                },
                child: const Text('Open Picker'),
              ),
            ),
          ),
        ),
      );

      // Open modal
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      expect(find.text('Select Range'), findsOneWidget);
      expect(find.text('Oct 21 – Nov 20'), findsOneWidget);

      // Tap Apply
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      // Modal closed and range returned
      expect(find.text('Select Range'), findsNothing);
      expect(returnedRange, isNotNull);
      expect(returnedRange!.start.year, 2026);
      expect(returnedRange!.start.month, 10);
      expect(returnedRange!.start.day, 21);
      expect(returnedRange!.end.year, 2026);
      expect(returnedRange!.end.month, 11);
      expect(returnedRange!.end.day, 20);
    });

    testWidgets('PeriodFilterBar Custom pill opens CustomDateRangeSheet and invokes callback', (tester) async {
      DateFilterPeriod? selectedPeriod;
      DateTimeRange? selectedRange;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PeriodFilterBar(
              selectedPeriod: DateFilterPeriod.mtd,
              customDateRange: null,
              onPeriodChanged: (period, range) {
                selectedPeriod = period;
                selectedRange = range;
              },
            ),
          ),
        ),
      );

      // Tap Custom pill
      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();

      // Verify custom date sheet appears
      expect(find.text('Select Range'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);

      // Tap Apply
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      // Callback invoked
      expect(selectedPeriod, DateFilterPeriod.customRange);
      expect(selectedRange, isNotNull);
    });
  });
}
