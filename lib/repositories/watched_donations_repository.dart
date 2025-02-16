import 'package:cloud_firestore/cloud_firestore.dart';


class WatchedDonationsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getWatchedDonations(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('watchlist')
        .snapshots();
  }

  Future<DocumentSnapshot> getDonorData(String donorId) {
    return _firestore.collection('users').doc(donorId).get();
  }

  Future<void> toggleWatchlist(String userId, String donationId, Map<String, dynamic> donation) async {
    bool isInWatchlist = await isDonationInWatchlist(userId, donationId);
    
    if (isInWatchlist) {
      await removeFromWatchlist(userId, donationId);
    } else {
      await addToWatchlist(userId, donationId, donation);
    }
  }

  Future<bool> isDonationInWatchlist(String userId, String donationId) async {
    DocumentSnapshot watchlistDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('watchlist')
        .doc(donationId)
        .get();
    return watchlistDoc.exists;
  }

  Future<void> addToWatchlist(String userId, String donationId, Map<String, dynamic> donationData) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('watchlist')
          .doc(donationId)
          .set({
        'productName': donationData['productName'],
        'status': donationData['status'],
        'expiryDate': donationData['expiryDate'],
        'location': donationData['location'],
        'donorName': donationData['donorName'],
        'imageUrl': donationData['imageUrl'],
        'addedOn': FieldValue.serverTimestamp(),
        'donorId': donationData['donorId'],
        'donationId': donationId,
        'isWatched': donationData['isWatched'] ?? true,
      });
    } catch (e) {
      throw Exception("Error adding to watchlist: $e");
    }
  }

  Future<void> removeFromWatchlist(String userId, String donationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('watchlist')
          .doc(donationId)
          .delete();
    } catch (e) {
      throw Exception("Error removing from watchlist: $e");
    }
  }
}