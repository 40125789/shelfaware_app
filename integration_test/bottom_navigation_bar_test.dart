import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shelfaware_app/pages/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/services/donation_service.dart';
import 'package:shelfaware_app/services/food_service.dart';


void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(fileName: "assets/.env");
    await Permission.location.request(); // Request location permission
    await Permission.camera.request();   // Request camera permission
  });

  group('HomePage Integration Tests', () {
    late FirebaseAuth auth;
    late FirebaseFirestore firestore;
    late DonationService donationService;
    late FoodService foodService;
      late User user;

    setUp(() async {
      // Initialize Firebase
      await Firebase.initializeApp();
      auth = FirebaseAuth.instance;
      await auth.signInWithEmailAndPassword(
          email: 'smyth668@hotmail.com', password: 'Ya9maha8@');
      firestore = FirebaseFirestore.instance;
      donationService = DonationService();
      foodService = FoodService();
      user = auth.currentUser!;
    });

    tearDown(() async {
      // Sign out the user to reset the state
      await auth.signOut();
    });

    testWidgets('Navigate through BottomNavigationBar and verify AppBar text', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.green, // Ensure this is the color from your main.dart
              ),
            ),
            home: HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially, verify the default AppBar text for Home (index 0)
      expect(find.descendant(
        of: find.byType(AppBar), 
        matching: find.text('Home')
      ), findsOneWidget); // Target only the Text inside AppBar

      // Tap on the 'Recipes' tab (index 1)
      await tester.tap(find.byIcon(Icons.book)); // Icon for 'Recipes' tab
      await tester.pumpAndSettle();
      
      // Verify that the AppBar shows "Recipes" after selecting the Recipes tab
      expect(find.descendant(
        of: find.byType(AppBar), 
        matching: find.text('Recipes')
      ), findsOneWidget); // Target only the Text inside AppBar

      // Tap on the 'Donations' tab (index 2)
      await tester.tap(find.byIcon(Icons.food_bank)); // Icon for 'Donations' tab
      await tester.pumpAndSettle();
      
      // Verify that the AppBar shows "Donations" after selecting the Donations tab
      expect(find.descendant(
        of: find.byType(AppBar), 
        matching: find.text('Donations')
      ), findsOneWidget); // Target only the Text inside AppBar

      // Tap on the 'Statistics' tab (index 3)
      await tester.tap(find.byIcon(Icons.bar_chart)); // Icon for 'Statistics' tab
      await tester.pumpAndSettle();
      
      // Verify that the AppBar shows "Statistics" after selecting the Statistics tab
      expect(find.descendant(
        of: find.byType(AppBar), 
        matching: find.text('Statistics')
      ), findsOneWidget); // Target only the Text inside AppBar
    });
  });
}