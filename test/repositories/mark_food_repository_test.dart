import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfaware_app/models/mark_food.dart';
import 'package:shelfaware_app/repositories/mark_food_respository.dart';

import 'favourites_repository_test.mocks.dart';

void main() {
  late MarkFoodRepository markFoodRepository;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    markFoodRepository = MarkFoodRepository(firebaseFirestore: fakeFirestore, auth: mockAuth);
  });

  group('MarkFoodRepository', () {
    test('fetchFoodItem returns MarkFood if document exists', () async {
      final documentId = 'testId';
      final data = {'productName': 'Apple', 'quantity': 10};
      await fakeFirestore.collection('foodItems').doc(documentId).set(data);

      final result = await markFoodRepository.fetchFoodItem(documentId);

      expect(result, isNotNull);
      expect(result!.productName, 'Apple');
      expect(result.quantity, 10);
    });

    test('fetchFoodItem returns null if document does not exist', () async {
      final documentId = 'testId';

      final result = await markFoodRepository.fetchFoodItem(documentId);

      expect(result, isNull);
    });

    test('updateFoodItem updates the document', () async {
      final foodItem = MarkFood(id: 'testId', productName: 'Apple', quantity: 10);
      await fakeFirestore.collection('foodItems').doc(foodItem.id).set({'productName': 'Apple', 'quantity': 5});

      await markFoodRepository.updateFoodItem(foodItem);

      final updatedDoc = await fakeFirestore.collection('foodItems').doc(foodItem.id).get();
      expect(updatedDoc.data(), {'productName': 'Apple', 'quantity': 10});
    });

    test('deleteFoodItem deletes the document', () async {
      final documentId = 'testId';
      await fakeFirestore.collection('foodItems').doc(documentId).set({'productName': 'Apple', 'quantity': 10});

      await markFoodRepository.deleteFoodItem(documentId);

      final deletedDoc = await fakeFirestore.collection('History').doc(documentId).get();
      expect(deletedDoc.exists, isFalse);
    });

    test('addHistory adds a new document to history collection', () async {
      final historyData = {'action': 'added', 'timestamp': Timestamp.now()};

      await markFoodRepository.addHistory(historyData);

      final historyCollection = await fakeFirestore.collection('history').get();
      expect(historyCollection.docs.length, 1);
      expect(historyCollection.docs.first.data(), historyData);
    });
  });
}
