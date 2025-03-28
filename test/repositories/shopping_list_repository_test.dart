import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:shelfaware_app/repositories/shopping_list_repository.dart'; // Adjust path as needed

void main() {
  late ShoppingListRepository repository;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  
  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    repository = ShoppingListRepository(firebaseFirestore: fakeFirestore, firebaseAuth: mockAuth);
  });

  test('addToShoppingList adds an item to Firestore', () async {
    final productName = 'Apples';
    final user = MockUser(uid: 'testUser');
    await mockAuth.signInAnonymously(); // Mock sign-in
    
    await repository.addToShoppingList(productName);
    
    final snapshot = await fakeFirestore.collection('shoppingList').get();
    expect(snapshot.docs.length, 1);
    expect(snapshot.docs.first.data()['productName'], equals(productName));
  });

  test('toggleAllPurchased updates all items to the given purchase status', () async {
    final user = MockUser(uid: 'testUser');
    await mockAuth.signInAnonymously();
    
    await fakeFirestore.collection('shoppingList').add({'user_id': user.uid, 'isPurchased': true});
    await repository.toggleAllPurchased(true);
    
    final snapshot = await fakeFirestore.collection('shoppingList').get();
    expect(snapshot.docs.first.data()['isPurchased'], isTrue);
  });

  test('updateQuantity correctly modifies the quantity of an item', () async {
    final user = MockUser(uid: 'testUser');
    await mockAuth.signInAnonymously();

    // Add an item to the shopping list
    final productName = 'Apples';
    await repository.addToShoppingList(productName);
    
    final snapshot = await fakeFirestore.collection('shoppingList').get();
    final productId = snapshot.docs.first.id;

    // Update the quantity
    await repository.updateQuantity(productId, 1);

    // Retrieve the updated item from Firestore
    final doc = await fakeFirestore.collection('shoppingList').doc(productId).get();
    expect(doc.data()?['quantity'], equals(2)); // The default quantity is 1, so after update it should be 2
  });

  test('removeFromShoppingList removes the specified item', () async {
    final productId = 'testProduct';
    await fakeFirestore.collection('shoppingList').doc(productId).delete();
    
    await repository.removeFromShoppingList(productId);
    
    final doc = await fakeFirestore.collection('shoppingList').doc(productId).get();
    expect(doc.exists, false);
  });

  test('markAsPurchased updates the purchase status of an item', () async {
    final productId = 'testProduct';
    await fakeFirestore.collection('shoppingList').doc(productId).set({'id': productId, 'isPurchased': false});
    
    await repository.markAsPurchased(productId, true);
    
    final doc = await fakeFirestore.collection('shoppingList').doc(productId).get();
    expect(doc.data()?['isPurchased'], isTrue);
  });

test('getShoppingList returns a list of user shopping items', () async {
  // Create a mock user with a specific UID
  final user = MockUser(uid: 'testUser');  // Ensure the test user ID is consistent

  // Sign in the mock user
  await mockAuth.signInAnonymously();
  mockAuth.mockUser = user; // Set the mock user as the current user

  // Add items to the shopping list with the same user_id as the mock user
  await fakeFirestore.collection('shoppingList').add({
    'user_id': user.uid,  // Use the correct user ID
    'productName': 'Bananas',
    'productId': 'bananasId',  // Adding productId field
    'isPurchased': false,
    'quantity': 1,
  });
  await fakeFirestore.collection('shoppingList').add({
    'user_id': user.uid,  // Ensure the user_id is correct
    'productName': 'Oranges',
    'productId': 'orangesId',  // Adding productId field
    'isPurchased': false,
    'quantity': 1,
  });

  // Fetch the shopping list
  final shoppingList = await repository.getShoppingList();

  // Check if the shopping list contains the added items
  expect(shoppingList.length, 2);
  expect(shoppingList.any((item) => item['productName'] == 'Bananas'), isTrue);
  expect(shoppingList.any((item) => item['productName'] == 'Oranges'), isTrue);

  // Optionally, you can also check for productId to ensure it's being set properly
  expect(shoppingList.any((item) => item['productId'] == 'bananasId'), isTrue);
  expect(shoppingList.any((item) => item['productId'] == 'orangesId'), isTrue);
});
}