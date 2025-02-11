import 'package:shelfaware_app/models/user_stats.dart';
import 'package:shelfaware_app/repositories/my_stats_repository.dart';

class StatsService {
  final StatsRepository _repository = StatsRepository();

  Future<UserStats> getUserStats(String userId, DateTime date) {
    return _repository.fetchUserStats(userId, date);
  }

  Future<List<String>> getConsumedItems(String userId, DateTime date) {
    return _repository.fetchConsumedItems(userId, date);
  }

  Future<List<String>> getDiscardedItems(String userId, DateTime date) {
    return _repository.fetchDiscardedItems(userId, date);
  }

  Future<List<String>> getDonatedItems(String userId, DateTime date) {
    return _repository.fetchDonatedItems(userId, date);
  }
}