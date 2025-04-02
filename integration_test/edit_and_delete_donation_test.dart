import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shelfaware_app/pages/home_page.dart';
import 'package:shelfaware_app/pages/my_donations_page.dart';
import 'package:shelfaware_app/services/donation_service.dart';
import 'package:shelfaware_app/services/food_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Firebase.initializeApp();
    await dotenv.load(fileName: "assets/.env");
    await Permission.storage.request(); // Request storage permission
    await Permission.camera.request(); // Request camera permission
    await Permission.location.request(); // Request location permission
  });

  group('Manage Donations Integration Tests', () {
    late FirebaseAuth auth;
    late FirebaseFirestore firestore;
    late FirebaseStorage storage;
    late DonationService donationService;
    late FoodService foodService;
    late User user;

    setUp(() async {
      auth = FirebaseAuth.instance;
      final testEmail = dotenv.env['TEST_EMAIL']!;
      final testPassword = dotenv.env['TEST_PASSWORD']!;
      await auth.signInWithEmailAndPassword(
          email: testEmail, password: testPassword);
      auth = FirebaseAuth.instance;
      firestore = FirebaseFirestore.instance;
      storage = FirebaseStorage.instance;
      donationService = DonationService();
      foodService = FoodService();
      user = auth.currentUser!;
    });

    testWidgets('Test Editing Pickup Instructions for a donation',
        (WidgetTester tester) async {
      // Step 1: Navigate to the "Manage Donations" page
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            routes: {
              '/myDonations': (context) => MyDonationsPage(userId: user.uid),
            },
            theme: ThemeData(
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.green,
              ),
            ),
            home: HomePage(),
          ),
        ),
      );

      // Wait for the widget to render
      await tester.pumpAndSettle();

      // Open the side drawer
      final Finder menuButton = find.byTooltip('Open navigation menu');
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Tap on "Manage Donations"
      final Finder manageDonationsNavItem = find.text('Manage Donations');
      await tester.tap(manageDonationsNavItem);
      await tester.pumpAndSettle();

      // Ensure "Manage Donations" page is displayed
      expect(find.text('Manage Donations'), findsOneWidget);

      // Find the dropdown and tap it
      final Finder dropdown = find.text('All');
      await tester.ensureVisible(dropdown); // Ensure dropdown is visible
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Select "Available" from dropdown
      final Finder availableOption = find.text('Available');
      await tester.tap(availableOption);
      await tester.pumpAndSettle();

      // Verify that the "Banana" donation with status "Available" is displayed
      final Finder bananaDonation = find.text('banana');
      await tester.tap(bananaDonation);
      await tester.pumpAndSettle();

      //expect to see "Donation Deatils" page
      expect(find.text('Donation Details'), findsOneWidget);

      //find the edit button
      final Finder editButton = find.text('Edit Pickup Details');
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      //edit pickup details
      final Finder pickupDateField =
          find.widgetWithText(TextField, 'Pickup Times');
      //clear the field
      (pickupDateField.evaluate().single.widget as TextField)
          .controller
          ?.clear();
      await tester.enterText(pickupDateField, '6-9pm');
      await tester.pumpAndSettle();

      //add pickup instructions
      final Finder pickupInstructionsField =
          find.widgetWithText(TextField, 'Pickup Instructions');
      await tester.enterText(
          pickupInstructionsField, 'Please ring the doorbell');
      await tester.pumpAndSettle();

      //save the changes
      final Finder saveButton = find.text('Save');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Wait for the snackbar to appear
      await tester.pump(const Duration(seconds: 2));

      // Saved snackbar should appear
      expect(find.text('6-9pm'), findsOneWidget);
      expect(find.text('Please ring the doorbell'), findsOneWidget);
    });

    testWidgets('Test Deleting a donation', (WidgetTester tester) async {
      // Step 1: Navigate to the "Manage Donations" page
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            routes: {
              '/myDonations': (context) => MyDonationsPage(userId: user.uid),
            },
            theme: ThemeData(
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.green,
              ),
            ),
            home: HomePage(),
          ),
        ),
      );

      // Wait for the widget to render
      await tester.pumpAndSettle();

      // Open the side drawer
      final Finder menuButton = find.byTooltip('Open navigation menu');
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Tap on "Manage Donations"
      final Finder manageDonationsNavItem = find.text('Manage Donations');
      await tester.tap(manageDonationsNavItem);
      await tester.pumpAndSettle();

      // Ensure "Manage Donations" page is displayed
      expect(find.text('Manage Donations'), findsOneWidget);

      // Find the dropdown and tap it
      final Finder dropdown = find.text('All');
      await tester.ensureVisible(dropdown); // Ensure dropdown is visible
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Select "Available" from dropdown
      final Finder availableOption = find.text('Available');
      await tester.tap(availableOption);
      await tester.pumpAndSettle();

      // Verify that the "Banana" donation with status "Available" is displayed
      final Finder bananaDonation = find.text('banana');
      await tester.tap(bananaDonation);
      await tester.pumpAndSettle();

      // Expect to see "Donation Details" page
      expect(find.text('Donation Details'), findsOneWidget);

      // Find the delete button
      final Finder deleteButton = find.text('Delete Donation');
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Confirm deletion
      final Finder confirmDeletionDialog = find.text('Confirm Deletion');
      expect(confirmDeletionDialog, findsOneWidget);
      final Finder confirmDeleteButton = find.text('Delete');
      await tester.tap(confirmDeleteButton);
      await tester.pumpAndSettle();

      // Make sure the donation is deleted
      expect(find.text('banana'), findsNothing);
      await tester.pump(const Duration(seconds: 2));
    });
  });
}
