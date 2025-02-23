import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfaware_app/components/matching_ingredients_text.dart';

void main() {
  testWidgets('MatchingIngredientsText displays correct text',
      (WidgetTester tester) async {
    const matchingCount = 3;
    const totalCount = 5;

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MatchingIngredientsText(
            matchingCount: matchingCount,
            totalCount: totalCount,
          ),
        ),
      ),
    );

    expect(find.text('You have $matchingCount out of $totalCount ingredients'),
        findsOneWidget);
  });

  testWidgets('MatchingIngredientsText has correct style',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MatchingIngredientsText(
            matchingCount: 3,
            totalCount: 5,
          ),
        ),
      ),
    );

    final textWidget =
        tester.widget<Text>(find.text('You have 3 out of 5 ingredients'));
    expect(textWidget.style?.fontSize, 14);
    expect(textWidget.style?.color, Colors.grey[700]);
  });
}
