import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shelfaware_app/main.dart' as app;


void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

group('LoginPage Integration Test', () {
  testWidgets('Successful login', (WidgetTester tester) async {
    // Initialize app
    app.main();
    await tester.pumpAndSettle();

    // Find the email and password text fields
    final emailField = find.byKey(Key('email-field'));
    final passwordField = find.byKey(Key('password-field'));
    final loginButton = find.byKey(Key('login-button'));

    // Enter email and password
    await tester.enterText(emailField, 'test@example.com');
    await tester.enterText(passwordField, 'password123');

    // Tap the login button
    await tester.tap(loginButton);
    
    // Wait for the login process to complete (includes waiting for CircularProgressIndicator)
    await tester.pumpAndSettle();  // Ensure the widget tree settles

    // Verify that the loading indicator is shown
    expect(find.byType(CircularProgressIndicator), findsNothing);  // It should not be there after login

  });
});


    testWidgets('Failed login', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find the email and password text fields
      final emailField = find.byKey(Key('email-field'));
      final passwordField = find.byKey(Key('password-field'));
      final loginButton = find.byKey(Key('login-button'));

      // Enter email and password
      await tester.enterText(emailField, 'wrong@example.com');
      await tester.enterText(passwordField, 'wrongpassword');

      // Tap the login button
      await tester.tap(loginButton);
      await tester.pump();

      // Verify that the loading indicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for the error message to be shown
      await tester.pumpAndSettle();

      // Verify that the error message is shown
      expect(find.text('The supplied auth credential is incorrect, malformed or has expired.'), findsOneWidget);
    });

}