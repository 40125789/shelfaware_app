import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfaware_app/screens/login_or_register_page.dart';
import 'package:shelfaware_app/screens/login_page.dart';
import 'package:shelfaware_app/screens/register_page.dart';

void main() {
  testWidgets('Initial state shows LoginPage', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginOrRegisterPage(),
      ),
    );

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(RegisterPage), findsNothing);
  });

  testWidgets('Tapping toggle switches to RegisterPage', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginOrRegisterPage(),
      ),
    );

    // Verify initial state is LoginPage
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(RegisterPage), findsNothing);

    // Tap the toggle button
    final toggleButton = find.byType(TextButton); // Assuming the toggle button is a TextButton
    await tester.tap(toggleButton);
    await tester.pumpAndSettle();

    // Verify state is now RegisterPage
    expect(find.byType(LoginPage), findsNothing);
    expect(find.byType(RegisterPage), findsOneWidget);
  });

  testWidgets('Tapping toggle again switches back to LoginPage', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginOrRegisterPage(),
      ),
    );

    // Tap the toggle button to switch to RegisterPage
    final toggleButton = find.byType(TextButton); // Assuming the toggle button is a TextButton
    await tester.tap(toggleButton);
    await tester.pumpAndSettle();

    // Verify state is now RegisterPage
    expect(find.byType(LoginPage), findsNothing);
    expect(find.byType(RegisterPage), findsOneWidget);

    // Tap the toggle button again to switch back to LoginPage
    await tester.tap(toggleButton);
    await tester.pumpAndSettle();

    // Verify state is now LoginPage
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(RegisterPage), findsNothing);
  });
}