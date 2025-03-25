import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shelfaware_app/repositories/food_suggestions_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  late FoodSuggestionsRepository repository;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    // Use FakeFirebaseFirestore instead of a Mockito mock
    fakeFirestore = FakeFirebaseFirestore();
    repository = FoodSuggestionsRepository(firestore: fakeFirestore);
  });

  group('FoodSuggestionsRepository', () {
    test('fetchFoodItems returns a list of food items', () async {
      // Arrange: Add a document to fake Firestore.
      final query = 'App';
      await fakeFirestore.collection('foodItems').add({'productName': 'Apple'});

      // Act
      final result = await repository.fetchFoodItems(query);

      // Assert
      expect(result, ['Apple']);
    });

    test('fetchHistoryItems returns a list of history items', () async {
      // Arrange: Add a document to fake Firestore.
      final query = 'Ban';
      await fakeFirestore.collection('history').add({'productName': 'Banana'});

      // Act
      final result = await repository.fetchHistoryItems(query);

      // Assert
      expect(result, ['Banana']);
    });

    test('fetchFoodItems returns an empty list when no items match', () async {
      // Arrange
      final query = 'NonExistentItem';

      // Act
      final result = await repository.fetchFoodItems(query);

      // Assert
      expect(result, []);
    });

    test('fetchHistoryItems returns an empty list when no items match',
        () async {
      // Arrange
      final query = 'NonExistentItem';

      // Act
      final result = await repository.fetchHistoryItems(query);

      // Assert
      expect(result, []);
    });
  });
}
