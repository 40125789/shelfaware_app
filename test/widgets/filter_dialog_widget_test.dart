import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfaware_app/components/filter_dialogue_widget.dart';

void main() {
  testWidgets('FilterDialog displays correctly', (WidgetTester tester) async {
    bool expiringSoon = false;
    bool newlyAdded = false;
    double? distance;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterDialog(
            filterExpiringSoon: expiringSoon,
            filterNewlyAdded: newlyAdded,
            filterDistance: distance,
            onExpiringSoonChanged: (value) => expiringSoon = value as bool,
            onNewlyAddedChanged: (value) => newlyAdded = value as bool,
            onDistanceChanged: (value) => distance = value,
            onApply: () {},
          ),
        ),
      ),
    );

    expect(find.text('Donations Filter'), findsOneWidget);
    expect(find.text('Sort by:'), findsOneWidget);
    expect(find.text('Expiring Soon'), findsOneWidget);
    expect(find.text('Newly Added'), findsOneWidget);
    expect(find.text('Maximum Distance:'), findsOneWidget);
    expect(find.text('0.3 miles'), findsOneWidget);
    expect(find.text('0.6 miles'), findsOneWidget);
    expect(find.text('1.3 miles'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
  });

  testWidgets('FilterDialog toggles expiring soon filter',
      (WidgetTester tester) async {
    bool expiringSoon = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterDialog(
            filterExpiringSoon: expiringSoon,
            filterNewlyAdded: false,
            filterDistance: null,
            onExpiringSoonChanged: (value) => expiringSoon = value as bool,
            onNewlyAddedChanged: (value) {},
            onDistanceChanged: (value) {},
            onApply: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Expiring Soon'));
    await tester.pump();

    expect(expiringSoon, isTrue);
  });

  testWidgets('FilterDialog toggles newly added filter',
      (WidgetTester tester) async {
    bool newlyAdded = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterDialog(
            filterExpiringSoon: false,
            filterNewlyAdded: newlyAdded,
            filterDistance: null,
            onExpiringSoonChanged: (value) {},
            onNewlyAddedChanged: (value) => newlyAdded = value as bool,
            onDistanceChanged: (value) {},
            onApply: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Newly Added'));
    await tester.pump();

    expect(newlyAdded, isTrue);
  });

  testWidgets('FilterDialog toggles distance filter',
      (WidgetTester tester) async {
    double? distance;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterDialog(
            filterExpiringSoon: false,
            filterNewlyAdded: false,
            filterDistance: distance,
            onExpiringSoonChanged: (value) {},
            onNewlyAddedChanged: (value) {},
            onDistanceChanged: (value) => distance = value,
            onApply: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('0.3 miles'));
    await tester.pump();

    expect(distance, 0.3);
  });

  testWidgets('FilterDialog apply button works', (WidgetTester tester) async {
    bool applyPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterDialog(
            filterExpiringSoon: false,
            filterNewlyAdded: false,
            filterDistance: null,
            onExpiringSoonChanged: (value) {},
            onNewlyAddedChanged: (value) {},
            onDistanceChanged: (value) {},
            onApply: () => applyPressed = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Apply'));
    await tester.pump();

    expect(applyPressed, isTrue);
  });
}
