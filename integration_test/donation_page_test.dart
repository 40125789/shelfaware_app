import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shelfaware_app/components/donation_card.dart';
import 'package:shelfaware_app/components/user_donation_map_widget.dart';
import 'package:shelfaware_app/pages/donation_detail_page.dart';
import 'package:shelfaware_app/pages/donations_page.dart';
import 'package:shelfaware_app/pages/home_page.dart';
import 'package:shelfaware_app/services/donation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelfaware_app/services/food_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(fileName: "assets/.env");
    await Permission.location.request(); // Request location permission
    await Permission.camera.request(); // Request camera permission
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

    testWidgets('Navigate to Donations tab and display donation items',
        (WidgetTester tester) async {
      // Build the HomePage widget with necessary providers
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

      // Wait for HomePage to settle
      await tester.pumpAndSettle();

      // Verify that the HomePage is displayed
      expect(find.byType(HomePage), findsOneWidget);

      // Initially, verify the default AppBar text for Home (index 0)
      expect(
          find.descendant(of: find.byType(AppBar), matching: find.text('Home')),
          findsOneWidget);

      // Tap on the 'Donations' tab (index 2) to navigate to Donations page
      await tester
          .tap(find.byIcon(Icons.food_bank)); // Icon for 'Donations' tab
      await tester.pumpAndSettle();

      // Verify that the AppBar text changes to 'Donations'
      expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text('Donations'),
          ),
          findsOneWidget);

      // Verify DonationPage is displayed
      expect(find.byType(DonationsPage), findsOneWidget);

      // Check if donation items are displayed (assumes donation items are represented by DonationCard widgets)
      expect(find.byType(DonationCard),
          findsWidgets); // Ensure there are donation cards displayed

      // Locate the first donation item and tap on it
      final donationCardFinder = find.byType(DonationCard).first;

      // Verify that a donation item is available
      expect(donationCardFinder, findsOneWidget);

      // Tap on the donation card to interact with it
      await tester.tap(donationCardFinder);
      await tester.pumpAndSettle();

      // Verify that tapping on the donation item takes you to the donation detail screen or changes the state

      // Verify that the DonationDetailPage displays the expected text
      expect(find.text('Product Details'), findsOneWidget);
    });

    testWidgets(
        'Filter and display donations based on user preferences in Donations page',
        (WidgetTester tester) async {
      // Build the HomePage widget with necessary providers
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

      // Wait for HomePage to settle
      await tester.pumpAndSettle();

      // Navigate to Donations tab (index 2)
      await tester.tap(find.byIcon(Icons.food_bank)); // Tap the 'Donations' tab
      await tester.pumpAndSettle();

      // Verify DonationPage is displayed
      expect(find.byType(DonationsPage), findsOneWidget);

      // Tap on the filter dropdown to apply a filter
      await tester.tap(find.text('Filter').last); // Tap the filter dropdown
      await tester.pumpAndSettle();
      await tester.tap(find.text('Newly Added').last); // Select a filter option
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply').last); // Tap the 'Apply' button
      await tester.pumpAndSettle();

      // Verify that only available donation items are displayed
      expect(find.text('New'), findsOneWidget);

      // Ensure that expired donations are not shown
      expect(find.text('Expiring Soon'), findsNothing);
    });

    testWidgets(
        'Filter and display donations based on expiring soon, shoould display no donations message',
        (WidgetTester tester) async {
      // Build the HomePage widget with necessary providers
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
      // Wait for HomePage to settle
      await tester.pumpAndSettle();

      // Navigate to Donations tab (index 2)
      await tester.tap(find.byIcon(Icons.food_bank)); // Tap the 'Donations' tab
      await tester.pumpAndSettle();

      // Verify DonationPage is displayed
      expect(find.byType(DonationsPage), findsOneWidget);

      // Tap on the filter dropdown to apply a filter
      await tester.tap(find.text('Filter').last); // Tap the filter dropdown
      await tester.pumpAndSettle();
      await tester
          .tap(find.text('Expiring Soon').last); // Select a filter option
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply').last); // Tap the 'Apply' button
      await tester.pumpAndSettle();

      // Verify that no donations are displayed
      expect(find.text('No donations match your filters!'), findsOneWidget);

      // Ensure that new donations are not shown
      expect(find.text('New'), findsNothing);
    });
  });
}
