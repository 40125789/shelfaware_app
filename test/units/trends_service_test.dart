import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shelfaware_app/repositories/trends_repository.dart';
import 'package:shelfaware_app/services/trends_service.dart';

class MockTrendsRepository extends Mock implements TrendsRepository {}

void main() {
  late TrendsService trendsService;
  late MockTrendsRepository mockTrendsRepository;

  setUp(() {
    mockTrendsRepository = MockTrendsRepository();
    trendsService = TrendsService(mockTrendsRepository);
  });

  group('fetchTrends', () {
    final userId = 'testUserId';

    test('returns error when no data found', () async {
      when(mockTrendsRepository.fetchHistoryData(userId)).thenAnswer((_) async => []);
      when(mockTrendsRepository.fetchDonations()).thenAnswer((_) async => []);

      final result = await trendsService.fetchTrends(userId);

      expect(result, {"error": "No data found."});
    });

    test('returns trends data when data is available', () async {
      when(mockTrendsRepository.fetchHistoryData(userId)).thenAnswer((_) async => [
        {
          'productName': 'Apple',
          'category': 'Fruit',
          'reason': 'Expired',
          'addedOn': Timestamp.fromDate(DateTime.now().subtract(Duration(days: 5))),
          'updatedOn': Timestamp.fromDate(DateTime.now()),
          'status': 'discarded'
        }
      ]);
      when(mockTrendsRepository.fetchDonations()).thenAnswer((_) async => [
        {
          'donorId': userId,
          'assignedTo': 'anotherUserId',
          'status': 'Picked Up'
        }
      ]);

      final result = await trendsService.fetchTrends(userId);

      expect(result['foodInsights'], isNotNull);
      expect(result['donationStats'], isNotNull);
    });

    test('returns error when an exception occurs', () async {
      when(mockTrendsRepository.fetchHistoryData(userId)).thenThrow(Exception('Test exception'));

      final result = await trendsService.fetchTrends(userId);

      expect(result, containsPair("error", contains("Error fetching trends:")));
    });
  });

  group('fetchJoinDuration', () {
    final userId = 'testUserId';

    test('returns join duration', () async {
      when(mockTrendsRepository.fetchJoinDuration(userId)).thenAnswer((_) async => '1 year');

      final result = await trendsService.fetchJoinDuration(userId);

      expect(result, '1 year');
    });
  });

  group('_analyzeHistoryData', () {
    test('analyzes history data correctly', () {
      final historyData = [
        {
          'productName': 'Apple',
          'category': 'Fruit',
          'reason': 'Expired',
          'addedOn': Timestamp.fromDate(DateTime.now().subtract(Duration(days: 5))),
          'updatedOn': Timestamp.fromDate(DateTime.now()),
          'status': 'discarded'
        }
      ];
    }); 
  });
}

