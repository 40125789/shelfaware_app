import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shelfaware_app/components/food_list_view.dart';
import 'package:shelfaware_app/components/top_app_bar.dart';
import 'package:shelfaware_app/pages/home_page.dart';
import 'package:shelfaware_app/services/donation_service.dart';
import 'package:shelfaware_app/services/food_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';



void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
   await dotenv.load(fileName: ".env");
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


    testWidgets('Display food items based on user filter in HomePage', (WidgetTester tester) async {
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

      // Verify that the HomePage is displayed
      expect(find.byType(HomePage), findsOneWidget);

      // Verify that the TopAppBar is displayed
      expect(find.byType(TopAppBar), findsOneWidget);

      // Tap on the dropdown to select filter
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('All').last);
      await tester.pumpAndSettle();

      // Verify that the FoodListView is displayed
      expect(find.byType(FoodListView), findsOneWidget);

      // Expand categories
      await tester.tap(find.text('Expired'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Expiring Soon'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fresh'));
      await tester.pumpAndSettle();

      // Verify food items
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Carrot'), findsOneWidget);

      // Locate the correct food item card
      final cardFinder = find.ancestor(
        of: find.text('Banana'),
        matching: find.byType(Card),
      );

      // Locate popup menu icon inside the specific card
      final popupMenuFinder = find.descendant(
        of: cardFinder,
        matching: find.byIcon(Icons.more_vert),
      );

      // Tap popup menu icon
      await tester.tap(popupMenuFinder);
      await tester.pumpAndSettle();

      // Verify popup menu options
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Donate'), findsOneWidget);
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
  


    testWidgets('Display filtered food items in HomePage', (WidgetTester tester) async {
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

      // Tap on the dropdown to select filter
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('fruits').last);
      await tester.pumpAndSettle();

      // Verify that the FoodListView is displayed
      expect(find.byType(FoodListView), findsOneWidget);

      // Expand categories
      await tester.tap(find.text('Expired'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Expiring Soon'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fresh'));
      await tester.pumpAndSettle();

      // Verify only filtered food item is displayed
      expect(find.text('Banana'), findsOneWidget);

      // Tap on the filtered food item
      await tester.tap(find.text('Banana'));
      await tester.pumpAndSettle();
    });
  });
}