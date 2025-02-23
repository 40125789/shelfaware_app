// favourites_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:shelfaware_app/repositories/favourites_repository.dart'; // Adjust path as needed

void main() {
  late FavouritesRepository repository;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;

  setUp(() {
    // Use FakeFirebaseFirestore instead of a Mockito mock
    fakeFirestore = FakeFirebaseFirestore();
    // For FirebaseAuth, you can use a mock from firebase_auth_mocks
    mockAuth = MockFirebaseAuth();
    repository = FavouritesRepository(firestore: fakeFirestore, auth: mockAuth);
  });

  test('isFavourite returns true if recipe exists in favourites', () async {
    // Arrange: Add a document to fake Firestore.
    final recipeId = 'recipe123';
    await fakeFirestore
        .collection('favourites')
        .doc(recipeId)
        .set({'id': recipeId});

    // Act
    final result = await repository.isFavourite(recipeId);

    // Assert
    expect(result, true);
  });

  test('isFavourite returns false if recipe does not exist in favourites',
      () async {
    // Arrange
    final recipeId = 'recipe123';

    // Act
    final result = await repository.isFavourite(recipeId);

    // Assert
    expect(result, false);
  });

  test('addFavourite adds a new favourite recipe', () async {
    // Arrange
    final recipeData = {'id': 'recipe123', 'name': 'Recipe Name'};

    // Act
    await repository.addFavourite(recipeData);

    // Assert
    final doc =
        await fakeFirestore.collection('favourites').doc('recipe123').get();
    expect(doc.exists, isTrue);
    expect(doc.data()?['name'], equals('Recipe Name'));
  });

  test('removeFavourite removes a recipe from favourites', () async {
    // Arrange: Add a document first.
    final recipeId = 'recipe123';
    await fakeFirestore
        .collection('favourites')
        .doc(recipeId)
        .set({'id': recipeId});

    // Act
    await repository.removeFavourite(recipeId);

    // Assert
    final doc =
        await fakeFirestore.collection('favourites').doc(recipeId).get();
    expect(doc.exists, isFalse);
  });
}
