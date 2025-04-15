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
    await dotenv.load(fileName: ".env");
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

    testWidgets('Test accepting a donation and marking it as picked up',
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
      final Finder bananaDonation = find.text('apple pie');
      await tester.tap(bananaDonation);
      await tester.pumpAndSettle();

      //expect to see "Donation Deatils" page
      expect(find.text('Donation Details'), findsOneWidget);
      // Step 2: Accept the donation
      final Finder request = find.textContaining('Requested by');
      expect(request, findsOneWidget,
          reason: 'The text "Requested By" was not found in the widget tree.');
      await tester.tap(request);
      await tester.pumpAndSettle();

      // Find the accept button and tap it
      final Finder acceptButton = find.text('Accept');
      await tester.tap(acceptButton);
      await tester.pumpAndSettle();

      // Verify that the donation status is updated to "Picked Up"
      final Finder pickedUpStatus = find.text('Reserved');
      expect(pickedUpStatus, findsOneWidget);

      // Step 3: Mark the donation as picked up
      // Find the "Mark as Picked Up" button and tap it
      final Finder markAsPickedUpButton = find.text('Mark as Picked Up');
      await tester.tap(markAsPickedUpButton);
      await tester.pumpAndSettle();

      // Verify that the donation status is updated to "Picked Up"
      final Finder pickedUpStatusAfter = find.text('Picked Up');
      expect(pickedUpStatusAfter, findsOneWidget);
      await tester.pumpAndSettle();
    });
  });
}
