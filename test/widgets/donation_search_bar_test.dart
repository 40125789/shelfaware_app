import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfaware_app/components/donation_search_bar.dart';

void main() {
  testWidgets('SearchBarWidget has a hint text', (WidgetTester tester) async {
    final searchController = TextEditingController();
    final onChanged = (String value) {};

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SearchBarWidget(
          searchController: searchController,
          onChanged: onChanged,
        ),
      ),
    ));

    expect(find.text('What are you looking for?'), findsOneWidget);
  });

  testWidgets('SearchBarWidget calls onChanged when text is entered',
      (WidgetTester tester) async {
    final searchController = TextEditingController();
    String changedValue = '';
    final onChanged = (String value) {
      changedValue = value;
    };

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SearchBarWidget(
          searchController: searchController,
          onChanged: onChanged,
        ),
      ),
    ));

    await tester.enterText(find.byType(TextField), 'test');
    expect(changedValue, 'test');
  });

  testWidgets('SearchBarWidget has a search icon', (WidgetTester tester) async {
    final searchController = TextEditingController();
    final onChanged = (String value) {};

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SearchBarWidget(
          searchController: searchController,
          onChanged: onChanged,
        ),
      ),
    ));

    expect(find.byIcon(Icons.search), findsOneWidget);
  });
}
