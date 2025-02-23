import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfaware_app/components/chat_user_input.dart';

void main() {
  testWidgets('UserInput widget test', (WidgetTester tester) async {
    final messageController = TextEditingController();
    bool sendPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UserInput(
            messageController: messageController,
            onSend: () {
              sendPressed = true;
            },
          ),
        ),
      ),
    );

    // Verify if the TextField is present
    expect(find.byType(TextField), findsOneWidget);

    // Verify if the IconButton is present
    expect(find.byType(IconButton), findsOneWidget);

    // Enter text into the TextField
    await tester.enterText(find.byType(TextField), 'Hello');
    expect(messageController.text, 'Hello');

    // Tap the send button
    await tester.tap(find.byType(IconButton));
    await tester.pump();

    // Verify if the onSend callback was triggered
    expect(sendPressed, true);
  });
}
