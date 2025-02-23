import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/src/fake_cloud_firestore_instance.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/src/firebase_auth_mocks_base.dart';


class WatchedDonationsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  WatchedDonationsRepository({required FirebaseFirestore firebaseFirestore, required FirebaseAuth firebaseAuth})
      : _firestore = firebaseFirestore,
        _auth = firebaseAuth;

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
        'pickupTimes': donationData['pickupTimes'],
        'pickupInstructions': donationData['pickupInstructions'],
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