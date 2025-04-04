import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shelfaware_app/components/food_list_view.dart';
import 'package:shelfaware_app/components/top_app_bar.dart';
import 'package:shelfaware_app/pages/home_page.dart';
import 'package:shelfaware_app/services/donation_service.dart';
import 'package:shelfaware_app/services/food_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(fileName: "assets/.env");
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

    testWidgets('Consume Food Items', (WidgetTester tester) async {
      // Build the HomePage widget
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

      await tester.pumpAndSettle();

      // Verify that the HomePage is displayed
      expect(find.byType(HomePage), findsOneWidget);

      // Verify that the TopAppBar is displayed
      expect(find.byType(TopAppBar), findsOneWidget);

      // Verify that the FoodListView is displayed
      expect(find.byType(FoodListView), findsOneWidget);

      // Expand categories
      await tester.tap(find.text('Expired'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Expiring Soon'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fresh'));
      await tester.pumpAndSettle();

      expect(find.text('Orange Juice'), findsOneWidget);
      expect(find.text('Chocolate Bar'), findsOneWidget);

      //tap on the orange juice card
      await tester.tap(find.text('Orange Juice'));
      await tester.pumpAndSettle();

      //Tap on consumed first
      await tester.tap(find.text('Consumed'));
      await tester.pumpAndSettle();

      // Verify that the food item is not in the list anymore
      expect(find.text('Orange Juice'), findsNothing);
      await tester.pumpAndSettle();
    });

    testWidgets('Discard Food Items', (WidgetTester tester) async {
      // Build the HomePage widget
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

      await tester.pumpAndSettle();

      // Verify that the HomePage is displayed
      expect(find.byType(HomePage), findsOneWidget);

      // Verify that the TopAppBar is displayed
      expect(find.byType(TopAppBar), findsOneWidget);

      // Verify that the FoodListView is displayed
      expect(find.byType(FoodListView), findsOneWidget);

      // Expand categories
      await tester.tap(find.text('Expired'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Expiring Soon'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fresh'));
      await tester.pumpAndSettle();

      expect(find.text('Chocolate Bar'), findsOneWidget);

      //tap on the chocolate bar card
      await tester.tap(find.text('Chocolate Bar'));
      await tester.pumpAndSettle();

      //Tap on consumed first
      await tester.tap(find.text('Discarded'));
      await tester.pumpAndSettle();

      // Tap on the dropdown with the text "Reason"
      await tester.tap(find.text('Select reason'));
      await tester.pumpAndSettle();

      //Select "Expired" from the dropdown
      await tester.tap(find.text('Expired').last);
      await tester.pumpAndSettle(Duration(seconds: 1));

      //Tap on the submit button
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle(Duration(seconds: 1));

      // Verify that the food item is not in the list anymore
      expect(find.text('Chocolate Bar'), findsNothing);
      await tester.pumpAndSettle();
    });

    testWidgets('Check if the food item is in the history',
        (WidgetTester tester) async {
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

      // Open the side drawer
      final Finder menuButton = find.byTooltip('Open navigation menu');
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Navigate to History page
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      // Verify History page title
      expect(find.text('Food History'), findsOneWidget);

      // Check for discarded item
      expect(find.textContaining('Chocolate Bar'), findsOneWidget);

      // Check for consumed item
      expect(find.textContaining('Orange Juice'), findsOneWidget);

      await tester.pumpAndSettle();
    });
  });
}
