import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shelfaware_app/models/donation.dart';

class UserDonationMap extends StatelessWidget {
  final LatLng currentLocation;
  final Set<Marker> markers;

  UserDonationMap({required this.currentLocation, required this.markers, required void Function(BuildContext context, DonationLocation donation) onTap});

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: currentLocation,
        zoom: 14,
      ),
      markers: markers,
    );
  }
}
