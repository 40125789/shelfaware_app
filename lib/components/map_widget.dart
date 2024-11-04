import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapWidget extends StatelessWidget {
  final LatLng initialPosition;
  final Set<Marker> markers;

  MapWidget({
    required this.initialPosition,
    required this.markers,
  });

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialPosition,
        zoom: 13,
      ),
      markers: markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
    );
  }
}
