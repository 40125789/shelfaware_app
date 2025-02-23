import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shelfaware_app/components/my_button.dart';
import 'package:shelfaware_app/components/my_textfield.dart';
import 'package:shelfaware_app/pages/home_page.dart';
import 'package:shelfaware_app/pages/login_page.dart';
import 'package:shelfaware_app/services/auth_services.dart';



// Import the generated mocks file (adjust filename as generated)
import '../mocks.mocks.dart';

@GenerateMocks([AuthService])
class TestNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushedRoutes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    pushedRoutes.add(route);
  }
}

void main() {
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
  });

  Widget createLoginPage() {
    return MaterialApp(
      home: LoginPage(
      // Provide the required named argument
        email: '',
        onTap: () {}, // Optional callback if needed
      ),
    );
  }

  testWidgets('LoginPage displays correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createLoginPage());

    expect(find.text('Welcome back!'), findsOneWidget);
    expect(find.byType(MyTextField), findsNWidgets(2));
    expect(find.byType(MyButton), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Not a member?'), findsOneWidget);
    expect(find.text('Register Now'), findsOneWidget);
  });

  testWidgets('LoginPage shows error SnackBar on invalid email', (WidgetTester tester) async {  

  await tester.pumpWidget(createLoginPage());

  await tester.enterText(find.byType(MyTextField).at(0), 'test@example.com');
  await tester.enterText(find.byType(MyTextField).at(1), 'wrongpassword');
  await tester.tap(find.byType(MyButton));

  // Instead of pumpAndSettle, pump for a short duration.
  await tester.pump(Duration(seconds: 1));

  // Check if error SnackBar is shown.
  expect(find.text('wrong-password'), findsOneWidget);
});

testWidgets('LoginPage navigates to HomePage on successful login', (WidgetTester tester) async {
  final email = 'test@example.com';
  final password = 'correctpassword';

  // Create a navigator observer to track navigation.
  final navigatorObserver = TestNavigatorObserver();

  // Set up the mock to succeed.
  when(mockAuthService.signInWithEmailAndPassword(email, password))
      .thenAnswer((_) async => null);

  await tester.pumpWidget(
    MaterialApp(
      home: LoginPage(
       
        email: '',
        onTap: () {},
      ),
      navigatorObservers: [navigatorObserver],
    ),
  );

  // Enter credentials.
  await tester.enterText(find.byType(MyTextField).at(0), email);
  await tester.enterText(find.byType(MyTextField).at(1), password);

  // Tap the login button.
  await tester.tap(find.byType(MyButton));

  // Instead of pumpAndSettle, pump in steps.
  await tester.pump(); // start processing the tap
  await tester.pump(const Duration(seconds: 1)); // wait for async operations

  // Verify that a route push occurred.
  expect(navigatorObserver.pushedRoutes, isNotEmpty);
  
  // Optionally, check that one of the pushed routes is HomePage.
  bool homePagePushed = navigatorObserver.pushedRoutes.any((route) {
    return route.settings.name == '/home' || (route is MaterialPageRoute && route.builder != null && route.builder(route.navigator!.context) is HomePage);
  });
  expect(homePagePushed, isTrue);
});

}
