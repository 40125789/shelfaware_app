import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shelfaware_app/pages/home_page.dart';
import 'package:shelfaware_app/pages/register_page.dart';
import 'package:shelfaware_app/main.dart' as app;
import 'package:shelfaware_app/pages/login_page.dart'; 


// Import your HomePage hereimport 'package:firebase_core/firebase_core.dart';



void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
  });

  group('Login and Registration Flow', () {
    testWidgets('Login to RegisterPage and complete registration', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: app.MyApp(),
        ),
      );
      await tester.pumpAndSettle();

     

      // Verify LoginPage is displayed
      expect(find.byType(LoginPage), findsOneWidget);

      // Navigate to Register Page
      final registerButton = find.byKey(Key('register-now-link'));
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // Verify RegisterPage is displayed
      expect(find.byType(RegisterPage), findsOneWidget);

      // Enter valid user details
      await tester.enterText(find.byKey(Key('first-name-field')), 'John');
      await tester.enterText(find.byKey(Key('last-name-field')), 'Doe');
      await tester.enterText(find.byKey(Key('email-field')), 'johndoe12@example.com');
      await tester.enterText(find.byKey(Key('password-field')), 'Test@123');
      await tester.enterText(find.byKey(Key('confirm-password-field')), 'Test@123');

      // Tap Sign Up
      await tester.tap(find.byKey(Key('sign-up-button')));
      await tester.pumpAndSettle();

      // Verify navigation to HomePage
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('Show validation errors on empty fields', (tester) async {
      await tester.pumpWidget(app.MyApp());

      // Navigate to Register Page
      await tester.tap(find.text('Register Now!'));
      await tester.pumpAndSettle();

      // Tap Sign Up without entering anything
      await tester.tap(find.byKey(Key('sign-up-button')));
      await tester.pumpAndSettle();

      // Verify validation messages
      expect(find.text('First name is required'), findsOneWidget);
      expect(find.text('Last name is required'), findsOneWidget);
      expect(find.text('Please enter a valid email'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });
  });
}
