
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfaware_app/services/dialog_service.dart';

void main() {
  testWidgets('showExpiredItemDialog displays correct message', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return ElevatedButton(
              onPressed: () => DialogService.showExpiredItemDialog(context),
              child: Text('Show Dialog'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Donation Alert!'), findsOneWidget);
    expect(find.text('This item has expired and cannot be donated.'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
  });

  testWidgets('showConfirmDeletionDialog displays correct message and returns true on delete', (WidgetTester tester) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return ElevatedButton(
              onPressed: () async {
                result = await DialogService.showConfirmDeletionDialog(context);
              },
              child: Text('Show Dialog'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Confirm Deletion'), findsOneWidget);
    expect(find.text('Are you sure you want to delete this item? This action cannot be undone.'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(result, true);
  });

  testWidgets('showConfirmDonationDialog displays correct message and returns true on donate', (WidgetTester tester) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return ElevatedButton(
              onPressed: () async {
                result = await DialogService.showConfirmDonationDialog(context);
              },
              child: Text('Show Dialog'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Confirm Donation'), findsOneWidget);
    expect(find.text('Are you sure you want to donate this item?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Donate'), findsOneWidget);

    await tester.tap(find.text('Donate'));
    await tester.pumpAndSettle();

    expect(result, true);
  });
}