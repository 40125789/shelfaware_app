import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Import LatLng

class DonationLocation {
  final String id; // Unique identifier for the donation
  final LatLng location; // LatLng of the donation location
  final String itemName; // Name of the item being donated
  final String expiryDate; // Expiry date of the item
  final String status; // Status of the donation (available, claimed, etc.)

  DonationLocation({
    required this.id,
    required this.location,
    required this.itemName,
    required this.expiryDate,
    required this.status,
  });

  // Factory constructor to map Firestore data to DonationLocation model
  factory DonationLocation.fromFirestore(Map<String, dynamic> doc) {
    final geoPoint = doc['location'] as GeoPoint; // Retrieve the GeoPoint

    return DonationLocation(
      id: doc['donorId'] ?? '',
      location: LatLng(
          geoPoint.latitude, geoPoint.longitude), // Convert GeoPoint to LatLng
      itemName: doc['itemName'] ?? '',
      expiryDate: doc['expiryDate']
          .toDate()
          .toLocal()
          .toString(), // Convert timestamp to a readable string
      status: doc['status'] ?? 'available',
    );
  }
}
