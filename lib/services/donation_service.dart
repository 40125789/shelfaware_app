import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shelfaware_app/repositories/donation_repository.dart';
import 'package:shelfaware_app/services/food_item_service.dart';
import 'package:shelfaware_app/components/donation_photo_form.dart'; // Adjust the path as necessary
import 'package:shelfaware_app/services/dialog_service.dart';

class DonationService {
  final DonationRepository _donationRepository = DonationRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );
  static final FoodItemService _fooditemService = FoodItemService();

  static Future<void> donateFoodItem(
      BuildContext context, String id, Position position) async {
    try {
      // Fetch the food item document
      Map<String, dynamic>? foodItemDoc =
          await _fooditemService.fetchFoodItemById(id);
      if (foodItemDoc == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Food item not found.")),
        );
        return;
      }

     // Check if the item is expired
      Timestamp expiryTimestamp = foodItemDoc['expiryDate'];
      DateTime expiryDate = expiryTimestamp.toDate();
      if (expiryDate.isBefore(DateTime.now())) {
        DialogService.showExpiredItemDialog(context);
        return;
      }


      // Get the user's location
      Position location = await _getUserLocation();

      // Show the DonationPhotoForm as a modal bottom sheet
      Map<String, String>? formData =
          await showModalBottomSheet<Map<String, String>>(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return AddPhotoAndDetailsForm(
            onPhotoAdded: (String imageUrl) {
              // You can keep this empty or update the state if needed
            },
            onDetailsAdded: (String pickupTimes, String pickupInstructions) {
              // You can keep this empty or update the state if needed
            },
            onFormSubmitted: (Map<String, String> formData) {
              // No need to pop here, handled within the form
            },
          );
        },
      );

      // Check if form data is returned or if the user canceled the form
      if (formData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Donation cancelled.")),
        );
        return;
      }

// Process the form data once it's returned
      print("Form Data received: $formData");

// Proceed with any additional processing after modal closes

      // Prepare donation data
      final String donorId = FirebaseAuth.instance.currentUser!.uid;
      final String donorEmail = FirebaseAuth.instance.currentUser!.email!;

      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(donorId)
          .get();
      final String donorName = userDoc['firstName'];

      final String donationId =
          FirebaseFirestore.instance.collection('donations').doc().id;

      foodItemDoc['donorId'] = donorId;
      foodItemDoc['donorName'] = donorName;
      foodItemDoc['donorEmail'] = donorEmail;
      foodItemDoc['donated'] = true;
      foodItemDoc['donatedAt'] = Timestamp.now();
      foodItemDoc['status'] = 'available';
      foodItemDoc['donationId'] = donationId;
      foodItemDoc['pickupTimes'] = formData['pickupTimes'] ?? '';
      foodItemDoc['pickupInstructions'] = formData['pickupInstructions'] ?? '';

      // If location exists in the user's document, use that, otherwise use GeoLocator location
      if (userDoc['location'] != null) {
        GeoPoint userLocation = userDoc['location'];
        foodItemDoc['location'] =
        GeoPoint(userLocation.latitude, userLocation.longitude);
      } else {
        foodItemDoc['location'] =
        GeoPoint(location.latitude, location.longitude);
      }

      if (formData['imageUrl'] != null) {
        foodItemDoc['imageUrl'] = formData['imageUrl'];
      }

      // Add the item to the donations collection
      await FirebaseFirestore.instance
          .collection('donations')
          .doc(donationId)
          .set(foodItemDoc);

      // Remove the item from the foodItems collection
      await FirebaseFirestore.instance.collection('foodItems').doc(id).delete();

      // Update the user's document with the new donation
      await FirebaseFirestore.instance.collection('users').doc(donorId).update({
        'myDonations': FieldValue.arrayUnion([donationId]),
      });

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Donation added successfully.")),
      );
        } catch (e) {
      print('Error donating food item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to donate item: $e")),
      );
        }
      }



  // Fetch donation details by donationId
  Future<Map<String, dynamic>> getDonationDetails(String donationId) async {
    return await _donationRepository.getDonationDetails(donationId);
  }

  // Fetch donations for a specific user
  Stream<List<Map<String, dynamic>>> getDonations(String userId, String donationId) {
    return _donationRepository.getDonations(userId, donationId);
  }

  // Fetch all donations
  Stream<List<Map<String, dynamic>>> getAllDonations() {
    return _donationRepository.getAllDonations();
  }

  // Fetch sent donation requests for a specific user
  Stream<List<Map<String, dynamic>>> getSentDonationRequests(String userId) {
    return _donationRepository.getSentDonationRequests(userId);
  }

  // Fetch donation request count for a specific donation
  Stream<int> getDonationRequestCount(String donationId, String userId) {
    return _donationRepository
        .getDonationRequests(donationId)
        .map((requests) => requests.length);
  }

  // Accept a donation request
  Future<void> acceptDonationRequest(
      String donationId, String requestId, String requesterId) async {
    await _donationRepository.acceptDonationRequest(
        donationId, requestId, requesterId);
  }

  // Decline a donation request
  Future<void> declineDonationRequest(String requestId) async {
    await _donationRepository.declineDonationRequest(requestId);
  }

  // Update donation request status
  Future<void> updateDonationRequestStatus(
      String donationId, String status, String requestId) async {
    await _donationRepository.updateDonationRequestStatus(donationId, status, requestId);
  }

  // Fetch requester's name by userId
  Future<String> getRequesterName(String userId) async {
    return await _donationRepository.getRequesterName(userId);
  }

  // Add a new donation
  Future<void> addDonation(Map<String, dynamic> donationData) async {
    await _donationRepository.addDonation(donationData);
  }

  // Remove a food item
  Future<void> removeFoodItem(String id) async {
    await _donationRepository.removeFoodItem(id);
  }

  // Update user donations
  Future<void> updateUserDonations(String userId, String donationId) async {
    await _donationRepository.updateUserDonations(userId, donationId);
  }

  // Upload donation image
  Future<String?> uploadDonationImage(File image) async {
    return await _donationRepository.uploadDonationImage(image);
  }

  // Withdraw a donation request
  Future<void> withdrawDonationRequest(
      BuildContext context, String requestId) async {
    await _donationRepository.withdrawDonationRequest(context, requestId);
  }

  // Check if user has already reviewed a donation
  Future<bool> hasUserAlreadyReviewed(String donationId, String userId) async {
    return await _donationRepository.hasUserAlreadyReviewed(donationId, userId);
  }

  static Future<Position> _getUserLocation() async {
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future updateDonationStatus(String donationId, String status) async {
    return await FirebaseFirestore.instance
        .collection('donations')
        .doc(donationId)
        .update({'status': status});
  }

  Stream<List<Map<String, dynamic>>> getDonationRequests(String donationId) {
    final String donorId = FirebaseAuth.instance.currentUser!.uid;
    return _donationRepository.getDonationRequests(donationId).map((requests) {
      return requests
          .where((request) => request['requesterId'] != donorId)
          .toList();
    });
  }
}
