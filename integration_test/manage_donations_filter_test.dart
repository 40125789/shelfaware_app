import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shelfaware_app/components/my_donation_status_filter.dart';
import 'package:shelfaware_app/pages/home_page.dart';
import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart';
import 'package:shelfaware_app/pages/my_donations_page.dart';
import 'package:shelfaware_app/services/donation_service.dart';
import 'package:shelfaware_app/services/food_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();


  setUpAll(() async {
    await Firebase.initializeApp();
    await dotenv.load(fileName: ".env");
    await Permission.storage.request();  // Request storage permission
    await Permission.camera.request();   // Request camera permission
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



    testWidgets('Test filtering donations by Available status', (WidgetTester tester) async {
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
      await tester.ensureVisible(dropdown);  // Ensure dropdown is visible
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Select "Available" from dropdown
      final Finder availableOption = find.text('Available');
      await tester.tap(availableOption);
      await tester.pumpAndSettle();

      // Verify that the "Banana" donation with status "Available" is displayed
      final Finder bananaDonation = find.text('banana');
      expect(bananaDonation, findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('Test filtering donations by Reserved status', (WidgetTester tester) async {
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
      await tester.ensureVisible(dropdown);  // Ensure dropdown is visible
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Select "Reserved" from dropdown
      final Finder reservedOption = find.text('Reserved');
      await tester.tap(reservedOption);
      await tester.pumpAndSettle();

      // Verify "Reserved" items are displayed
      final Finder crispDonation = find.text('crisps');
      expect(crispDonation, findsOneWidget);
      await tester.pumpAndSettle();
    });

testWidgets('Test filtering donations by Picked Up status', (WidgetTester tester) async {
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

  // Find the dropdown and tap it (this should open the menu)
  final Finder dropdown = find.text('All');
  await tester.ensureVisible(dropdown);  // Ensure dropdown is visible
  await tester.tap(dropdown);
  await tester.pumpAndSettle();  // Ensure the dropdown menu is fully rendered

  // First select "Reserved" to verify the dropdown is working correctly
  final Finder reservedOption = find.text('Reserved');
  await tester.tap(reservedOption);
  await tester.pumpAndSettle();
  
  // Then tap the dropdown again to select "Picked Up"
  final Finder dropdownButton = find.byType(StatusFilterWidget);
  await tester.tap(dropdownButton);
  await tester.pumpAndSettle();
  
  // Now, find the "Picked Up" option in the dropdown menu
  final Finder pickedUpOption = find.text('Picked Up');
  expect(pickedUpOption, findsWidgets);  // Ensure "Picked Up" option is available

  // Tap on the "Picked Up" option to filter
  await tester.tap(pickedUpOption);
  await tester.pumpAndSettle();

  // Verify that "Picked Up" items are displayed or that items are marked as "Donated"
  final Finder donatedText = find.byWidgetPredicate(
    (widget) => widget is Text && widget.data == 'Donated',
  );

  // Assert that at least one "Donated" item is displayed after filtering
  expect(donatedText, findsWidgets);  // This will check if there is at least one match
});
  });
}