import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelfaware_app/models/user_model.dart';

void main() {
  group('UserData', () {
    final testData = {
      'firstName': 'John',
      'lastName': 'Doe',
      'profileImageUrl': 'http://example.com/profile.jpg',
      'bio': 'This is a bio',
      'joinDate': Timestamp.fromDate(DateTime(2020, 1, 1)),
      'averageRating': 4.5,
      'reviewCount': 10,
    };

    test('fromFirestore creates a UserData instance from Firestore data', () {
      final user = UserData.fromFirestore(testData);

      expect(user.firstName, 'John');
      expect(user.lastName, 'Doe');
      expect(user.profileImageUrl, 'http://example.com/profile.jpg');
      expect(user.bio, 'This is a bio');
      expect(user.joinDate, DateTime(2020, 1, 1));
      expect(user.averageRating, 4.5);
      expect(user.reviewCount, 10);
    });

    test('toMap converts a UserData instance to a map', () {
      final user = UserData.fromFirestore(testData);
      final userMap = user.toMap();

      expect(userMap['firstName'], 'John');
      expect(userMap['lastName'], 'Doe');
      expect(userMap['profileImageUrl'], 'http://example.com/profile.jpg');
      expect(userMap['bio'], 'This is a bio');
      expect(userMap['joinDate'], Timestamp.fromDate(DateTime(2020, 1, 1)));
      expect(userMap['averageRating'], 4.5);
      expect(userMap['reviewCount'], 10);
    });

    });
  
}