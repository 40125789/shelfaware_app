import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfaware_app/components/my_button.dart';
import 'package:shelfaware_app/components/my_textfield.dart';
import 'package:shelfaware_app/components/square_tile.dart';
import 'package:shelfaware_app/pages/register_page.dart';

void main() {
  testWidgets('RegisterPage has all necessary fields and buttons', (WidgetTester tester) async {
    // Build the RegisterPage widget
    await tester.pumpWidget(
      MaterialApp(
        home: RegisterPage(onTap: () {}),
      ),
    );

    // Verify the presence of all necessary fields and buttons
    expect(find.byType(Icon), findsOneWidget);
    expect(find.text('Let\'s make an account!'), findsOneWidget);
    expect(find.byType(MyTextField), findsNWidgets(5));
    expect(find.byType(MyButton), findsOneWidget);
    expect(find.text('or continue with'), findsOneWidget);
    expect(find.byType(SquareTile), findsNWidgets(2));
    expect(find.text('Already have an account?'), findsOneWidget);
    expect(find.text(' Login Now'), findsOneWidget);
  });

  testWidgets('RegisterPage shows error message when passwords do not match', (WidgetTester tester) async {
    // Build the RegisterPage widget
    await tester.pumpWidget(
      MaterialApp(
        home: RegisterPage(onTap: () {}),
      ),
    );

    // Enter text into the password and confirm password fields
    await tester.enterText(find.byType(MyTextField).at(3), 'Password123!');
    await tester.enterText(find.byType(MyTextField).at(4), 'Password123');

    // Tap the sign-up button
    await tester.tap(find.byType(MyButton));
    await tester.pump();

    // Verify that the error message is displayed
    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('RegisterPage shows error message for invalid password', (WidgetTester tester) async {
    // Build the RegisterPage widget
    await tester.pumpWidget(
      MaterialApp(
        home: RegisterPage(onTap: () {}),
      ),
    );

    // Enter text into the password and confirm password fields
    await tester.enterText(find.byType(MyTextField).at(3), 'pass');
    await tester.enterText(find.byType(MyTextField).at(4), 'pass');

    // Tap the sign-up button
    await tester.tap(find.byType(MyButton));
    await tester.pump();

    // Verify that the error message is displayed
    expect(find.text('Password must be at least 6 characters'), findsOneWidget);
  });
}