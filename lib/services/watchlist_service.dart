
import 'package:cloud_firestore/cloud_firestore.dart';

class WatchlistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a donation to the watchlist
  Future<void> addToWatchlist(String userId, String donationId, Map<String, dynamic> donation) async {
    try {
      await _firestore.collection('watchlist').doc(userId).set({
        donationId: donation,
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error adding to watchlist: $e");
    }
  }

  // Remove a donation from the watchlist
  Future<void> removeFromWatchlist(String userId, String donationId) async {
    try {
      await _firestore.collection('watchlist').doc(userId).update({
        donationId: FieldValue.delete(),
      });
    } catch (e) {
      print("Error removing from watchlist: $e");
    }
  }

  // Check if a donation is in the watchlist
  Future<bool> isDonationInWatchlist(String userId, String donationId) async {
    try {
      var doc = await _firestore.collection('watchlist').doc(userId).get();
      return doc.exists && doc.data()?[donationId] != null;
    } catch (e) {
      print("Error checking watchlist: $e");
      return false;
    }
  }
}
