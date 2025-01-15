import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shelfaware_app/models/trend_stats.dart';

class DataService {
  Future<List<TrendStats>> fetchTrendStats(bool isWeekly, String userId) async {
    var snapshot = await FirebaseFirestore.instance
        .collection('history')
        .where('userId', isEqualTo: userId) // Filter by userId
        .get();
        
    List<TrendStats> trendStats = [];

    for (var doc in snapshot.docs) {
      DateTime addedDate = (doc['addedOn'] as Timestamp).toDate();
      String status = doc['status'] ?? '';

      if (isWeekly) {
        int week = getWeekOfYear(addedDate);
        // Store and process data for weekly aggregation
      } else {
        int month = getMonth(addedDate);
        // Store and process data for monthly aggregation
      }
    }

    return trendStats;
  }

  int getWeekOfYear(DateTime date) {
    int dayOfYear = int.parse(DateFormat("D").format(date));
    return ((dayOfYear - 1) / 7).floor() + 1;
  }

  int getMonth(DateTime date) {
    return date.month;
  }
}
