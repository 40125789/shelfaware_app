import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfaware_app/components/withdraw_request_dialog.dart';

void main() {
  testWidgets('showWithdrawDialog displays correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showWithdrawDialog(context),
            child: Text('Show Dialog'),
          ),
        ),
      ),
    );

    // Tap the button to show the dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Verify the dialog is displayed
    expect(find.text('Confirm Withdrawal'), findsOneWidget);
    expect(
        find.text(
            'Are you sure you want to withdraw this request?\n\nPlease let the donor know before you do!'),
        findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Withdraw'), findsOneWidget);
  });

  testWidgets('showWithdrawDialog returns true when Withdraw is tapped',
      (WidgetTester tester) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showWithdrawDialog(context);
            },
            child: Text('Show Dialog'),
          ),
        ),
      ),
    );

    // Tap the button to show the dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Tap the Withdraw button
    await tester.tap(find.text('Withdraw'));
    await tester.pumpAndSettle();

    // Verify the result is true
    expect(result, true);
  });

  testWidgets('showWithdrawDialog returns false when Cancel is tapped',
      (WidgetTester tester) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showWithdrawDialog(context);
            },
            child: Text('Show Dialog'),
          ),
        ),
      ),
    );

    // Tap the button to show the dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Tap the Cancel button
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Verify the result is false
    expect(result, false);
  });
}
