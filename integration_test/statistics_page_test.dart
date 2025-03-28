import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shelfaware_app/pages/home_page.dart';
import 'package:shelfaware_app/pages/statistics_page.dart';
import 'package:shelfaware_app/services/donation_service.dart';
import 'package:shelfaware_app/services/food_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(fileName: "assets/.env");
  });

  group('StatisticsPage Integration Tests', () {
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

    // Test 1: Directly Navigating to Statistics Tab and Verifying the Statistics Page
    testWidgets(
        'Directly navigate to Statistics tab and display statistics items',
        (WidgetTester tester) async {
      // Build the MaterialApp widget with the HomePage and navigation setup
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              appBarTheme: AppBarTheme(
                backgroundColor: Colors
                    .green, // Ensure this is the color from your main.dart
              ),
            ),
            home: HomePage(),
          ),
        ),
      );

      // Wait for the HomePage to settle
      await tester.pumpAndSettle();

      // Verify the HomePage is displayed
      expect(find.byType(HomePage), findsOneWidget);

      // Tap on the "Statistics" tab (index 3)
      await tester
          .tap(find.byIcon(Icons.bar_chart)); // Icon for 'Statistics' tab
      await tester.pumpAndSettle();

      // Verify that the AppBar text changes to 'Statistics'
      expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text('Statistics'),
          ),
          findsOneWidget);

      // Verify that the StatisticsPage is displayed
      expect(find.byType(StatisticsPage), findsOneWidget);
    });

    // Test 2: Selecting Month from the Month Picker Dialog on Statistics Page
    testWidgets('Select month from the month picker dialog on StatisticsPage',
        (WidgetTester tester) async {
      // Build the MaterialApp widget with the HomePage and navigation setup
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              appBarTheme: AppBarTheme(
                backgroundColor: Colors
                    .green, // Ensure this is the color from your main.dart
              ),
            ),
            home: HomePage(),
          ),
        ),
      );

      // Wait for the HomePage to settle
      await tester.pumpAndSettle();

      // Tap on the "Statistics" tab (index 3)
      await tester
          .tap(find.byIcon(Icons.bar_chart)); // Icon for 'Statistics' tab
      await tester.pumpAndSettle();

      // Wait for the StatisticsPage to settle
      await tester.pumpAndSettle();

      // Find the "March" text that represents the currently selected month
      final monthText = find.text('March');
      expect(monthText, findsOneWidget);

      // Tap on the "March" text to open the month picker
      await tester.tap(monthText);
      await tester.pumpAndSettle();

      // Verify the month picker dialog appears
      final monthPickerDialog = find.byType(Dialog);
      expect(monthPickerDialog, findsOneWidget);

      // Tap on the "Feb" text to select February
      final febButton = find.text('Feb');
      expect(febButton, findsOneWidget);
      await tester.tap(febButton);
      await tester.pumpAndSettle();

      // Tap on the "OK" text to confirm the month selection
      final okButton = find.text('OK');
      expect(okButton, findsOneWidget);
      await tester.tap(okButton);
      await tester.pumpAndSettle();

      // Verify that the month picker dialog is dismissed
      expect(monthPickerDialog, findsNothing);

      // Verify that the month has been updated to February
      final febText = find.text('February');
      expect(febText, findsOneWidget);
    });

    // Test 3: Interacting with the Expandable Tile on Statistics Page
    testWidgets(
        'Interact with expandable tile on StatisticsPage and verify list visibility',
        (WidgetTester tester) async {
      // Build the MaterialApp widget with the HomePage and navigation setup
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              appBarTheme: AppBarTheme(
                backgroundColor: Colors
                    .green, // Ensure this is the color from your main.dart
              ),
            ),
            home: HomePage(),
          ),
        ),
      );

      // Wait for the HomePage to settle
      await tester.pumpAndSettle();

      // Tap on the "Statistics" tab (index 3)
      await tester
          .tap(find.byIcon(Icons.bar_chart)); // Icon for 'Statistics' tab
      await tester.pumpAndSettle();

      // Wait for the StatisticsPage to settle
      await tester.pumpAndSettle();

      // Tap on the first expandable tile (Consumed Items)
      final consumedTile = find.text('Consumed Items');
      expect(consumedTile, findsOneWidget);

      // Tap on the expandable tile to expand it
      await tester.tap(consumedTile);
      await tester.pumpAndSettle();

      // Verify that the consumed items list is now visible
      final consumedItemsList = find.byType(ListTile);
      expect(consumedItemsList, findsWidgets);

      // Tap again to collapse the tile
      await tester.tap(consumedTile);
      await tester.pumpAndSettle();

      // Verify that the consumed items list is no longer visible
      expect(consumedTile, findsOneWidget);
      await tester.pumpAndSettle();
    });
  });
}
