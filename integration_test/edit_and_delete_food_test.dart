import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shelfaware_app/components/food_list_view.dart';
import 'package:shelfaware_app/screens/home_page.dart';
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

   testWidgets('Edit food item - Change name to Apple Cake and quantity to 1', (WidgetTester tester) async {
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
    of: find.text('Apple'),
    matching: find.byType(Card),
  );

  // Tap the popup menu inside the specific card
  final popupMenuFinder = find.descendant(
    of: cardFinder,
    matching: find.byIcon(Icons.more_vert),
  );
  await tester.tap(popupMenuFinder);
  await tester.pumpAndSettle();

  // Tap the "Edit" option
  await tester.tap(find.text('Edit'));
  await tester.pumpAndSettle();

  // Verify that the "Edit Food Item" screen is displayed
  expect(find.text('Edit Food Item'), findsOneWidget);

  // Fill in the product name
  final productNameField = find.widgetWithText(TextFormField, 'Product Name');
  await tester.enterText(productNameField, 'Apple C');
  expect(find.text('Apple C'), findsOneWidget);
  await tester.pumpAndSettle();

  // Simulate pressing "Done" on the keyboard
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();

  // Dismiss food suggestions dropdown if it appears
  final appleSuggestion = find.text('Apple Cake');
  await tester.tap(appleSuggestion);
  await tester.pumpAndSettle();

  // Ensure "Apple Cake" is in the product name field
  expect(find.text('Apple Cake'), findsOneWidget);
  await tester.pumpAndSettle();

  // Adjust quantity using the minus button to set it to 1
  final minusButton = find.byIcon(Icons.remove);
  await tester.tap(minusButton);
  await tester.pumpAndSettle();

  // Verify that the quantity is updated to 1
  expect(find.text('1'), findsOneWidget);

  // Tap the Submit button to save the changes
  final submitButton = find.text('Save Food Item');
  await tester.ensureVisible(submitButton);
  await tester.tap(submitButton);
  await tester.pumpAndSettle();

  // Verify success message appears
  expect(find.text('Food Item updated successfully!'), findsOneWidget);
  await tester.pumpAndSettle();

  // Verify the updated food item in the list
  expect(find.text('Apple Cake'), findsOneWidget);

});

testWidgets('Delete Apple Cake and verify it is removed', (WidgetTester tester) async {
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

        // Expand categories
      await tester.tap(find.text('Expired'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Expiring Soon'));
      await tester.pumpAndSettle();


  // Locate the correct food item card for "Apple Cake"
  final cardFinder = find.ancestor(
    of: find.text('Apple Cake'),
    matching: find.byType(Card),
  );

  // Tap the popup menu inside the specific card
  final popupMenuFinder = find.descendant(
    of: cardFinder,
    matching: find.byIcon(Icons.more_vert),
  );
  await tester.tap(popupMenuFinder);
  await tester.pumpAndSettle();

  // Tap the "Delete" option
  await tester.tap(find.text('Delete'));
  await tester.pumpAndSettle();

  // Confirm deletion by tapping "Delete" in the confirmation dialog
  final confirmDeleteButton = find.text('Delete');
  await tester.tap(confirmDeleteButton);
  await tester.pumpAndSettle();

  // Verify that "Apple Cake" is removed from the list
  expect(find.text('Apple Cake'), findsNothing);
});


  });
}