// This file contains the MapWidget class which is a StatelessWidget that displays a GoogleMap widget with the initial position and markers provided.
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapWidget extends StatelessWidget {
  final LatLng initialPosition;
  final Set<Marker> markers;

  const MapWidget({required this.initialPosition, required this.markers});

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: initialPosition, zoom: 14),
      myLocationEnabled: true,
      markers: markers,
    );
  }
}
