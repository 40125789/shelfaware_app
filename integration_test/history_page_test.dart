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

    testWidgets('Tap on Sort by Newest First, Display March',
        (WidgetTester tester) async {
      await navigateToHistoryPage(tester);

      // Tap on the dropdown to change sort option
      final Finder dropdownButton = find.byType(DropdownButton<String>);
      await tester.tap(dropdownButton);
      await tester.pumpAndSettle();

      // Select 'Newest First' option
      final Finder newestFirstOption = find.descendant(
        of: dropdownButton,
        matching: find.text('Sort by Newest'),
      );
      await tester.tap(newestFirstOption);
      await tester.pumpAndSettle();

      // Expect the sorted data to show March first
      expect(find.text('March 2025'), findsOneWidget);
    });

    testWidgets('Tap on Sort by Oldest First, Display November',
        (WidgetTester tester) async {
      await navigateToHistoryPage(tester);

      // Tap on the dropdown to change sort option
      final Finder dropdownButton = find.byType(DropdownButton<String>);
      await tester.tap(dropdownButton);
      await tester.pumpAndSettle(); // Ensure the dropdown options are rendered

      // Ensure the "Sort by Oldest" option exists in the dropdown
      final Finder oldestFirstOption = find.text('Sort by Oldest');
      expect(oldestFirstOption, findsOneWidget); // Verify the option is found

      // Tap on 'Oldest First' option
      await tester.tap(oldestFirstOption);
      await tester.pumpAndSettle();

      // Expect the sorted data to show November first
      expect(find.text('November 2024'), findsOneWidget);
    });

// Test to verify the "Show Discarded" option in the dropdown
    testWidgets('Tap on Show Discarded, Display Discarded Items',
        (WidgetTester tester) async {
      await navigateToHistoryPage(tester);

      // Tap on the dropdown to change filter option
      final Finder dropdownButton = find.byType(DropdownButton<String>);
      await tester.tap(dropdownButton);
      await tester.pumpAndSettle();

      // Ensure the "Show Discarded" option exists in the dropdown
      final Finder showDiscardedOption = find.text('Show Discarded');
      expect(showDiscardedOption, findsOneWidget); // Verify the option is found

      // Tap on 'Show Discarded' option
      await tester.tap(showDiscardedOption);
      await tester.pumpAndSettle();

      // Expect multiple instances of "Discarded" in the list
      final Finder discardedText = find.text('Discarded');
      expect(discardedText, findsWidgets); // Expect at least one "Discarded"
    });

    testWidgets('Tap on Show Consumed, Display Consumed Items',
        (WidgetTester tester) async {
      await navigateToHistoryPage(tester);

      // Tap on the dropdown to change filter option
      final Finder dropdownButton = find.byType(DropdownButton<String>);
      await tester.tap(dropdownButton);
      await tester.pumpAndSettle();

      // Ensure the "Show Consumed" option exists in the dropdown
      final Finder showConsumedOption = find.text('Show Consumed');
      expect(showConsumedOption, findsOneWidget); // Verify the option is found

      // Tap on 'Show Consumed' option
      await tester.tap(showConsumedOption);
      await tester.pumpAndSettle();

      // Expect multiple instances of "Consumed" in the list
      final Finder consumedText = find.text('Consumed');
      expect(consumedText, findsWidgets); // Expect at least one "Consumed"
    });
  });
}
