import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/components/request_status_filter.dart';

void main() {
  testWidgets('RequestStatusFilter displays correct text', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: RequestStatusFilter(),
          ),
        ),
      ),
    );

    // Verify that the default value 'All' is displayed
    expect(find.text('All'), findsOneWidget);

    // Open the dropdown menu
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();

    // Verify that all the dropdown items are displayed
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('Declined'), findsOneWidget);
    expect(find.text('Picked Up'), findsOneWidget);

    // Select 'Accepted' from the dropdown
    await tester.tap(find.text('Accepted').last);
    await tester.pumpAndSettle();

    // Verify that the selected value 'Accepted' is displayed
    expect(find.text('Accepted'), findsOneWidget);
  });
}