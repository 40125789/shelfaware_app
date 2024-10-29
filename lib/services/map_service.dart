import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapService {
  Set<Marker> getMarkers(LatLng currentLocation, List<LatLng> donationPoints) {
    final markers = {
      Marker(
        markerId: MarkerId('currentLocation'),
        position: currentLocation,
        infoWindow: InfoWindow(title: "You are here"),
      ),
    };

    for (var i = 0; i < donationPoints.length; i++) {
      markers.add(
        Marker(
          markerId: MarkerId('donationPoint_$i'),
          position: donationPoints[i],
          infoWindow: InfoWindow(title: "Donation Center $i"),
        ),
      );
    }
    return markers;
  }
}