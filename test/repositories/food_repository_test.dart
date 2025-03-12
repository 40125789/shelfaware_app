import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfaware_app/repositories/food_repository.dart';

void main() {
  late FoodRepository repository;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;

  setUp(() {
    // Use FakeFirebaseFirestore instead of a Mockito mock
    fakeFirestore = FakeFirebaseFirestore();
    // For FirebaseAuth, you can use a mock from firebase_auth_mocks
    mockAuth = MockFirebaseAuth();
    repository = FoodRepository(firestore: fakeFirestore, auth: mockAuth);
  });

  test('fetchFilterOptions returns list of categories', () async {
    // Arrange: Add category data to fake Firestore with the correct field name
    final categoryData = {'Food Type': 'Fruit'};
    await fakeFirestore.collection('categories').add(categoryData);

    // Act: Call fetchFilterOptions method
    final categories = await repository.fetchFilterOptions();

    // Assert: Verify the category data is returned
    expect(categories, ['Fruit']);
  });

  test('deleteFoodItem deletes a food item', () async {
    await repository.deleteFoodItem('testId');
    final doc = fakeFirestore.collection('foodItems').doc('testId');
    expect((await doc.get()).exists, false);
  });

  test('fetchUserIngredients returns list of ingredients', () async {
    // Arrange: Add a sample food item to fake Firestore
    final userId = 'testUserId';
    final foodItemData = {'productName': 'Apple', 'userId': userId};
    await fakeFirestore.collection('foodItems').add(foodItemData);

    // Act: Call the fetchUserIngredients method
    final ingredients = await repository.fetchUserIngredients(userId);

    // Assert: Verify the ingredients list contains 'Apple'
    expect(ingredients, ['Apple']);
  });

  test('addFoodItem adds a food item', () async {
    final foodItemData = {'productName': 'Banana'};
    await repository.addFoodItem(foodItemData);
    final querySnapshot = await fakeFirestore.collection('foodItems').get();
    expect(querySnapshot.docs.first['productName'], 'Banana');
  });

  test('getUserFoodItems returns a stream of user food items', () async {
    // Arrange: Add a sample food item to fake Firestore
    final userId = 'userId';
    final foodItemData = {'name': 'Apple', 'userId': userId};
    await fakeFirestore.collection('foodItems').add(foodItemData);

    // Act: Call the getUserFoodItems method
    final stream = repository.getUserFoodItems(userId);
    final snapshot = await stream.first;

    // Assert: Verify the food item is returned
    expect(
        (snapshot[0].data() as Map<String, dynamic>)['name'], equals('Apple'));
  });

  test('getFoodItemById returns a food item', () async {
    final docRef = fakeFirestore.collection('foodItems').doc('testId');
    await docRef.set({'productName': 'Apple'});

    final foodItem = await repository.getFoodItemById('testId');
    expect(foodItem['productName'], 'Apple');
  });

  test('getCategories returns list of category documents', () async {
    await fakeFirestore.collection('categories').add({'name': 'Fruit'});

    final categories = await repository.getCategories();
    expect(categories.first['name'], 'Fruit');
  });
}
