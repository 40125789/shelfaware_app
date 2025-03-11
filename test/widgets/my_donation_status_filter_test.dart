import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfaware_app/components/my_donation_status_filter.dart';

void main() {
  testWidgets('StatusFilterWidget displays correct initial status', (WidgetTester tester) async {
    const selectedStatus = 'Available';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatusFilterWidget(
            selectedStatus: selectedStatus,
            onStatusChanged: (String status) {},
          ),
        ),
      ),
    );

    expect(find.text(selectedStatus), findsOneWidget);
  });

  testWidgets('StatusFilterWidget calls onStatusChanged when a new status is selected', (WidgetTester tester) async {
    String? changedStatus;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatusFilterWidget(
            selectedStatus: 'Available',
            onStatusChanged: (String status) {
              changedStatus = status;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reserved').last);
    await tester.pumpAndSettle();

    expect(changedStatus, 'Reserved');
  });

  testWidgets('StatusFilterWidget displays correct badge and color for each status', (WidgetTester tester) async {
  const statuses = ['Available', 'Reserved', 'Picked Up'];
  final badgeColors = [ Colors.green, Colors.orange, Colors.blue];
  final badgeIcons = [Icons.check_circle, Icons.hourglass_empty, Icons.card_giftcard];

  for (int i = 0; i < statuses.length; i++) {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatusFilterWidget(
            selectedStatus: statuses[i],
            onStatusChanged: (String status) {},
          ),
        ),
      ),
    );

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byWidgetPredicate((widget) => widget is DropdownMenuItem<String> && widget.value == statuses[i]),
        matching: find.byWidgetPredicate((widget) => widget is Icon && widget.icon == badgeIcons[i]),
      ),
      findsOneWidget,
    );
    expect(
      (tester.widget(find.byType(CircleAvatar)) as CircleAvatar).backgroundColor,
      badgeColors[i],
    );
  }
});
}