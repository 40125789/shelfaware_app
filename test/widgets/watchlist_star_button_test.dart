import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfaware_app/components/watchlist_star_button.dart';

void main() {
  group('WatchlistToggleButton', () {
    testWidgets('renders star icon when in watchlist',
        (WidgetTester tester) async {
      bool isInWatchlist = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WatchlistToggleButton(
              isInWatchlist: isInWatchlist,
              onToggle: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.star_border), findsNothing);
    });

    testWidgets('renders star_border icon when not in watchlist',
        (WidgetTester tester) async {
      bool isInWatchlist = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WatchlistToggleButton(
              isInWatchlist: isInWatchlist,
              onToggle: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star_border), findsOneWidget);
      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('calls onToggle callback when tapped',
        (WidgetTester tester) async {
      bool isInWatchlist = false;
      bool callbackCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WatchlistToggleButton(
              isInWatchlist: isInWatchlist,
              onToggle: () {
                callbackCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(callbackCalled, true);
    });

    testWidgets('has correct size and decoration', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WatchlistToggleButton(
              isInWatchlist: false,
              onToggle: () {},
            ),
          ),
        ),
      );

      final containerFinder = find.byType(Container).first;
      final Container container = tester.widget(containerFinder);

      expect(container.constraints?.maxWidth, 40);
      expect(container.constraints?.maxHeight, 40);

      final BoxDecoration decoration = container.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
    });
  });
}
