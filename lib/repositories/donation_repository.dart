import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import 'package:shelfaware_app/models/donation.dart';

class DonationRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore _firestore;

  DonationRepository({required this.auth, required FirebaseFirestore firestore}) : _firestore = firestore;

Future<List<DonationLocation>> fetchDonationLocations(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('donations').get();
      final donations = snapshot.docs.map((doc) {
        var donation = DonationLocation.fromFirestore(doc.data() as Map<String, dynamic>);
        if (donation.id != userId) {
          return donation;
        }
        return null;
      }).whereType<DonationLocation>().toList();
      return donations;
    } catch (e) {
      print('Error fetching donation locations: $e');
      return [];
    }
  }




  // Remove a donation from the database
  Future<void> removeDonation(String donationId) async {
    try {
      // Remove the donation from 'donations' collection
      await _firestore.collection('donations').doc(donationId).delete();
    } catch (e) {
      throw Exception("Error removing donation: $e");
    }
  }


  // Remove the donation from the user's donation list
  Future<void> removeUserDonation(String userId, String donationId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'myDonations': FieldValue.arrayRemove([donationId]),
      });
    } catch (e) {
      throw Exception("Error removing donation from user: $e");
    }
  }




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



Future<String?> getAssigneeProfileImage(String donationId) async {
  try {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Step 1: Get the assignedTo ID from the donations collection
    DocumentSnapshot donationDoc = await firestore
        .collection('donations') // Adjust if your collection name is different
        .doc(donationId)
        .get();

    if (donationDoc.exists && donationDoc.data() != null) {
      String? assignedToId = donationDoc.get('assignedTo');

      if (assignedToId != null && assignedToId.isNotEmpty) {
        // Step 2: Use the assignedTo ID to fetch the profileImageUrl from the users collection
        DocumentSnapshot userDoc = await firestore
            .collection('users') // Adjust if needed
            .doc(assignedToId)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          return userDoc.get('profileImageUrl'); // Ensure this matches your Firestore field
        }
      }
    }
    print("No assigned user found or user profile does not exist.");
    return null;
  } catch (e) {
    print("Error fetching profile image: $e");
    return null;
  }
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



  // Add a new donation to the database
  Future<void> addDonation(Map<String, dynamic> donationData) async {
    try {
      final String donationId = _firestore.collection('donations').doc().id;

      // Ensure donorId is set in the donationData map
      final User? currentUser = auth.currentUser;
      if (currentUser == null) {
        throw Exception("User is not authenticated");
      }
      final String userId = currentUser.uid;
    

      // Prepare donation data and add to 'donations' collection
      donationData['donationId'] = donationId;
          donationData['donorId'] = userId; // Ensure donorId is set in the donationData map
      await _firestore.collection('donations').doc(donationId).set(donationData);

      // Update the user's donation list with the new donation
      await _firestore.collection('users').doc(userId).update({
        'myDonations': FieldValue.arrayUnion([donationId]),
      });
    } catch (e) {
      throw Exception("Error adding donation: $e");
    }
  }



  // Remove a food item from the database
  Future<void> removeFoodItem(String id) async {
    await _firestore.collection('foodItems').doc(id).delete();
  }



  Future<String?> uploadDonationImage(File image) async {
    final String userId = auth.currentUser!.uid;
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

      var donationDoc = await _firestore.collection('donations').doc(donationId).get();
      if (donationDoc.exists) {
        var donationData = donationDoc.data() as Map<String, dynamic>;
        if (donationData['assignedTo'] == requestDoc['requesterId']) {
          await _firestore.collection('donations').doc(donationId).update({
            'status': 'available',
            'assignedTo': FieldValue.delete(),
            'assignedToName': FieldValue.delete(),
          });
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Donation request withdrawn successfully')),
      );
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
