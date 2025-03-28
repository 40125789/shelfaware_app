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
import 'package:shelfaware_app/components/donation_request_card.dart';
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

    Future<void> testFilter(WidgetTester tester, String status,
        {bool multiple = false}) async {
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

      // Tap on the "Sent Requests" tab
      final Finder sentRequestsTab = find.text('Sent Requests');
      await tester.tap(sentRequestsTab);
      await tester.pumpAndSettle();

      // Open the filter dropdown
      final Finder dropdown = find.byType(DropdownButton<String>);
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Ensure dropdown menu is now visible and find the specific status option **inside** the dropdown
      final Finder dropdownMenuItem = find.descendant(
        of: find
            .byType(DropdownMenuItem<String>), // Search within dropdown items
        matching: find.text(status),
      );

      expect(dropdownMenuItem,
          findsOneWidget); // Ensure the option exists in dropdown

      // Tap the status option inside the dropdown
      await tester.tap(dropdownMenuItem);
      await tester.pumpAndSettle();

      // Verify that at least one donation request is displayed with the selected status
      final Finder donationRequestCard = find.descendant(
        of: find.byType(DonationRequestCard),
        matching: find.textContaining(status, findRichText: true),
      );

      if (multiple) {
        expect(donationRequestCard, findsWidgets); // Expect multiple items
      } else {
        expect(donationRequestCard, findsOneWidget); // Expect only one item
      }

      await tester.pumpAndSettle();
    }

    testWidgets('Test filtering donations by Pending status', (tester) async {
      await testFilter(tester, 'Pending');
    });

    testWidgets('Test filtering donations by Declined status', (tester) async {
      await testFilter(tester, 'Declined');
    });

    testWidgets('Test filtering donations by Accepted status', (tester) async {
      await testFilter(tester, 'Accepted');
    });

    testWidgets('Test filtering donations by Picked Up status', (tester) async {
      await testFilter(tester, 'Picked Up', multiple: true);
    });
  });
}
