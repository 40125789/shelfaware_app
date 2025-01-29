import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shelfaware_app/models/donation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart'; // Import the ImageConfiguration class

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class MapService {
  // Updated method to handle both user donations and predefined donation points
  Future<Set<Marker>> getMarkers(
    LatLng currentLocation,
    List<DonationLocation> donationLocations, // List of user donation locations
    List<LatLng> predefinedDonationPoints,
    String userId, // Pass the logged-in user's ID
    Function(DonationLocation donation) onMarkerTap, // Callback for marker taps
  ) async {
    final markers = <Marker>{};

    // Marker for current location (red) with custom icon
    markers.add(
      Marker(
        markerId: MarkerId('currentLocation'),
        position: currentLocation,
        infoWindow: InfoWindow(title: "You are here"),
        icon: await BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(48, 48)), 'assets/custom_marker_home.png'), // Custom icon for user location
      ),
    );

    // Add donation markers (excluding donations from the logged-in user)
    for (var i = 0; i < donationLocations.length; i++) {
      final donation = donationLocations[i];
      // Only add markers for donations where the donorId is not the logged-in user's ID
      if (donation.donorId != userId) {
        // Parse the expiry date to DateTime and format it
        DateTime expiryDate = DateTime.parse(donation.expiryDate); // Assuming expiryDate is in ISO 8601 format
        String formattedExpiryDate =
            DateFormat('dd/MM/yyyy').format(expiryDate); // Format in UK format

        markers.add(
          Marker(
            markerId: MarkerId('donation_${donation.itemName}_$i'), // Make the ID unique
            position: donation.location,
            infoWindow: InfoWindow(
              title: donation.itemName,
              snippet: 'Expires: $formattedExpiryDate', // Use formatted date
            ),
            icon: await BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(48, 48)), 'assets/custom_marker_donation.png'), // Custom icon for donation markers
            onTap: () => onMarkerTap(donation), // Tap handler
          ),
        );
      }
    }

    // Add predefined donation points (if any) with custom markers
    for (var i = 0; i < predefinedDonationPoints.length; i++) {
      markers.add(
        Marker(
          markerId: MarkerId('donationPoint_$i'),
          position: predefinedDonationPoints[i],
          infoWindow: InfoWindow(title: "Donation Center $i"),
          icon: await BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(48, 48)), 'assets/custom_marker_predefined.png'), // Custom icon for predefined donation points
          onTap: () {
            // Handle tap for predefined points if needed
            print('Tapped predefined point $i');
          },
        ),
      );
    }

    return markers;
  }
}
