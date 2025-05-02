import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shelfaware_app/screens/home_page.dart';
import 'package:shelfaware_app/screens/my_donations_page.dart';
import 'package:shelfaware_app/services/donation_service.dart';
import 'package:shelfaware_app/services/food_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(fileName: ".env");
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

    testWidgets('Donate Banana - Fill in details, take photo, and submit',
        (WidgetTester tester) async {
      // Wrap your widget in a provider that overrides ImagePicker with your mock, if needed.
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

      // Wait for the widget to render
      await tester.pumpAndSettle();

      // Expand categories and find the correct food item card for "Banana"
      await tester.tap(find.text('Expired'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Expiring Soon'));
      await tester.pumpAndSettle();

      // Locate the card for "Banana"
      final cardFinder = find.ancestor(
        of: find.text('banana'), // Case-insensitive search
        matching: find.byType(Card),
      );

      // Tap the popup menu inside the specific card
      final popupMenuFinder = find.descendant(
        of: cardFinder,
        matching: find.byIcon(Icons.more_vert),
      );
      await tester.tap(popupMenuFinder);
      await tester.pumpAndSettle();

      // Tap the "Donate" option
      await tester.tap(find.text('Donate'));
      await tester.pumpAndSettle();

      // Verify that the confirmation dialog appears
      expect(find.text('Confirm Donation'), findsOneWidget);

      // Tap the "Donate" button on the confirmation dialog
      await tester.tap(find.text('Donate'));
      await tester.pumpAndSettle();

      // Wait for the bottom modal sheet to be fully rendered
      await tester.pumpAndSettle(); // Wait for any animations to complete

      // Add an extra wait to ensure that the modal sheet has had time to appear
      await tester
          .pumpAndSettle(Duration(seconds: 2)); // Add more time if necessary

      // Verify that the form fields in the modal sheet are visible
      expect(find.text('Pickup Times'), findsOneWidget);
      expect(find.text('Pickup Instructions'), findsOneWidget);

      // Fill in Pickup Times
      final pickupTimeField =
          find.widgetWithText(TextFormField, 'Pickup Times');
      await tester.enterText(pickupTimeField, '10:00 AM - 12:00 PM');
      expect(find.text('10:00 AM - 12:00 PM'), findsOneWidget);
      await tester.pumpAndSettle();

      // Fill in Pickup Instructions
      final pickupInstructionsField =
          find.widgetWithText(TextFormField, 'Pickup Instructions');
      await tester.enterText(
          pickupInstructionsField, 'Ring the doorbell upon arrival.');
      expect(find.text('Ring the doorbell upon arrival.'), findsOneWidget);
      await tester.pumpAndSettle();

      // Tap the "Take Photo" button inside the DonationPhotoForm modal sheet
      final takePhotoButton = find.text('Take Photo');
      await tester.tap(takePhotoButton);
      await tester.pumpAndSettle();

      // At this point, the camera should open on the  device.
      // Manually interact with the camera to take a photo.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      await tester.pumpAndSettle(
          Duration(seconds: 7)); // Adjust as needed for camera interaction.

      // Scroll to submit button
      final modalScrollable = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(Scrollable),
      );

      await tester.scrollUntilVisible(
        find.text('Submit Donation'),
        100, // Scroll amount per iteration
        scrollable: modalScrollable.first,
        maxScrolls: 2,
      );

      // Proceed with the form submission
      final submitButton = find.text('Submit Donation');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Wait until the "Donation added successfully." text appears
      final snackBarTextFinder = find.text('Donation added successfully.');
      while (snackBarTextFinder.evaluate().isEmpty) {
        await tester.pump();
      }

      expect(snackBarTextFinder, findsOneWidget);

      // Wait for Snackbar to disappear (if it auto-dismisses after a while)
      await tester
          .pumpAndSettle(Duration(seconds: 2)); // Adjust this delay if needed.
    });

    testWidgets(
        'Navigate to Manage Donations to verify donation has been added',
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

      // Open the side drawer
      final Finder menuButton = find.byTooltip('Open navigation menu');
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Tap on the "Manage Donations" navigation item in the side drawer
      final Finder manageDonationsNavItem = find.text('Manage Donations');
      await tester.tap(manageDonationsNavItem);
      await tester.pumpAndSettle();

      // Step 2: Wait until the "Manage Donations" page is displayed
      await tester.pumpAndSettle();
      expect(find.text('Manage Donations'), findsOneWidget);

      await tester.pumpAndSettle();

      // Step 2: Wait until the "Manage Donations" page is displayed
      expect(find.text('Manage Donations'), findsOneWidget);

      // Step 3: Wait until the "All" dropdown is displayed and then tap it to filter donations
      await tester.pumpAndSettle();
      expect(find.text('All'), findsOneWidget);
      final Finder allDropdown = find.text('All');
      await tester.tap(allDropdown);
      await tester.pumpAndSettle();

      // Step 4: Select "Available" from the dropdown options
      final Finder availableOption = find.text('Available');
      await tester.tap(availableOption);
      await tester.pumpAndSettle();

      // Step 5: Verify that the "Banana" donation with status "Available" is displayed
      final Finder bananaDonation = find.text('banana');
      expect(bananaDonation, findsOneWidget);
    });
  });
}
