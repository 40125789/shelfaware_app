import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfaware_app/repositories/trends_repository.dart';
import 'package:shelfaware_app/services/trends_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

void main() {
  late TrendsService trendsService;
  late TrendsRepository trendsRepository;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    trendsRepository =
        TrendsRepository(firestore: fakeFirestore, auth: mockAuth);
    trendsService = TrendsService(trendsRepository);
  });

  group('fetchTrends', () {
    final userId = 'testUserId';

    test('returns error when no data found', () async {
      final result = await trendsService.fetchTrends(userId);
      expect(result, {"error": "No data found."});
    });

    test('returns trends data when history and donations exist', () async {
      // Arrange: Add mock history data
      await fakeFirestore.collection('history').add({
        'userId': userId,
        'productName': 'Apple',
        'category': 'Fruit',
        'reason': 'Expired',
        'addedOn':
            Timestamp.fromDate(DateTime.now().subtract(Duration(days: 5))),
        'updatedOn': Timestamp.fromDate(DateTime.now()),
        'status': 'discarded'
      });

      // Arrange: Add mock donation data
      await fakeFirestore.collection('donations').add({
        'donorId': userId,
        'assignedTo': 'anotherUserId',
        'status': 'Picked Up'
      });

      // Act
      final result = await trendsService.fetchTrends(userId);

      // Assert
      expect(result['foodInsights'], isNotNull);
      expect(result['donationStats'], isNotNull);
    });
  });


  group('_analyzeHistoryData', () {
    test('correctly analyzes history data', () async {
      final historyData = [
        {
          'productName': 'Apple',
          'category': 'Fruit',
          'reason': 'Expired',
          'addedOn':
              Timestamp.fromDate(DateTime.now().subtract(Duration(days: 5))),
          'updatedOn': Timestamp.fromDate(DateTime.now()),
          'status': 'discarded'
        }
      ];

      final insights = trendsService.analyzeHistoryData(historyData);

      expect(insights['mostWastedFoodItem'], 'Apple');
      expect(insights['mostWastedFoodCategory'], 'Fruit');
      expect(insights['mostCommonDiscardReason'], 'Expired');
      expect(insights['averageTimeBetweenAddingAndDiscarding'],
          contains("5 days"));
    });
  });

  group('_analyzeDonationStats', () {
    final userId = 'testUserId';

    test('correctly analyzes donation statistics', () {
      final donations = [
        {
          'donorId': userId,
          'assignedTo': 'anotherUserId',
          'status': 'Picked Up'
        },
        {'donorId': 'otherUser', 'assignedTo': userId, 'status': 'Picked Up'}
      ];

      final donationStats =
          trendsService.analyzeDonationStats(donations, userId);

      expect(donationStats['givenDonations'], 1);
      expect(donationStats['receivedDonations'], 1);
    });
  });
}
