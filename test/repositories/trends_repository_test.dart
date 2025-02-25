import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelfaware_app/repositories/trends_repository.dart';

import 'favourites_repository_test.mocks.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}

class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock implements QueryDocumentSnapshot<Map<String, dynamic>> {}

void main() {
  group('TrendsRepository', () {
    late TrendsRepository trendsRepository;
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;

    setUp(() {
      // Use FakeFirebaseFirestore instead of a Mockito mock
      fakeFirestore = FakeFirebaseFirestore();
      // For FirebaseAuth, you can use a mock from firebase_auth_mocks
      mockAuth = MockFirebaseAuth();
      trendsRepository = TrendsRepository(firestore: fakeFirestore, auth: mockAuth);
    });

    test('fetchHistoryData returns list of history data', () async {
      final collectionReference = fakeFirestore.collection('history');
      await collectionReference.add({'userId': 'userId', 'key': 'value'});

      final result = await trendsRepository.fetchHistoryData('userId');

      expect(result, isA<List<Map<String, dynamic>>>());
      expect(result.length, 1);
      result[0].remove('userId');
      expect(result[0], {'key': 'value'});
    });

    test('fetchDonations returns list of donations', () async {
      final collectionReference = fakeFirestore.collection('donations');
      await collectionReference.add({'key': 'value'});

      final result = await trendsRepository.fetchDonations();

      expect(result, isA<List<Map<String, dynamic>>>());
      expect(result.length, 1);
      expect(result[0], {'key': 'value'});
    });

    test('fetchJoinDuration returns join duration in days', () async {
      final collectionReference = fakeFirestore.collection('users');
      await collectionReference.doc('userId').set({'joinDate': Timestamp.fromDate(DateTime.now().subtract(Duration(days: 5)))});

      final result = await trendsRepository.fetchJoinDuration('userId');

      expect(result, '5 days');
    });

    test('fetchJoinDuration returns join duration in hours', () async {
      final collectionReference = fakeFirestore.collection('users');
      await collectionReference.doc('userId').set({'joinDate': Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 5)))});

      final result = await trendsRepository.fetchJoinDuration('userId');

      expect(result, '5 hours');
    });

    test('fetchJoinDuration returns "Unknown duration" if user does not exist', () async {
      final result = await trendsRepository.fetchJoinDuration('userId');

      expect(result, 'Unknown duration');
    });
  });
}
