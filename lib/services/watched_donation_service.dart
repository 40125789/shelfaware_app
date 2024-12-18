import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WatchlistService {
  final String userId;

  WatchlistService({required this.userId});

  // Check if a donation is already in the user's watchlist
  Future<bool> isDonationInWatchlist(String donationId) async {
    DocumentSnapshot watchlistDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('watchlist')
        .doc(donationId)
        .get();
    return watchlistDoc.exists;
  }

  // Toggle the watchlist status (add or remove)
  Future<void> toggleWatchlist(String donationId, Map<String, dynamic> donationData) async {
    bool isInWatchlist = await isDonationInWatchlist(donationId);
    
    if (isInWatchlist) {
      // If the donation is in the watchlist, remove it
      await removeFromWatchlist(donationId);
    } else {
      // If the donation is not in the watchlist, add it
      await addToWatchlist(donationId, donationData);
    }
  }

  // Add donation to the user's watchlist
  Future<void> addToWatchlist(String donationId, Map<String, dynamic> donationData) async {
    try {
      await FirebaseFirestore.instance
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

  // Remove donation from the user's watchlist
  Future<void> removeFromWatchlist(String donationId) async {
    try {
      await FirebaseFirestore.instance
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

