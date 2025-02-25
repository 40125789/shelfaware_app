import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelfaware_app/models/user_stats.dart';

class StatsRepository {
 final FirebaseFirestore firestore;

  StatsRepository({required this.firestore});

  Future<UserStats> fetchUserStats(String userId, DateTime date) async {
    var snapshot = await firestore
        .collection('history')
        .where('userId', isEqualTo: userId)
        .get();

    int consumed = 0;
    int discarded = 0;
    int donated = 0;

    for (var doc in snapshot.docs) {
      DateTime addedDate = (doc['updatedOn'] as Timestamp).toDate();
      if (addedDate.year != date.year || addedDate.month != date.month) continue;

      String status = doc['status'] ?? '';
      if (status == 'consumed') {
        consumed++;
      } else if (status == 'discarded') {
        discarded++;
      }
    }

    var donationSnapshot = await firestore
        .collection('donations')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'Picked Up')
        .get();

    for (var doc in donationSnapshot.docs) {
      DateTime donationDate = (doc['addedOn'] as Timestamp).toDate();
      if (donationDate.year == date.year && donationDate.month == date.month) {
        donated++;
      }
    }

    return UserStats(
      consumed: consumed,
      discarded: discarded,
      donated: donated,
      mostWastedFoodItem: '',
      mostCommonCategory: '',
      avgShelfLife: 0,
    );
  }

  Future<List<String>> fetchConsumedItems(String userId, DateTime date) async {
    var snapshot = await firestore
        .collection('history')
        .where('userId', isEqualTo: userId)
        .get();

    List<String> consumedItems = [];

    for (var doc in snapshot.docs) {
      DateTime addedDate = (doc['updatedOn'] as Timestamp).toDate();
      if (addedDate.year != date.year || addedDate.month != date.month) continue;

      String status = doc['status'] ?? '';
      String foodName = doc['productName'] ?? '';

      if (status == 'consumed') {
        consumedItems.add(foodName);
      }
    }

    return consumedItems;
  }

  Future<List<String>> fetchDiscardedItems(String userId, DateTime date) async {
    var snapshot = await firestore
        .collection('history')
        .where('userId', isEqualTo: userId)
        .get();

    List<String> discardedItems = [];

    for (var doc in snapshot.docs) {
      DateTime addedDate = (doc['updatedOn'] as Timestamp).toDate();
      if (addedDate.year != date.year || addedDate.month != date.month) continue;

      String status = doc['status'] ?? '';
      String foodName = doc['productName'] ?? '';

      if (status == 'discarded') {
        discardedItems.add(foodName);
      }
    }

    return discardedItems;
  }

  Future<List<String>> fetchDonatedItems(String userId, DateTime date) async {
    var donationSnapshot = await firestore
        .collection('donations')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'Picked Up')
        .get();

    List<String> donatedItems = [];

    for (var doc in donationSnapshot.docs) {
      DateTime donationDate = (doc['addedOn'] as Timestamp).toDate();
      if (donationDate.year == date.year && donationDate.month == date.month) {
        String foodName = doc['productName'] ?? '';
        donatedItems.add(foodName);
      }
    }

    return donatedItems;
  }
}