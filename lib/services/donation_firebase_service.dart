import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DonationFireBaseService {
  Stream<List<Map<String, dynamic>>> getUserDonations(String userId) {
    return FirebaseFirestore.instance
        .collection('donations')
        .where('donorId', isEqualTo: userId)
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        return doc.exists ? Map<String, dynamic>.from(doc.data() as Map<String, dynamic>) : <String, dynamic>{};
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getSentDonationRequests(String userId) {
    return FirebaseFirestore.instance
        .collection('donationRequests')
        .where('requesterId', isEqualTo: userId)
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        return doc.exists ? Map<String, dynamic>.from(doc.data() as Map<String, dynamic>) : <String, dynamic>{};
      }).toList();
    });
  }


  Future<List<Map<String, dynamic>>> getDonations(String userId) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('donations')
        .where('status', isEqualTo: 'Picked Up')
        .get();

    return querySnapshot.docs.map((doc) {
      return doc.exists ? Map<String, dynamic>.from(doc.data() as Map<String, dynamic>) : <String, dynamic>{};
    }).toList();
  }


  Future<void> withdrawDonationRequest(BuildContext context, String requestId) async {
    try {
      var requestDoc = await FirebaseFirestore.instance
          .collection('donationRequests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        throw Exception('Donation request not found');
      }

      String donationId = requestDoc['donationId'];
      if (donationId.isEmpty) {
        throw Exception('Donation ID is missing from request document');
      }

      await requestDoc.reference.delete();

      await FirebaseFirestore.instance.collection('donations').doc(donationId).update({
        'status': 'available',
        'assignedTo': FieldValue.delete(),
        'assignedToName': FieldValue.delete(),
      }).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Donation request withdrawn and donation status updated to available')),
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
    final querySnapshot = await FirebaseFirestore.instance
        .collection('reviews')
        .where('donationId', isEqualTo: donationId)
        .where('reviewerId', isEqualTo: userId)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }
}