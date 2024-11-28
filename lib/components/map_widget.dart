import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show CameraPosition, GoogleMap, GoogleMapController, LatLng, Marker;

class MapWidget extends StatefulWidget {
  final LatLng initialPosition;
  final Set<Marker> markers;

  MapWidget({
    required this.initialPosition,
    required this.markers,
  });

  @override
  _MapWidgetState createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  late GoogleMapController mapController;

  @override
Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (_) {}, // Prevents parent swipe gestures
      onHorizontalDragUpdate: (_) {}, // Prevents parent swipe gestures
      behavior: HitTestBehavior.opaque, // Ensures touch events pass to GoogleMap
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: widget.initialPosition,
          zoom: 13, // Initial zoom level
        
        ),
        markers: widget.markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true, // Enable zoom controls (buttons)
        scrollGesturesEnabled: true, // Enable scroll gestures (drag to move the map)
        zoomGesturesEnabled: true,  // Enable pinch-to-zoom functionality
        rotateGesturesEnabled: true, // Allow map rotation
        tiltGesturesEnabled: true, // Allow map tilt
        onMapCreated: (GoogleMapController controller) {
          mapController = controller;
        },
   
      ),
    );
  }
}
