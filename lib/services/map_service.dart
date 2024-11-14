import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shelfaware_app/models/donation.dart';



class MapService {
  // Updated method to handle both user donations and predefined donation points
  Set<Marker> getMarkers(
    LatLng currentLocation,
    List<DonationLocation> donationLocations,  // List of user donation locations
    List<LatLng> predefinedDonationPoints,  // Predefined donation points
  ) {
    final markers = <Marker>{};

    // Marker for current location
    markers.add(
      Marker(
        markerId: MarkerId('currentLocation'),
        position: currentLocation,
        infoWindow: InfoWindow(title: "You are here"),
      ),
    );

// Add donation markers
    for (var i = 0; i < donationLocations.length; i++) {
      final donation = donationLocations[i];
      markers.add(
        Marker(
          markerId: MarkerId('userDonation_$i'),
          position: donation.location,
          infoWindow: InfoWindow(
            title: donation.itemName,
            snippet: 'Expires: ${donation.expiryDate}',
          ),
        ),
      );
    }

    // Add predefined donation points (if any)
    for (var i = 0; i < predefinedDonationPoints.length; i++) {
      markers.add(
        Marker(
          markerId: MarkerId('donationPoint_$i'),
          position: predefinedDonationPoints[i],
          infoWindow: InfoWindow(title: "Donation Center $i"),
        ),
      );
    }

    return markers;
  }
}
