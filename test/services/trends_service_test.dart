import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfaware_app/repositories/trends_repository.dart';
import 'package:shelfaware_app/services/trends_service.dart';

// A fake TrendsRepository for testing.
class FakeTrendsRepository implements TrendsRepository {
  @override
  FirebaseFirestore firestore;

  FakeTrendsRepository({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;
  Future<List<Map<String, dynamic>>> fetchHistoryData(String userId) async {
    // Return fake history data with one discarded item and one consumed item.
    return [
      {
        'productName': 'Apple',
        'category': 'Fruits',
        'reason': 'Expired',
        'addedOn': Timestamp.fromDate(DateTime(2023, 8, 1)),
        'updatedOn': Timestamp.fromDate(DateTime(2023, 8, 3)),
        'status': 'discarded',
      },
      {
        'productName': 'Banana',
        'category': 'Fruits',
        'reason': 'Spoiled',
        'addedOn': Timestamp.fromDate(DateTime(2023, 8, 2)),
        'updatedOn': Timestamp.fromDate(DateTime(2023, 8, 4)),
        'status': 'consumed',
      },
      // Data outside the target month (should be ignored)
      {
        'productName': 'Carrot',
        'category': 'Vegetables',
        'reason': 'Good',
        'addedOn': Timestamp.fromDate(DateTime(2023, 7, 15)),
        'updatedOn': Timestamp.fromDate(DateTime(2023, 7, 20)),
        'status': 'discarded',
      },
    ];
  }

  Future<List<Map<String, dynamic>>> fetchDonations() async {
    // Return fake donation data with one donation where user is donor and one where user is receiver.
    return [
      {
        'donorId': 'user123',
        'assignedTo': 'user456',
        'status': 'Picked Up',
      },
      {
        'donorId': 'user789',
        'assignedTo': 'user123',
        'status': 'Picked Up',
      },
    ];
  }

  Future<String> fetchJoinDuration(String userId) async {
    return "30 days";
  }
}

void main() {
  late TrendsService trendsService;
  late FakeTrendsRepository fakeRepository;
  const testUserId = 'user123';

  setUp(() {
    fakeRepository = FakeTrendsRepository();
    // Pass the fake repository to the TrendsService
    trendsService = TrendsService(fakeRepository);
  });

  group('TrendsService.fetchTrends', () {
    test('returns correct food insights and donation stats', () async {
      final trends = await trendsService.fetchTrends(testUserId);

      // Check that trends contains both foodInsights and donationStats.
      expect(trends.containsKey("foodInsights"), isTrue);
      expect(trends.containsKey("donationStats"), isTrue);

      // Validate the food insights.
      final foodInsights = trends["foodInsights"] as Map<String, dynamic>;
      // In our fake data, we have one consumed and one discarded item in August.
      expect(foodInsights, isNotEmpty);
      // For example, if your analysis logic sums counts, expect:
      // consumed: 1 (Banana), discarded: 1 (Apple)
      // (Adjust based on your _analyzeHistoryData logic)
      
      // Validate donation stats.
      final donationStats = trends["donationStats"] as Map<String, dynamic>;
      // In our fake data, for userId 'user123':
      // - As donor: 1 donation (first item, donorId == 'user123')
      // - As receiver: 1 donation (second item, assignedTo == 'user123')
      expect(donationStats["givenDonations"], equals(1));
      expect(donationStats["receivedDonations"], equals(1));
    });

    test('returns error if no history and donation data found', () async {
      // For this test, override the fake repository to return empty lists.
      fakeRepository = FakeTrendsRepositoryEmpty();
      trendsService = TrendsService(fakeRepository);

      final trends = await trendsService.fetchTrends(testUserId);
      expect(trends.containsKey("error"), isTrue);
      expect(trends["error"], equals("No data found."));
    });
  });

  group('TrendsService.fetchJoinDuration', () {
    test('returns the join duration string', () async {
      final joinDuration = await trendsService.fetchJoinDuration(testUserId);
      expect(joinDuration, isA<String>());
      expect(joinDuration, equals("30 days"));
    });
  });
}

/// A fake repository that returns empty lists for history and donations.
class FakeTrendsRepositoryEmpty extends FakeTrendsRepository {
  @override
  Future<List<Map<String, dynamic>>> fetchHistoryData(String userId) async => [];
  @override
  Future<List<Map<String, dynamic>>> fetchDonations() async => [];
}
