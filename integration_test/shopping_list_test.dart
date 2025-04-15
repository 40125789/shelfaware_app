import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shelfaware_app/components/food_card.dart';
import 'package:shelfaware_app/pages/home_page.dart';
import 'package:shelfaware_app/services/donation_service.dart';
import 'package:shelfaware_app/services/food_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(fileName: ".env");
  });

  group('HomePage Integration Tests', () {
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

    Future<void> navigateToShoppingList(WidgetTester tester) async {
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
      final Finder menuButton = find.byTooltip('Open navigation menu');
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      final Finder shoppingListNavItem = find.text('Shopping List');
      await tester.tap(shoppingListNavItem);
      await tester.pumpAndSettle();
    }

    testWidgets('Navigate to Shopping List Screen',
        (WidgetTester tester) async {
      await navigateToShoppingList(tester);
      expect(find.text('Shopping List'), findsOneWidget);
    });

    testWidgets('Add a product to the Shopping List',
        (WidgetTester tester) async {
      await navigateToShoppingList(tester);
      final Finder textField = find.byType(TextField);
      await tester.enterText(textField, 'egg');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      final Finder addButton = find.byIcon(Icons.add);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      expect(find.text('egg'), findsOneWidget);
    });

  testWidgets('Mark an item as purchased', (WidgetTester tester) async {
    await navigateToShoppingList(tester);
    
    // Find the egg item in the list
    final Finder eggItem = find.ancestor(
    of: find.text('egg'),
    matching: find.byType(ListTile),
    );
    
    // Find the checkbox within the egg item
    final Finder eggCheckBox = find.descendant(
    of: eggItem,
    matching: find.byType(Checkbox),
    );
    
    // Tap the checkbox to mark as purchased
    await tester.tap(eggCheckBox);
    await tester.pumpAndSettle();
    
    // Add a delay to ensure the purchased state is updated
    await Future.delayed(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    
    // Verify the item is marked as purchased
    final purchasedText = find.text('Purchased');
    expect(purchasedText, findsOneWidget);
    
    
  });

    testWidgets('Toggle Hide Purchased Items', (WidgetTester tester) async {
      await navigateToShoppingList(tester);
      
      // Now test the toggle functionality
      final Finder toggleButton = find.byType(Switch);
      
      // Toggle to ON position
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();
      
  
      expect(find.text('egg'), findsNothing);
      // Toggle back to OFF position
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();
      expect(find.text('egg'), findsOneWidget);

      
     
    });

    testWidgets('Increase the quantity of a food item in the Shopping List',
      (WidgetTester tester) async {
      await navigateToShoppingList(tester);
      
      // Find the dropdown showing quantity "1"
      final quantityDropdown = find.byType(DropdownButton<int>);
      expect(quantityDropdown, findsOneWidget);
      
      // Open the dropdown
      await tester.tap(quantityDropdown);
      await tester.pumpAndSettle();
      
      // Select quantity "2" from the dropdown
      await tester.tap(find.text('2').last);
      await tester.pumpAndSettle();
      
      // Verify the quantity has been updated to "2"
      expect(find.descendant(
      of: quantityDropdown,
      matching: find.text('2'),
      ), findsOneWidget);
    });

    testWidgets('Delete an item from the Shopping List',
        (WidgetTester tester) async {
      await navigateToShoppingList(tester);
      final Finder deleteButton = find.byIcon(Icons.delete);
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();
      expect(find.text('egg'), findsNothing);
    });

    //Test for adding a food item from inventory to shopping list
    testWidgets('Add a food item from inventory to Shopping List',
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

      // Expand all food categories to locate "Apple"
      final expandableTileFinder = find.byType(ExpansionTile);
      for (var i = 0; i < expandableTileFinder.evaluate().length; i++) {
        await tester.tap(expandableTileFinder.at(i));
        await tester.pumpAndSettle();
      }

      // Locate the correct food item card
      final cardFinder = find.ancestor(
        of: find.text('apple'),
        matching: find.byType(Card),
      );

      // Tap the popup menu inside the specific card
      final popupMenuFinder = find.descendant(
        of: cardFinder,
        matching: find.byIcon(Icons.more_vert),
      );
      await tester.tap(popupMenuFinder);
      await tester.pumpAndSettle();

      // Tap the "shopping list" option
      await tester.tap(find.text('+ Shopping List'));
      await tester.pumpAndSettle();

      // Verify that "Apple" is added to the Shopping List, navigate to the Shopping List page
      await navigateToShoppingList(tester);
      expect(find.text('apple'), findsOneWidget);
    });
  });
  
}
