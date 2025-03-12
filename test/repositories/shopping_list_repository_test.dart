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
    final productId = 'testProduct';
    await fakeFirestore.collection('shoppingList').doc(productId).set({'id': productId, 'quantity': 2});
    
    await repository.updateQuantity(productId, 1);
    
    final doc = await fakeFirestore.collection('shoppingList').doc(productId).get();
    expect(doc.data()?['quantity'], equals(3));
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
    final user = MockUser(uid: 'testUser');
    await mockAuth.signInAnonymously();
    
    await fakeFirestore.collection('shoppingList').add({'user_id': user.uid, 'productName': 'Bananas'});
    await fakeFirestore.collection('shoppingList').add({'user_id': user.uid, 'productName': 'Oranges'});
    
    final shoppingList = await repository.getShoppingList();
    
    expect(shoppingList.length, 2);
    expect(shoppingList.any((item) => item['productName'] == 'Bananas'), isTrue);
    expect(shoppingList.any((item) => item['productName'] == 'Oranges'), isTrue);
  });
}