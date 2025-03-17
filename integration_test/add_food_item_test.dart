import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shelfaware_app/pages/home_page.dart';
import 'package:shelfaware_app/services/donation_service.dart';
import 'package:shelfaware_app/services/food_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(fileName: "assets/.env");
  });

  group('HomePage Integration Tests', () {
    late FirebaseAuth auth;
    late FirebaseFirestore firestore;
    late DonationService donationService;
    late FoodService foodService;
    late User user;

    setUp(() async {
      // Initialize Firebase
      await Firebase.initializeApp();
      auth = FirebaseAuth.instance;
      await auth.signInWithEmailAndPassword(
          email: 'smyth668@hotmail.com', password: 'Ya9maha8@');
      firestore = FirebaseFirestore.instance;
      donationService = DonationService();
      foodService = FoodService();
      user = auth.currentUser!;
    });

    testWidgets('Tap on Plus button and display Add Food Item form',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              appBarTheme: AppBarTheme(
                backgroundColor: Colors
                    .green, // Ensure this is the color from your main.dart
              ),
            ),
            home: HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Locate the "Plus" button (FAB)
      final fabFinder = find.byIcon(Icons.add);
      expect(fabFinder, findsOneWidget);

      // Tap on the Plus button to open the Add Food Item form
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      // Verify that the Add Food Item form is displayed
      expect(find.byType(TextFormField), findsWidgets);
      expect(find.text('Add Food Item'), findsOneWidget);
    });

    testWidgets('Fill in the form with required fields and submit',
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

      // Tap the Plus button to open the Add Food Item form
      final fabFinder = find.byIcon(Icons.add);
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      // Fill in the product name
      final productNameField =
          find.widgetWithText(TextFormField, 'Product Name');
      await tester.enterText(productNameField, 'App');
      expect(find.text('App'), findsOneWidget);
      await tester.pumpAndSettle();

      // Simulate pressing "Done" on the keyboard to dismiss it
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Dismiss any food suggestions dropdown if it appears by tapping on the "Apple" suggestion
      final appleSuggestion = find.text('Apple'); // This is the dropdown item
      await tester.tap(appleSuggestion);
      await tester.pumpAndSettle();

      // Ensure "Apple" is in the product name field
      expect(find.text('Apple'), findsOneWidget);
      await tester.pumpAndSettle();

      // Tap on the expiry date field to open the date picker
      final expiryDateField = find.widgetWithText(TextFormField, 'Expiry Date');
      await tester.ensureVisible(expiryDateField); // Ensure visibility
      await tester.tap(expiryDateField, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Simulate selecting a day in the date picker
      final dayFinder = find.text('18');
      await tester.tap(dayFinder);
      await tester.pumpAndSettle();

      // Now simulate pressing the "OK" button on the date picker
      final okButton = find.text('OK');
      await tester.tap(okButton);
      await tester.pumpAndSettle();

      // Verify that the selected date is displayed in the expiry date field
      expect(find.text('18/03/2025'), findsOneWidget);

      // Tap on the category dropdown and choose "fruits"
      final categoryDropdown =
          find.widgetWithText(DropdownButton<String>, 'All');
      await tester.tap(categoryDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('fruits').last);
      await tester.pumpAndSettle();
      expect(find.text('fruits'), findsOneWidget);

      // Adjust quantity using the plus and minus buttons
      final plusButton = find.byIcon(Icons.add);
      final minusButton = find.byIcon(Icons.remove);

      // Tap the Plus button twice to increase the quantity
      await tester.tap(plusButton);
      await tester.pumpAndSettle();
      await tester.tap(plusButton);
      await tester.pumpAndSettle();

      // Tap the Minus button to decrease the quantity
      await tester.tap(minusButton);
      await tester.pumpAndSettle();

      // Verify that the quantity is updated
      expect(find.text('2'), findsOneWidget);

      // Tap the Submit button to submit the form
      final submitButton = find.text('Save Food Item');
      await tester.ensureVisible(submitButton); // Ensure visibility
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Allow any UI transitions and snackbar to show up
      await tester.pumpAndSettle();

      // Verify that the snackbar appears with the success message
      expect(find.text('Food item saved successfully!'), findsOneWidget);
    });

    testWidgets('Verify the added food item in the list',
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
      expect(find.text('Apple'), findsOneWidget);
    });
  });
}
