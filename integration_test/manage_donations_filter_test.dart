import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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
    await Permission.location.request(); // Request location permission
    await Permission.camera.request(); // Request camera permission
  });

  group('Manage Donations Integration Tests', () {
    late FirebaseAuth auth;
    late FirebaseFirestore firestore;
    late DonationService donationService;
    late FoodService foodService;
    late User user;

    setUp(() async {
      // Initialize Firebase
      auth = FirebaseAuth.instance;
      await auth.signInWithEmailAndPassword(
          email: 'smyth668@hotmail.com', password: 'Ya9maha8@');
      firestore = FirebaseFirestore.instance;
      donationService = DonationService();
      foodService = FoodService();
      user = auth.currentUser!;
    });

    testWidgets('Test filtering donations by status in the dropdown', (WidgetTester tester) async {
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
      expect(dropdown, findsOneWidget);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Select "Available" from dropdown
      final Finder availableOption = find.text('Available');
      await tester.ensureVisible(availableOption);
      await tester.tap(availableOption);
      await tester.pumpAndSettle();

      // Verify "Available" is displayed in the cards
      expect(find.text('banana'), findsOneWidget); 
      await tester.pumpAndSettle();

      // Tap dropdown again to select "Reserved"
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      final Finder reservedOption = find.text('Reserved');
      await tester.ensureVisible(reservedOption);
      await tester.tap(reservedOption);
      await tester.pumpAndSettle();

      // Verify "Reserved" items are displayed (make sure these exist in your test setup)
      expect(find.text('Crisps'), findsOneWidget);  // Example of reserved item.
      await tester.pumpAndSettle();

      // Tap dropdown again to select "Picked Up"
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      final Finder pickedUpOption = find.text('Picked Up');
      await tester.ensureVisible(pickedUpOption);
      await tester.tap(pickedUpOption);
      await tester.pumpAndSettle();

      // Verify that "Picked Up" items are displayed or that items are marked as "Donated"
      expect(find.text('Donated'), findsWidgets);  // Or whatever the correct label for "Picked Up" is.
      await tester.pumpAndSettle();
    });
  });

}
