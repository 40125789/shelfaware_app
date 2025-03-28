import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfaware_app/components/my_donation_status_filter.dart';

void main() {
  testWidgets('StatusFilterWidget displays correct initial status',
      (WidgetTester tester) async {
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

  testWidgets(
      'StatusFilterWidget calls onStatusChanged when a new status is selected',
      (WidgetTester tester) async {
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

  testWidgets(
      'StatusFilterWidget displays correct badge and color for each status',
      (WidgetTester tester) async {
    const statuses = ['Available', 'Reserved', 'Picked Up'];
    final badgeColors = [Colors.green, Colors.orange, Colors.blue];
    final badgeIcons = [
      Icons.check_circle,
      Icons.hourglass_empty,
      Icons.card_giftcard
    ];

    for (int i = 0; i < statuses.length; i++) {
      // Build the widget tree with the current status
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

      // Open the dropdown by tapping the dropdown button
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // Find the DropdownMenuItem for the current status in the dropdown menu
      final itemFinder =
          find.widgetWithText(DropdownMenuItem<String>, statuses[i]).last;

      // Check if the CircleAvatar inside the menu has the correct background color
      final circleAvatarFinder = find.descendant(
        of: itemFinder,
        matching: find.byWidgetPredicate((widget) =>
            widget is CircleAvatar && widget.backgroundColor == badgeColors[i]),
      );
      expect(circleAvatarFinder, findsOneWidget);
      final circleAvatar = tester.widget<CircleAvatar>(circleAvatarFinder);

      // Validate the background color
      expect(circleAvatar.backgroundColor, badgeColors[i]);

      // Ensure only one icon exists for the specific badge
      final iconFinder = find.descendant(
        of: itemFinder,
        matching: find.byIcon(badgeIcons[i]),
      );

      // Ensure there's exactly one matching icon
      expect(iconFinder, findsOneWidget);
    }
  });
}
