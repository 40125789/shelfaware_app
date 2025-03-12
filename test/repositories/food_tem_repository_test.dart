import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_auth_platform_interface/src/auth_credential.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shelfaware_app/repositories/food_repository.dart';

void main() {
  late FoodRepository foodItemRepository;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;

  setUp(() {
    // Use FakeFirebaseFirestore instead of a Mockito mock
    fakeFirestore = FakeFirebaseFirestore();
    // For FirebaseAuth, you can use a mock from firebase_auth_mocks
    mockAuth = MockFirebaseAuth();
    foodItemRepository =
        FoodRepository(firestore: fakeFirestore, auth: mockAuth);
  });

  test('addFoodItem adds a food item to the collection', () async {
    // Arrange: No need to mock Firestore methods with FakeFirestore
    final foodItemData = {'name': 'Apple'};

    // Act
    await foodItemRepository.addFoodItem(foodItemData);

    // Assert: Check if the document exists in the fake Firestore
    final doc = await fakeFirestore
        .collection('foodItems')
        .where('name', isEqualTo: 'Apple')
        .get();
    expect(doc.docs.isNotEmpty, isTrue);
    expect(doc.docs.first.data()['name'], equals('Apple'));
  });

  test('getUserFoodItems returns a stream of user food items', () async {
    // Arrange: Add a sample food item to fake Firestore
    final userId = 'userId';
    final foodItemData = {'name': 'Apple', 'userId': userId};
    await fakeFirestore.collection('foodItems').add(foodItemData);

    // Act: Call the getUserFoodItems method
    final stream = foodItemRepository.getUserFoodItems(userId);
    final snapshot = await stream.first;

    // Assert: Verify the food item is returned
    expect(
        (snapshot[0].data() as Map<String, dynamic>)['name'], equals('Apple'));
  });

  test('getFoodItemById returns a food item by id', () async {
    // Arrange: Add a food item to fake Firestore
    final foodItemData = {'name': 'Apple'};
    final docRef =
        await fakeFirestore.collection('foodItems').add(foodItemData);

    // Act: Call getFoodItemById method
    final result = await foodItemRepository.getFoodItemById(docRef.id);

    // Assert: Check if the returned data matches
    expect((result.data() as Map<String, dynamic>)['name'], equals('Apple'));
  });

  test('getCategories returns a list of categories', () async {
    // Arrange: Add category data to fake Firestore
    final categoryData = {'name': 'Fruit'};
    await fakeFirestore.collection('categories').add(categoryData);

    // Act: Call getCategories method
    final result = await foodItemRepository.getCategories();

    // Assert: Verify the category data is returned
    expect((result[0].data() as Map<String, dynamic>)['name'], equals('Fruit'));
  });
}
