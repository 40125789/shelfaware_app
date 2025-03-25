import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shelfaware_app/pages/home_page.dart';
import 'package:shelfaware_app/services/donation_service.dart';
import 'package:shelfaware_app/services/food_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(fileName: "assets/.env");
  });

  group('Chat List Page Integration Tests', () {
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

    // Function to navigate to the Chat List page from the Home page
    Future<void> navigateToChatListPage(WidgetTester tester) async {
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

      // Tap on the "Messages" navigation item in the side drawer
      final Finder messagesNavItem = find.text('Messages');
      await tester.tap(messagesNavItem);
      await tester.pumpAndSettle();
    }

    // Test: Clear Sarah and search for chats with John in the Chat List
    testWidgets('Clear Sarah and search for chats with John in the Chat List',
        (WidgetTester tester) async {
      // Navigate to the chat list page
      await navigateToChatListPage(tester);

      // Ensure we are on the Chat List page
      expect(find.text('Chat List'), findsOneWidget);

      // Find the search TextField and tap it
      final Finder searchField = find.byType(TextField).first;
      await tester.tap(searchField);
      await tester.pumpAndSettle();

      // Enter 'Sarah' in the search field
      await tester.enterText(searchField, 'sarah');
      await tester.pumpAndSettle();

      // Ensure that chats containing 'Sarah' are shown
      final Finder chatWithSarah = find.textContaining('Sarah');
      expect(chatWithSarah,
          findsWidgets); // Only chats with 'Sarah' should be shown

      // Clear the search field by entering an empty string and waiting for the list to update
      await tester.enterText(searchField, ''); // Clear the field
      await tester.pumpAndSettle();

      // Ensure no chats are visible after clearing the search (if necessary)
      final Finder allChats = find.byType(ListTile);
      expect(allChats, findsWidgets); // Ensure that chats are reset

      // Now enter 'John' in the search field
      await tester.enterText(searchField, 'john');
      await tester.pumpAndSettle();

      // No chats with "John" should be displayed
      final Finder chatWithJohn = find.textContaining('John');
      expect(
          chatWithJohn, findsNothing); // Ensure no chats with 'John' are shown
      await tester.pumpAndSettle();

      // Check that chats with 'Sarah' are not displayed
      final Finder chatWithSarahAfterClear = find.textContaining('Sarah');
      expect(chatWithSarahAfterClear,
          findsNothing); // Ensure no chats with 'Sarah' are shown
    });

    // Test: Search for James and send a message in the chat
    testWidgets(
        'Search for chats with James in the chat list page and send a message  to the user "James" in the Chat page',
        (WidgetTester tester) async {
      // Navigate to the chat list page
      await navigateToChatListPage(tester);

      // Ensure we are on the Chat List page
      expect(find.text('Chat List'), findsOneWidget);

      // Find the search TextField and tap it
      final Finder searchField = find.byType(TextField).first;
      await tester.tap(searchField);
      await tester.pumpAndSettle();

      // Enter 'James' in the search field
      await tester.enterText(searchField, 'james');
      await tester.pumpAndSettle();

      // Ensure that chats containing 'James' are shown
      final Finder chatWithJames = find.textContaining('James');
      expect(chatWithJames,
          findsWidgets); // Only chats with 'James' should be shown

      // Tap the first chat in the list
      final Finder firstChat = find.byType(ListTile).first;
      await tester.tap(firstChat);
      await tester.pumpAndSettle();

      // Ensure that we are navigated to the chat page with the title 'Chat with James'
      expect(find.text('Chat with James'), findsOneWidget);

      // Find the UserInput widget's text field (to enter a message)
      final Finder messageField = find
          .byType(TextField)
          .last; // Assuming the last TextField is for message input
      await tester.tap(messageField);
      await tester.pumpAndSettle();

      // Enter a message into the text field
      final messageText = 'Hello, James!';
      await tester.enterText(messageField, messageText);
      await tester.pumpAndSettle();

      // Ensure that the message field is not empty before tapping the send button
      expect(find.text(messageText),
          findsOneWidget); // Make sure the text was entered

      // Find the send button (icon) and tap it
      final Finder sendButton = find.byIcon(Icons.send);
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      // Verify that the message is displayed in the chat
      final Finder sentMessage = find.text(messageText);
      expect(sentMessage,
          findsOneWidget); // Ensure the message appears in the chat
      await tester.pumpAndSettle();

      // Check if "Today" is displayed above the sent message
      final Finder todayLabel = find.text('Today');
      expect(todayLabel,
          findsOneWidget); // Ensure "Today" is displayed next to the sent message
      await tester.pumpAndSettle();
    });
  });
}
