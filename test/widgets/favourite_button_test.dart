import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfaware_app/components/favourite_button.dart';

void main() {
  testWidgets('FavouriteButton displays correct icon when not favourite',
      (WidgetTester tester) async {
    bool isFavourite = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FavouriteButton(
            isFavourite: isFavourite,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsNothing);
  });

  testWidgets('FavouriteButton displays correct icon when favourite',
      (WidgetTester tester) async {
    bool isFavourite = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FavouriteButton(
            isFavourite: isFavourite,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsNothing);
  });

  testWidgets('FavouriteButton calls onPressed when tapped',
      (WidgetTester tester) async {
    bool isFavourite = false;
    bool wasPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FavouriteButton(
            isFavourite: isFavourite,
            onPressed: () {
              wasPressed = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(IconButton));
    await tester.pump();

    expect(wasPressed, isTrue);
  });
}
