import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shelfaware_app/pages/home_page.dart';
import 'package:shelfaware_app/pages/my_donations_page.dart';
import 'package:shelfaware_app/services/donation_service.dart';
import 'package:shelfaware_app/services/food_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Firebase.initializeApp();
    await dotenv.load(fileName: "assets/.env");
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

    testWidgets('Test leave review for picked up donation', (tester) async {
      // Navigate to the "Manage Donations" page
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

      await tester.pumpAndSettle();

      // Open the side drawer
      final Finder menuButton = find.byTooltip('Open navigation menu');
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Tap on "Manage Donations"
      final Finder manageDonationsNavItem = find.text('Manage Donations');
      await tester.tap(manageDonationsNavItem);
      await tester.pumpAndSettle();

      // Tap on the "Sent Requests" tab
      final Finder sentRequestsTab = find.text('Sent Requests');
      await tester.tap(sentRequestsTab);
      await tester.pumpAndSettle();

      // Open the filter dropdown
      final Finder dropdown = find.byType(DropdownButton<String>);
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Select "Picked Up" from the dropdown
      final Finder pickedUpOption = find.descendant(
        of: find.byType(DropdownMenuItem<String>),
        matching: find.text('Picked Up'),
      );
      await tester.tap(pickedUpOption);
      await tester.pumpAndSettle();

      // Find and tap on the first available donation expansion tile
      await tester.pumpAndSettle();
      final Finder anyDonationTile = find.byType(ExpansionTile).at(2);
      expect(anyDonationTile, findsOneWidget);
      await tester.tap(anyDonationTile);
      await tester.pumpAndSettle();

      // Find and tap on the "Leave a Review" button
      final Finder leaveReviewButton = find.text('Leave a Review');
      expect(leaveReviewButton, findsOneWidget);
      await tester.tap(leaveReviewButton);
      await tester.pumpAndSettle();

      //the review page should be displayed
      expect(find.text('Leave a Review'), findsOneWidget);
      // Enter a review in the text field
      // Wait for the review page to fully load
      await tester.pumpAndSettle(Duration(seconds: 2));

      // Find all star rating widgets - try both common star icons
      final Finder starRatings = find.byIcon(Icons.star).evaluate().isEmpty
          ? find.byIcon(Icons.star_outline)
          : find.byIcon(Icons.star);
      expect(starRatings, findsWidgets);

      // Tap the 5th star for each rating category (giving 5 stars)
      final int starsPerRating = 5;
      for (int i = 0; i < 3; i++) {
        final int starIndex = (i * starsPerRating) + 4;
        if (starIndex < starRatings.evaluate().length) {
          await tester.tap(starRatings.at(starIndex));
          await tester.pumpAndSettle();
        }
      }

      // Enter review text
      final Finder reviewTextField = find.byType(TextField);
      await tester.enterText(reviewTextField, 'Great experience! The food was fresh and delicious.');
      await tester.pumpAndSettle();
      
      // Close the keyboard
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();


      // Tap "Submit Review"
      final Finder submitButton = find.text('Submit Review');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify success message appears
      expect(find.text('Thanks for your review!'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('Test withdraw/delete a donation request', (tester) async {
      // Navigate to the "Manage Donations" page
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

      await tester.pumpAndSettle();

      // Open the side drawer
      final Finder menuButton = find.byTooltip('Open navigation menu');
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Tap on "Manage Donations"
      final Finder manageDonationsNavItem = find.text('Manage Donations');
      await tester.tap(manageDonationsNavItem);
      await tester.pumpAndSettle();

      // Tap on the "Sent Requests" tab
      final Finder sentRequestsTab = find.text('Sent Requests');
      await tester.tap(sentRequestsTab);
      await tester.pumpAndSettle();

      // Wait for widget tree to stabilize
      await tester.pumpAndSettle(Duration(seconds: 2));
      
      // Open the filter dropdown
      final Finder dropdown = find.byType(DropdownButton<String>);
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Select "Available" from the dropdown
      final Finder availableOption = find.descendant(
        of: find.byType(DropdownMenuItem<String>),
        matching: find.text('Accepted'),
      ).first;
      await tester.tap(availableOption);
      await tester.pumpAndSettle(Duration(seconds: 1));

      // Find and tap on the first available donation expansion tile
      await tester.pumpAndSettle();
      final Finder anyDonationTile = find.byType(ExpansionTile).first;
      expect(anyDonationTile, findsOneWidget);
      await tester.tap(anyDonationTile);
      await tester.pumpAndSettle();

      // Find and tap on the "Withdraw Request" button
      final Finder withdrawRequestButton = find.text('Withdraw Request');
      expect(withdrawRequestButton, findsOneWidget);
      await tester.tap(withdrawRequestButton);
      await tester.pumpAndSettle();

      // Confirm the deletion in the dialog
      final Finder confirmButton = find.text('Withdraw');
      expect(confirmButton, findsOneWidget);
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();
      // Verify the donation is no longer in the list
      expect(find.text('Banana Bread'), findsNothing);

      // Add delay before test completion
      await Future.delayed(const Duration(seconds: 1));
      });
      });
    }
