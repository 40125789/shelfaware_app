import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:geolocator/geolocator.dart';

import 'package:shelfaware_app/services/food_item_service.dart';


class DonationService {
  static final FoodItemService _fooditemService = FoodItemService();
  static Future<void> donateFoodItem(BuildContext context, String id, Position position) async {
    try {
      // Fetch the food item document
      Map<String, dynamic> ? foodItemDoc = await _fooditemService.fetchFoodItemById(id);
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
        _showExpiredItemDialog(context);
        return;
      }

      // Get the user's location
      Position location = await _getUserLocation();
      

      // Ask if the user wants to add a photo
      bool takePhoto = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              "Would you like to add a photo?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center, // Ensures title is centered
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image with adjusted size and border for better presentation
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey, width: 1),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/camera.png', // Your image path here
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Improved text with better alignment and styling
                Text(
                  "Adding a photo of your food item can help attract more attention and assist others in assessing its quality. Photos make listings stand out and feel more trustworthy.",
                  textAlign: TextAlign.center, // Centers the content text
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
            actions: [
              // Simplified actions with consistent styling
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  "No, skip",
                  style: TextStyle(color: Colors.blueAccent),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Yes, add photo",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );

      String? imageUrl;
      if (takePhoto) {
        // Show the Lottie loading animation dialog after the photo is taken
        showDialog(
          context: context,
          barrierDismissible: false, // Prevent closing the dialog
          builder: (BuildContext context) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RepaintBoundary(
                    child: Lottie.network(
                      'https://lottie.host/726edc0a-86f8-4d94-95fc-3df9de90d8fe/c2E6eYh86Z.json',
                      frameRate: FrameRate.max,
                      repeat: true,
                      animate: true,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Donating your food...",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          },
        );

        // Let user pick an image
        final picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 800,
          maxHeight: 800,
        );

        if (image != null) {
          final String userId = FirebaseAuth.instance.currentUser!.uid;
          final String imageName =
              "donation_${DateTime.now().millisecondsSinceEpoch}.jpg";
          final Reference storageRef = FirebaseStorage.instance
              .ref()
              .child('donation_images/$userId/$imageName');
          final TaskSnapshot snapshot =
              await storageRef.putFile(File(image.path)).whenComplete(() {});

          // Get image URL after upload
          imageUrl = await snapshot.ref.getDownloadURL();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("No photo captured. Proceeding without photo.")),
          );
        }

        Navigator.pop(context); // Dismiss loading dialog after image upload
      }

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

      // If location exists in the user's document, use that, otherwise use GeoLocator location
      if (userDoc['location'] != null) {
        GeoPoint userLocation = userDoc['location'];
        foodItemDoc['location'] =
            GeoPoint(userLocation.latitude, userLocation.longitude);
      } else {
        foodItemDoc['location'] =
            GeoPoint(location.latitude, location.longitude);
      }

      if (imageUrl != null) {
        foodItemDoc['imageUrl'] = imageUrl;
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Item donated successfully.")),
      );
    } catch (e) {
      print('Error donating food item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to donate item: $e")),
      );
    }
  }

  static void _showExpiredItemDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Donation Alert!"),
          content: Text("This item has expired and cannot be donated."),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  static Future<Position> _getUserLocation() async {
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }
}
