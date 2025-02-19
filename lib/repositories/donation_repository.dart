import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class DonationRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getDonationDetails(String donationId) async {
    DocumentSnapshot donationDoc =
        await _firestore.collection('donations').doc(donationId).get();
    return donationDoc.exists ? donationDoc.data() as Map<String, dynamic> : {};
  }

  Stream<List<Map<String, dynamic>>> getDonationRequests(String donationId) {
    return _firestore
        .collection('donationRequests')
        .where('donationId', isEqualTo: donationId)
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        return doc.exists
            ? Map<String, dynamic>.from(doc.data())
            : <String, dynamic>{};
      }).toList();
    });
  }

  Future<String> getRequesterName(String requesterId) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(requesterId).get();
    return userDoc.exists
        ? (userDoc.data() as Map<String, dynamic>)['firstName'] ?? 'Unknown'
        : 'Unknown';
  }

  Future<void> updateDonationStatus(String donationId, String status) async {
    await _firestore
        .collection('donations')
        .doc(donationId)
        .update({'status': status});
  }

 Future<void> updateDonationRequestStatus(
      String donationId, String requestId, String status) async {
    await _firestore
        .collection('donationRequests')
        .doc(requestId)
        .update({'status': status, 'donationId': donationId});
  }


  Future<void> acceptDonationRequest(
      String donationId, String requestId, String requesterId) async {
    DocumentSnapshot userSnapshot =
        await _firestore.collection('users').doc(requesterId).get();
    String requesterName =
        userSnapshot.exists ? userSnapshot['firstName'] : 'Unknown';

    await _firestore.collection('donations').doc(donationId).update({
      'status': 'Reserved',
      'assignedTo': requesterId,
      'assignedToName': requesterName,
    });

    await _firestore.collection('donationRequests').doc(requestId).update({
      'status': 'Accepted',
      'assignedTo': requesterId,
      'assignedToName': requesterName,
    });

    final otherRequestsSnapshot = await _firestore
        .collection('donationRequests')
        .where('donationId', isEqualTo: donationId)
        .get();
    for (var doc in otherRequestsSnapshot.docs) {
      if (doc.id != requestId) {
        await _firestore
            .collection('donationRequests')
            .doc(doc.id)
            .update({'status': 'Declined'});
      }
    }
  }

  Future<void> declineDonationRequest(String requestId) async {
    await _firestore
        .collection('donationRequests')
        .doc(requestId)
        .update({'status': 'Declined'});
  }

  Future<Map<String, dynamic>?> fetchUserById(String userId) async {
    final DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();
    return userDoc.exists
        ? Map<String, dynamic>.from(userDoc.data() as Map<String, dynamic>)
        : null;
  }

  Future<void> addDonation(Map<String, dynamic> donationData) async {
    await _firestore
        .collection('donations')
        .doc(donationData['donationId'])
        .set(donationData);
  }

  Future<void> removeFoodItem(String id) async {
    await _firestore.collection('foodItems').doc(id).delete();
  }

  Future<void> updateUserDonations(String userId, String donationId) async {
    await _firestore.collection('users').doc(userId).update({
      'myDonations': FieldValue.arrayUnion([donationId]),
    });
  }

  Future<String?> uploadDonationImage(File image) async {
    final String userId = _auth.currentUser!.uid;
    final String imageName =
        "donation_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final Reference storageRef = FirebaseStorage.instance
        .ref()
        .child('donation_images/$userId/$imageName');
    final TaskSnapshot snapshot =
        await storageRef.putFile(image).whenComplete(() {});

    // Get image URL after upload
    return await snapshot.ref.getDownloadURL();
  }

  Stream<List<Map<String, dynamic>>> getSentDonationRequests(String userId) {
    return _firestore
        .collection('donationRequests')
        .where('requesterId', isEqualTo: userId)
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        return doc.exists
            ? Map<String, dynamic>.from(doc.data())
            : <String, dynamic>{};
      }).toList();
    });
  }

  // Fetch donations for a specific user
  Stream<List<Map<String, dynamic>>> getDonations(String userId, String donationId) {
    return _firestore
        .collection('donations')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        return doc.exists
            ? Map<String, dynamic>.from(doc.data())
            : <String, dynamic>{};
      }).toList();
    });
  }

  Future<void> withdrawDonationRequest(
      BuildContext context, String requestId) async {
    try {
      var requestDoc =
          await _firestore.collection('donationRequests').doc(requestId).get();

      if (!requestDoc.exists) {
        throw Exception('Donation request not found');
      }

      String donationId = requestDoc['donationId'];
      if (donationId.isEmpty) {
        throw Exception('Donation ID is missing from request document');
      }

      await requestDoc.reference.delete();

      await _firestore.collection('donations').doc(donationId).update({
        'status': 'available',
        'assignedTo': FieldValue.delete(),
        'assignedToName': FieldValue.delete(),
      }).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Donation request withdrawn and donation status updated to available')),
        );
      }).catchError((e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating donation: $e')),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error withdrawing request: $e')),
      );
    }
  }

  Future<bool> hasUserAlreadyReviewed(String donationId, String userId) async {
    final querySnapshot = await _firestore
        .collection('reviews')
        .where('donationId', isEqualTo: donationId)
        .where('reviewerId', isEqualTo: userId)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  Stream<List<Map<String, dynamic>>> getAllDonations() {
    return _firestore.collection('donations').snapshots().map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        return doc.exists
            ? Map<String, dynamic>.from(doc.data())
            : <String, dynamic>{};
      }).toList();
    });
  }
}
