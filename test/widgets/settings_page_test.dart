import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfaware_app/pages/settings_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('SettingsPage displays correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SettingsPage(),
        ),
      ),
    );

    // Verify the AppBar title
    expect(find.text('Settings'), findsOneWidget);

    // Verify the Theme section
    expect(find.text('Theme'), findsOneWidget);
    expect(find.byIcon(Icons.palette), findsOneWidget);

    // Verify the Notification Preferences section
    expect(find.text('Notification Preferences'), findsOneWidget);
    expect(find.byIcon(Icons.notifications), findsOneWidget);
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Donation Requests'), findsOneWidget);
    expect(find.text('Expiry Alerts'), findsOneWidget);

    // Verify the Other section
    expect(find.text('App powered by:'), findsOneWidget);
    expect(find.byIcon(Icons.info), findsOneWidget);
  });

  testWidgets('Toggle Dark Mode switch', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SettingsPage(),
        ),
      ),
    );

    // Find the Dark Mode switch and toggle it
    final darkModeSwitch = find.byType(Switch).first;
    expect(darkModeSwitch, findsOneWidget);

    await tester.tap(darkModeSwitch);
    await tester.pump();

    // Verify the switch has been toggled
    expect((tester.widget(darkModeSwitch) as Switch).value, isTrue);
  });

  testWidgets('Toggle Notifications switches', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SettingsPage(),
        ),
      ),
    );

    // Find and toggle the Messages switch
    final messagesSwitch = find.byType(Switch).at(1);
    expect(messagesSwitch, findsOneWidget);

    await tester.tap(messagesSwitch);
    await tester.pump();

    // Verify the switch has been toggled
    expect((tester.widget(messagesSwitch) as Switch).value, isFalse);

    // Find and toggle the Donation Requests switch
    final donationSwitch = find.byType(Switch).at(2);
    expect(donationSwitch, findsOneWidget);

    await tester.tap(donationSwitch);
    await tester.pump();

    // Verify the switch has been toggled
    expect((tester.widget(donationSwitch) as Switch).value, isFalse);

    // Find and toggle the Expiry Alerts switch
    final expirySwitch = find.byType(Switch).at(3);
    expect(expirySwitch, findsOneWidget);

    await tester.tap(expirySwitch);
    await tester.pump();

    // Verify the switch has been toggled
    expect((tester.widget(expirySwitch) as Switch).value, isFalse);
  });
}
