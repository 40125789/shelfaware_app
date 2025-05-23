import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shelfaware_app/models/donation_request.dart';

class DonationRequestRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DonationRequestRepository(
      {required FirebaseFirestore firebaseFirestore,
      required FirebaseAuth firebaseAuth})
      : _firestore = firebaseFirestore,
        _auth = firebaseAuth;

  Future<DocumentSnapshot> getDonationById(String donationId) async {
    try {
      return await _firestore.collection('donations').doc(donationId).get();
    } catch (e) {
      print('Error fetching donation: $e');
      rethrow;
    }
  }

  Future<void> addDonationRequest(DonationRequest request) async {
    try {
      DocumentReference docRef =
          await _firestore.collection('donationRequests').add(request.toMap());
      await docRef.update({'requestId': docRef.id});
    } catch (e) {
      throw Exception('Error adding donation request: $e');
    }
  }

  Future<String?> getUserProfileImageUrl(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      return userDoc['profileImageUrl'] ?? '';
    } catch (e) {
      throw Exception('Error fetching user profile image URL: $e');
    }
  }

  Future<bool> checkIfAlreadyRequested(
      String donationId, String requesterId) async {
    final donationRequestDoc = await _firestore
        .collection('donationRequests')
        .where('donationId', isEqualTo: donationId)
        .where('requesterId', isEqualTo: requesterId)
        .get();

    return donationRequestDoc.docs.isNotEmpty;
  }
}
