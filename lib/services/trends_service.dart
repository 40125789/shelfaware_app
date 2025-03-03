import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelfaware_app/repositories/trends_repository.dart';

class TrendsService {
  final TrendsRepository _trendsRepository;

  TrendsService(this._trendsRepository);

  Future<Map<String, dynamic>> fetchTrends(String userId) async {
    try {
      List<Map<String, dynamic>> historyData = await _trendsRepository.fetchHistoryData(userId);
      List<Map<String, dynamic>> donations = await _trendsRepository.fetchDonations();

      if (historyData.isEmpty && donations.isEmpty) {
        return {"error": "No data found."};
      }

      Map<String, dynamic> foodInsights = _analyzeHistoryData(historyData);
      Map<String, dynamic> donationStats = _analyzeDonationStats(donations, userId);

      return {
        "foodInsights": foodInsights,
        "donationStats": donationStats,
      };
    } catch (e) {
      return {"error": "Error fetching trends: $e"};
    }
  }

  Future<String> fetchJoinDuration(String userId) {
    return _trendsRepository.fetchJoinDuration(userId);
  }

  Map<String, dynamic> _analyzeHistoryData(List<Map<String, dynamic>> historyData) {
    Map<String, int> foodItemCount = {};
    Map<String, int> foodCategoryCount = {};
    Map<String, int> discardReasonCount = {};
    int totalDiscardedItems = 0;
    Duration totalTimeBetweenAddingAndDiscarding = Duration.zero;

    for (var item in historyData) {
      String? foodItem = item['productName'];
      String? foodCategory = item['category'];
      String? reason = item['reason'];
      Timestamp? addedOn = item['addedOn'];
      Timestamp? discardedOn = item['updatedOn'];
      String? status = item['status'];

      if (status == 'discarded' && addedOn != null && discardedOn != null) {
        if (foodItem != null) {
          foodItemCount[foodItem] = (foodItemCount[foodItem] ?? 0) + 1;
        }

      if (foodCategory != null && foodCategory != "All") {
  foodCategoryCount[foodCategory] = (foodCategoryCount[foodCategory] ?? 0) + 1;
}


        if (reason != null) {
          discardReasonCount[reason] = (discardReasonCount[reason] ?? 0) + 1;
        }

        totalDiscardedItems++;
        totalTimeBetweenAddingAndDiscarding += discardedOn.toDate().difference(addedOn.toDate());
      }
    }

    String mostWastedFoodItem = foodItemCount.isNotEmpty
        ? foodItemCount.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : 'No data';
    String mostWastedFoodCategory = foodCategoryCount.isNotEmpty
        ? foodCategoryCount.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : 'No data';
    String mostCommonDiscardReason = discardReasonCount.isNotEmpty
        ? discardReasonCount.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : 'No data';
    Duration averageTimeBetweenAddingAndDiscarding = totalDiscardedItems > 0
        ? totalTimeBetweenAddingAndDiscarding ~/ totalDiscardedItems
        : Duration.zero;
    String formattedAverageTime = _formatDuration(averageTimeBetweenAddingAndDiscarding);

    return {
      "mostWastedFoodItem": mostWastedFoodItem,
      "mostWastedFoodCategory": mostWastedFoodCategory,
      "mostCommonDiscardReason": mostCommonDiscardReason,
      "averageTimeBetweenAddingAndDiscarding": formattedAverageTime,
    };
  }

  String _formatDuration(Duration duration) {
    int days = duration.inDays;
    int hours = duration.inHours % 24;
    if (days > 0) {
      return "$days days after adding";
    } else {
      return "$hours hours after adding";
    }
  }

  Map<String, dynamic> _analyzeDonationStats(List<Map<String, dynamic>> donations, String userId) {
    int givenDonations = 0;
    int receivedDonations = 0;

    for (var donation in donations) {
      if (donation['donorId'] == userId && donation['status'] == 'Picked Up') {
        givenDonations++;
      }
      if (donation['assignedTo'] == userId && donation['status'] == 'Picked Up') {
        receivedDonations++;
      }
    }

    return {
      "givenDonations": givenDonations,
      "receivedDonations": receivedDonations,
    };
  }
}