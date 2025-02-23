import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfaware_app/components/discarded_dialog.dart';

void main() {
  testWidgets('DiscardedDialog displays correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiscardedDialog(
            maxQuantity: 5,
            onSubmit: (reason, quantity) {},
          ),
        ),
      ),
    );

    expect(find.text('Reason for Discarding'), findsOneWidget);
    expect(find.text('Submit'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.byType(DropdownButton<int>), findsOneWidget);
    expect(find.byType(DropdownButton<String>), findsOneWidget);
  });

  testWidgets(
      'DiscardedDialog shows error message when submit without selection',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiscardedDialog(
            maxQuantity: 5,
            onSubmit: (reason, quantity) {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Submit'));
    await tester.pump();

    expect(find.text('Please provide a reason and select a quantity'),
        findsOneWidget);
  });

  testWidgets('DiscardedDialog calls onSubmit with correct values',
      (WidgetTester tester) async {
    String? submittedReason;
    int? submittedQuantity;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiscardedDialog(
            maxQuantity: 5,
            onSubmit: (reason, quantity) {
              submittedReason = reason;
              submittedQuantity = quantity;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Expired').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit'));
    await tester.pump();

    expect(submittedReason, 'Expired');
    expect(submittedQuantity, 3);
  });
}
