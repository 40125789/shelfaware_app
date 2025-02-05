import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Import LatLng
import 'package:google_maps_flutter/google_maps_flutter.dart'
    show LatLng; // Import LatLng

class DonationLocation {
  final String id; // Unique identifier for the donation
  final LatLng location; // LatLng of the donation location
  final String itemName; // Name of the item being donated
  final String expiryDate; // Expiry date of the item
  final String status;
  final String donorId;
  final String donorName;
  final String donorEmail;
  final String donationId;
  final String addedOn;
  final String imageUrl;
  // Name of the donor
  // ID of the donor (must be a string)

  DonationLocation({
    required this.id,
    required this.location,
    required this.itemName,
    required this.expiryDate,
    required this.status,
    required this.donorId, // Required donorId
    required this.donorName,
    required this.donorEmail,
    required this.donationId,
    required this.addedOn,
    required this.imageUrl,
  });

  // Factory constructor to map Firestore data to DonationLocation model
  factory DonationLocation.fromFirestore(Map<String, dynamic> doc) {
    final geoPoint = doc['location'] as GeoPoint; // Retrieve the GeoPoint

    return DonationLocation(
        id: doc['id'] ?? '', // Unique donation ID
        location: LatLng(geoPoint.latitude,
            geoPoint.longitude), // Convert GeoPoint to LatLng
        itemName: doc['productName'] ?? '',
        expiryDate: (doc['expiryDate'] as Timestamp)
            .toDate()
            .toLocal()
            .toString(), // Convert Firestore Timestamp to a readable string
        status: doc['status'] ?? 'available',
        donorId:
            doc['donorId'] ?? '', // Get donor ID from the Firestore document
        donorName: doc['donorName'] ?? 'Anonymous', //

        donorEmail: doc['donorEmail'],
        donationId: doc['donationId'], 
        addedOn: (doc['addedOn'] as Timestamp)
            .toDate()
            .toLocal()
            .toString(), 
       imageUrl: doc['imageUrl'] ?? ''); 
  }

    // This method calculates the distance between two GeoPoints
  double filterDistance(double lat1, double lon1, double lat2, double lon2) {
    const double radius = 6371; // Radius of the Earth in kilometers
    double dLat = _degToRad(lat2 - lat1);
    double dLon = _degToRad(lon2 - lon1);
    double a = 
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return radius * c; // Returns distance in kilometers
  }

  double _degToRad(double deg) {
    return deg * (pi / 180);
  }
// Optional: Getter for user ID if needed
String get userId => donorId;

  get rating => null;

  get distanceText => null;

  get isNewlyAdded => null;

  get isExpiringSoon => null;
}
