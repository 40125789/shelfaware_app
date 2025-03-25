import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shelfaware_app/pages/home_page.dart';
import 'package:shelfaware_app/pages/settings_page.dart';
import 'package:shelfaware_app/services/donation_service.dart';
import 'package:shelfaware_app/services/food_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(fileName: "assets/.env");
  });

  group('Settings Page Integration Tests', () {
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

    // Function to navigate to the "Settings" page from the Home page
    Future<void> navigateToSettingsPage(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            routes: {
              '/settings': (context) => SettingsPage(),
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

      // Open the side drawer
      final Finder menuButton = find.byTooltip('Open navigation menu');
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Tap on the "Settings" navigation item in the side drawer
      final Finder settingsNavItem = find.text('Settings');
      await tester.tap(settingsNavItem);
      await tester.pumpAndSettle(); // Wait for the transition to complete
    }

    testWidgets('Navigate to Settings page', (WidgetTester tester) async {
      // Navigate to the Settings page
      await navigateToSettingsPage(tester);

      // Verify that the Settings page is displayed
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('Toggle Messages switch', (WidgetTester tester) async {
      // Navigate to the Settings page
      await navigateToSettingsPage(tester);

      // Find and toggle the "Messages" switch
      final Finder messagesSwitch = find.byKey(Key('messages-switch'));
      expect(messagesSwitch, findsOneWidget);

      // Check if the switch is initially ON (assuming default state)
      final Switch messagesSwitchWidget = tester.widget<Switch>(messagesSwitch);
      expect(messagesSwitchWidget.value, true);

      // Toggle the switch
      await tester.tap(messagesSwitch);
      await tester.pumpAndSettle();

      // Verify that the switch is toggled (value should change to OFF)
      expect(tester.widget<Switch>(messagesSwitch).value, false);

      // Toggle it back to ON
      await tester.tap(messagesSwitch);
      await tester.pumpAndSettle();
    });

    testWidgets('Toggle Donation Requests switch', (WidgetTester tester) async {
      // Navigate to the Settings page
      await navigateToSettingsPage(tester);

      // Find and toggle the "Donation Requests" switch
      final Finder donationRequestsSwitch = find.byKey(Key('request-switch'));
      await tester.tap(donationRequestsSwitch);
      await tester.pumpAndSettle();
    });

    testWidgets('Toggle Expiry Alerts switch', (WidgetTester tester) async {
      // Navigate to the Settings page
      await navigateToSettingsPage(tester);

      // Find and toggle the "Expiry Alerts" switch
      final Finder expiryAlertsSwitch = find.byKey(Key('expiry-switch'));
      await tester.tap(expiryAlertsSwitch);
      await tester.pumpAndSettle();
    });

    testWidgets('Toggle Theme switch', (WidgetTester tester) async {
      // Navigate to the Settings page
      await navigateToSettingsPage(tester);

      // Now, check the theme toggle switch (light/dark mode)
      final Finder themeSwitch = find.byKey(Key('theme-switch'));
      expect(themeSwitch, findsOneWidget);
      await tester.tap(themeSwitch);
      await tester.pumpAndSettle();

      // Verify that the theme is toggled (Light/Dark)
      final Finder darkModeIcon = find.byIcon(Icons.nightlight_round);
      final Finder lightModeIcon = find.byIcon(Icons.sunny);

      if (darkModeIcon.evaluate().isEmpty) {
        expect(lightModeIcon, findsOneWidget); // Light mode should be visible
      } else {
        expect(darkModeIcon, findsOneWidget); // Dark mode should be visible
      }
    });
  });
}
