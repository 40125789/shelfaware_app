import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shelfaware_app/components/food_list_view.dart';
import 'package:shelfaware_app/screens/register_page.dart';
import 'package:shelfaware_app/screens/home_page.dart';



void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  group('RegisterPage Integration Test', () {
    testWidgets('User can register successfully and navigate to HomePage', (WidgetTester tester) async {
      final mockAuth = MockFirebaseAuth();
      final fakeFirestore = FakeFirebaseFirestore();

      await tester.pumpWidget(
        MaterialApp(
          home: RegisterPage(
            onTap: () {},
          ),
        ),
      );

      // Enter first name
      await tester.enterText(find.byKey(Key('firstNameField')), 'John');
      // Enter last name
      await tester.enterText(find.byKey(Key('lastNameField')), 'Doe');
      // Enter email
      await tester.enterText(find.byKey(Key('emailField')), 'john.doe@example.com');
      // Enter password
      await tester.enterText(find.byKey(Key('passwordField')), 'password123');
      // Enter confirm password
      await tester.enterText(find.byKey(Key('confirmPasswordField')), 'password123');

      // Tap the sign-up button
      await tester.tap(find.byKey(Key('signupButton')));
      await tester.pumpAndSettle();

    
    });

    testWidgets('User sees error message for invalid email', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RegisterPage(
            onTap: () {},
          ),
        ),
      );

      // Enter first name
      await tester.enterText(find.byKey(Key('firstNameField')), 'John');
      // Enter last name
      await tester.enterText(find.byKey(Key('lastNameField')), 'Doe');
      // Enter invalid email
      await tester.enterText(find.byKey(Key('emailField')), 'invalid-email');
      // Enter password
      await tester.enterText(find.byKey(Key('passwordField')), 'password123');
      // Enter confirm password
      await tester.enterText(find.byKey(Key('confirmPasswordField')), 'password123');

      // Tap the sign-up button
      await tester.tap(find.byKey(Key('signupButton')));
      await tester.pumpAndSettle();

      // Verify that the error message is shown
      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('User sees error message for password mismatch', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RegisterPage(
            onTap: () {},
          ),
        ),
      );

      // Enter first name
      await tester.enterText(find.byKey(Key('firstNameField')), 'John');
      // Enter last name
      await tester.enterText(find.byKey(Key('lastNameField')), 'Doe');
      // Enter email
      await tester.enterText(find.byKey(Key('emailField')), 'johndoe@hotmail.com');
      // Enter password
      await tester.enterText(find.byKey(Key('passwordField')), 'Password@123');
      // Enter different confirm password
      await tester.enterText(find.byKey(Key('confirmPasswordField')), 'Password@456');

      // Tap the sign-up button
      await tester.tap(find.byKey(Key('signupButton')));
      await tester.pumpAndSettle();

            // Wait for a specific duration to ensure the error message appears
      await tester.pump(const Duration(seconds: 3));

      // Verify that the error message is shown
      expect(find.text('Passwords do not match'), findsOneWidget);
    });
  });
}