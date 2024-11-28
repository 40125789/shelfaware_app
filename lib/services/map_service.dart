import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shelfaware_app/models/donation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MapService {
  // Updated method to handle both user donations and predefined donation points
  Set<Marker> getMarkers(
    LatLng currentLocation,
    List<DonationLocation> donationLocations,  // List of user donation locations
    List<LatLng> predefinedDonationPoints, 
    String userId, // Pass the logged-in user's ID
    Function(DonationLocation donation) onMarkerTap, // Callback for marker taps
  ) {
    final markers = <Marker>{};

    // Marker for current location (red)
    markers.add(
      Marker(
        markerId: MarkerId('currentLocation'),
        position: currentLocation,
        infoWindow: InfoWindow(title: "You are here"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed), // Red icon for current location
      ),
    );

    // Add donation markers (excluding donations from the logged-in user)
    for (var i = 0; i < donationLocations.length; i++) {
      final donation = donationLocations[i];
      // Only add markers for donations where the donorId is not the logged-in user's ID
      if (donation.donorId != userId) {
        markers.add(
          Marker(
            markerId: MarkerId('donation_${donation.itemName}_$i'), // Make the ID unique
            position: donation.location,
            infoWindow: InfoWindow(
              title: donation.itemName,
              snippet: 'Expires: ${donation.expiryDate}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen), // Green icon for donation markers
            onTap: () => onMarkerTap(donation), // Tap handler
          ),
        );
      }
    }

    // Add predefined donation points (if any)
    for (var i = 0; i < predefinedDonationPoints.length; i++) {
      markers.add(
        Marker(
          markerId: MarkerId('donationPoint_$i'),
          position: predefinedDonationPoints[i],
          infoWindow: InfoWindow(title: "Donation Center $i"),
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


