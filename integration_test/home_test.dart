// integration_test/home_page_test.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
 // Replace with your main entry point file
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shelfaware_app/components/calendar_view_widget.dart';
import 'package:shelfaware_app/main.dart';

Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'your_api_key',
      appId: 'your_app_id',
      messagingSenderId: 'your_messaging_sender_id',
      projectId: 'your_project_id',
    ),
  );

  group('HomePage Integration Test', () {
    testWidgets('User navigates and interacts with HomePage elements',
        (tester) async {
      // Set up necessary authentication or mock the FirebaseAuth instance if needed
      FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      );

      // Pump the HomePage widget
      await tester.pumpWidget(MyApp()); // Replace with your actual app widget

      // Verify the home page is loaded by checking the app bar title or any widget
      expect(find.text('Home'), findsOneWidget);

      // Test the filter dropdown functionality
      expect(find.byType(DropdownButton<String>), findsOneWidget);

      // Interact with the dropdown and change the selected filter
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('All').last);
      await tester.pumpAndSettle();

      // Verify the dropdown updated correctly
      expect(find.text('All'), findsOneWidget);

      // Test switching between list view and calendar view
      expect(find.byType(Switch), findsOneWidget);

      // Toggle the switch to change the view
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.byType(CalendarView), findsOneWidget);

      // Test navigating to the 'Recipes' page
      await tester.tap(find.byIcon(Icons.restaurant)); // Replace with the actual icon or navigation method
      await tester.pumpAndSettle();
      expect(find.text('Recipes'), findsOneWidget);
    });
  });
}
