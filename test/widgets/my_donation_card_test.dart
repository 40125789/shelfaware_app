import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfaware_app/components/my_donation_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  testWidgets('MyDonationCard displays correct request count',
      (WidgetTester tester) async {
    // Arrange
    final donation = {
      'productName': 'Test Product',
      'donatedAt': Timestamp.now(),
      'status': 'Pending',
      'imageUrl': '',
      'assignedToName': 'John Doe',
    };
    final requestCount = 5;
    final userId = 'user123';
    final onTap = () {};

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MyDonationCard(
            donation: donation,
            requestCount: requestCount,
            onTap: onTap,
            userId: userId,
          ),
        ),
      ),
    );

    // Assert
    expect(find.text('5 requests'), findsOneWidget);
  });

  testWidgets('MyDonationCard displays singular request count correctly',
      (WidgetTester tester) async {
    // Arrange
    final donation = {
      'productName': 'Test Product',
      'donatedAt': Timestamp.now(),
      'status': 'Pending',
      'imageUrl': '',
      'assignedToName': 'John Doe',
    };
    final requestCount = 1;
    final userId = 'user123';
    final onTap = () {};

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MyDonationCard(
            donation: donation,
            requestCount: requestCount,
            onTap: onTap,
            userId: userId,
          ),
        ),
      ),
    );

    // Assert
    expect(find.text('1 request'), findsOneWidget);
  });

  testWidgets('MyDonationCard hides request count when zero',
      (WidgetTester tester) async {
    // Arrange
    final donation = {
      'productName': 'Test Product',
      'donatedAt': Timestamp.now(),
      'status': 'Pending',
      'imageUrl': '',
      'assignedToName': 'John Doe',
    };
    final requestCount = 0;
    final userId = 'user123';
    final onTap = () {};

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MyDonationCard(
            donation: donation,
            requestCount: requestCount,
            onTap: onTap,
            userId: userId,
          ),
        ),
      ),
    );

    // Assert
    expect(find.text('0 requests'), findsNothing);
  });
}
