import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shelfaware_app/components/food_history_item_card.dart';
import 'package:shelfaware_app/screens/add_food_item.dart';
import 'package:shelfaware_app/screens/home_page.dart';
import 'package:shelfaware_app/services/donation_service.dart';
import 'package:shelfaware_app/services/food_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(fileName: ".env");
  });

  group('History Page Integration Tests', () {
    late FirebaseAuth auth;
    late FirebaseFirestore firestore;
    late DonationService donationService;
    late FoodService foodService;
    late User user;

     setUp(() async {
      await Firebase.initializeApp();
      auth = FirebaseAuth.instance;
      final testEmail = dotenv.env['TEST_EMAIL']!;
      final testPassword = dotenv.env['TEST_PASSWORD']!;
      await auth.signInWithEmailAndPassword(
          email: testEmail, password: testPassword);
      firestore = FirebaseFirestore.instance;
      donationService = DonationService();
      foodService = FoodService();
      user = auth.currentUser!;
    });

    // Function to navigate to the History page from the Home page
    Future<void> navigateToHistoryPage(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.green,
              ),
            ),
            home: HomePage(),
          ),
        ),
      );

      // Open the side drawer
      final Finder menuButton = find.byTooltip('Open navigation menu');
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Tap on the "History" navigation item in the side drawer
      final Finder historyNavItem = find.text('History');
      await tester.tap(historyNavItem);
      await tester.pumpAndSettle();
    }

    testWidgets('Navigate to History Page', (WidgetTester tester) async {
      await navigateToHistoryPage(tester);
      expect(find.text('Food History'), findsOneWidget);
    });

    testWidgets('Recreate food item from history', (WidgetTester tester) async {
      await navigateToHistoryPage(tester);

      // Enable recreate mode
      await tester.tap(find.text("RECREATE"));
      await tester.pumpAndSettle();

      // Find the exact ListTile containing "orange x 1"
      final Finder foodHistoryItem = find.descendant(
        of: find.byType(ListTile),
        matching: find.text('Seeded brioche buns x 1'),
      );

      expect(foodHistoryItem, findsOneWidget,
          reason: "Failed to find unique ListTile for 'orange x 1'");

      // Find the correct checkbox inside the found ListTile
      final Finder elderCheckBox = find.descendant(
        of: find.ancestor(of: foodHistoryItem,matching: find.byType(ListTile)),
        matching: find.byType(Checkbox),
      );

      await tester.tap(elderCheckBox);
      await tester.pump(Duration(milliseconds: 500)); // Allow UI update

      // Verify the selected item count text appears once the checkbox is ticked
      expect(find.text("1 Items selected"), findsOneWidget);

      // Tap the recreate button
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // Verify navigation to AddFoodItem page
      expect(find.byType(AddFoodItem), findsOneWidget);
      expect(find.textContaining("Seeded brioche buns"), findsOneWidget);
      expect(find.text("01/05/2025"), findsOneWidget);  
     

      await tester.pumpAndSettle();

      // Save the recreated food item
      await tester.tap(find.text('Save Food Item'));
      await tester.pumpAndSettle();

      // Verify the food item is saved
      expect(find.text("Food item saved successfully!"), findsOneWidget);
    });

//verify the newly recreated item has been added to inventory on home page
    testWidgets(
        'Verify the item has been added to the inventory on the Home Page',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.green,
              ),
            ),
            home: HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the added food item in the list
      final expandableTileFinder = find.byType(ExpansionTile);
      expect(expandableTileFinder, findsWidgets);

      // Tap on all expandable tiles to expand them
      for (var i = 0; i < expandableTileFinder.evaluate().length; i++) {
        await tester.tap(expandableTileFinder.at(i));
        await tester.pumpAndSettle();
      }

      // Check for the added food item details
      expect(find.text('Seeded brioche buns'), findsOneWidget);
    });
  });
}
