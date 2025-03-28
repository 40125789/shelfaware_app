import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shelfaware_app/components/donation_card.dart';
import 'package:shelfaware_app/pages/donations_page.dart';
import 'package:shelfaware_app/pages/home_page.dart';
import 'package:shelfaware_app/pages/my_donations_page.dart';
import 'package:shelfaware_app/services/donation_service.dart';
import 'package:shelfaware_app/services/food_service.dart';
// Removing the test package as flutter_test already provides the testing functionality we need

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(fileName: "assets/.env");
    await Permission.location.request(); // Request location permission
    await Permission.camera.request(); // Request camera permission
  });

  group('Request Donation Integration Tests', () {
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

    testWidgets(
    'Send a Request for a Donation Item and verify the request is sent',
    (WidgetTester tester) async {
  // Build the HomePage widget with necessary providers
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

  // Wait for HomePage to settle
  await tester.pumpAndSettle();

  // Navigate to Donations tab
  await tester.tap(find.byIcon(Icons.food_bank));
  await tester.pumpAndSettle();

  // Verify DonationPage is displayed
  expect(find.byType(DonationsPage), findsOneWidget);

  // Check if donation items are displayed
  expect(find.byType(DonationCard), findsWidgets);

  // Locate a donation item containing "cheese"
  final donationCardFinder = find.descendant(
    of: find.byType(DonationCard),
    matching: find.textContaining('cheese', findRichText: true),
  ).first;

  // Ensure the donation item is found
  expect(donationCardFinder, findsOneWidget);

  // Tap on the donation card
  await tester.tap(donationCardFinder);
  await tester.pumpAndSettle();

  // Verify that the donation detail screen is displayed
  expect(find.text('Product Details'), findsOneWidget);

  // Tap the "Request Donation" button
  final requestDonationButton = find.text('Request Donation');
  await tester.tap(requestDonationButton);
  await tester.pumpAndSettle();

  // Verify that the request page appears
  expect(find.text('Donation Request Form'), findsOneWidget);

  // Find the pickup date/time field
  final pickupDateTimeField =
      find.widgetWithText(TextFormField, 'Pickup Date & Time (required)');

  // Ensure the field is visible before tapping
  await tester.ensureVisible(pickupDateTimeField);
  await tester.pumpAndSettle();

  // Tap the field
  await tester.tap(pickupDateTimeField);
  await tester.pumpAndSettle();

  // If the date picker does not appear, manually enter a date/time
  if (find.text('26').evaluate().isEmpty) {
    await tester.enterText(pickupDateTimeField, '2024-03-27 19:00');
    await tester.pumpAndSettle();
  } else {
    // Select a day in the date picker
    await tester.tap(find.text('26'));
    await tester.pumpAndSettle();

    // Tap OK
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Select time
    await tester.tap(find.text('19'));
    await tester.pumpAndSettle();
  

    // Tap OK again
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }
  
  // Tap the "Send Request" button
  final requestDonationButton2 = find.text('Send Request');
  await tester.tap(requestDonationButton2);
  await tester.pumpAndSettle();

  // Verify that the request was sent successfully
  expect(find.text('Donation request sent successfully!'), findsOneWidget);
  await tester.pumpAndSettle();
  
await Future.delayed(Duration(seconds: 5)); // Allow Firestore to sync
await tester.pumpAndSettle();

});
  


testWidgets('Verify the donation requests is within "Sent Requests',
    (WidgetTester tester) async {

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

  //tap on the "Sent Requests" tab
  final Finder sentRequestsTab = find.text('Sent Requests');
  await tester.tap(sentRequestsTab);
  await tester.pumpAndSettle();

     final Finder dropdown = find.text('All');
      await tester.ensureVisible(dropdown);  // Ensure dropdown is visible
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Select "Reserved" from dropdown
      final Finder pendingOption = find.text('Pending');
      await tester.tap(pendingOption);
      await tester.pumpAndSettle();

  // Verify that the donation request is displayed within a card
  final Finder donationRequestCard = find.descendant(
    of: find.byType(Card),
    matching: find.textContaining('cheese', findRichText: true)
  );
  expect(donationRequestCard, findsOneWidget);
  await tester.pumpAndSettle();
});

  });
}