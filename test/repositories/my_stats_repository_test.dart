import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfaware_app/repositories/my_stats_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('StatsRepository', () {
    late StatsRepository statsRepository;
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      statsRepository = StatsRepository(firestore: fakeFirestore);
    });

    final userId = 'testUserId';
    final date = DateTime(2023, 10, 1);

    test('fetchUserStats returns correct UserStats', () async {
      final collectionReference = fakeFirestore.collection('history');
      await collectionReference.add({
        'userId': userId,
        'updatedOn': Timestamp.fromDate(date),
        'status': 'consumed'
      });

      final donationCollectionReference = fakeFirestore.collection('donations');
      await donationCollectionReference.add({
        'userId': userId,
        'addedOn': Timestamp.fromDate(date),
        'status': 'Picked Up',
        'productName': 'Apple'
      });

      final userStats = await statsRepository.fetchUserStats(userId, date);

      expect(userStats.consumed, 1);
      expect(userStats.discarded, 0);
      expect(userStats.donated, 1);
    });

    test('fetchConsumedItems returns correct list of consumed items', () async {
      final collectionReference = fakeFirestore.collection('history');
      await collectionReference.add({
        'userId': userId,
        'updatedOn': Timestamp.fromDate(date),
        'status': 'consumed',
        'productName': 'Apple'
      });

      final consumedItems =
          await statsRepository.fetchConsumedItems(userId, date);

      expect(consumedItems, ['Apple']);
    });

    test('fetchDiscardedItems returns correct list of discarded items',
        () async {
      final collectionReference = fakeFirestore.collection('history');
      await collectionReference.add({
        'userId': userId,
        'updatedOn': Timestamp.fromDate(date),
        'status': 'discarded',
        'productName': 'Banana'
      });

      final discardedItems =
          await statsRepository.fetchDiscardedItems(userId, date);

      expect(discardedItems, ['Banana']);
    });

    test('fetchDonatedItems returns correct list of donated items', () async {
      final collectionReference = fakeFirestore.collection('donations');
      await collectionReference.add({
        'userId': userId,
        'addedOn': Timestamp.fromDate(date),
        'status': 'Picked Up',
        'productName': 'Orange'
      });

      final donatedItems =
          await statsRepository.fetchDonatedItems(userId, date);

      expect(donatedItems, ['Orange']);
    });
  });
}
