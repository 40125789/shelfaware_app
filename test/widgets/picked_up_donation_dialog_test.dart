import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfaware_app/components/picked_up_donation_dialog.dart';

void main() {
  testWidgets('PickedUpDonationDialog displays correctly',
      (WidgetTester tester) async {
    // Build the dialog
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) => PickedUpDonationDialog(),
                  );
                },
                child: Text('Show Dialog'),
              );
            },
          ),
        ),
      ),
    );

    // Tap the button to show the dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Verify the dialog is displayed
    expect(find.text('Donation Collected'), findsOneWidget);
    expect(find.text("You've saved another food item from going to waste!"),
        findsOneWidget);
    expect(find.text('OK'), findsOneWidget);

    // Tap the OK button to close the dialog
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Verify the dialog is closed
    expect(find.text('Donation Collected'), findsNothing);
  });
}
