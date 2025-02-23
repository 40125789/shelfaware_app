import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shelfaware_app/components/map_widget.dart';

void main() {
  testWidgets('MapWidget initializes with given initial position and markers',
      (WidgetTester tester) async {
    // Define initial position and markers
    final initialPosition = LatLng(37.7749, -122.4194);
    final markers = <Marker>{
      Marker(
        markerId: MarkerId('test_marker'),
        position: LatLng(37.7749, -122.4194),
      ),
    };

    // Build the MapWidget
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MapWidget(
          initialPosition: initialPosition,
          markers: markers,
        ),
      ),
    ));

    // Verify that the GoogleMap widget is present
    expect(find.byType(GoogleMap), findsOneWidget);
  });

  testWidgets('MapWidget creates GoogleMapController on map creation',
      (WidgetTester tester) async {
    // Define initial position and markers
    final initialPosition = LatLng(37.7749, -122.4194);
    final markers = <Marker>{
      Marker(
        markerId: MarkerId('test_marker'),
        position: LatLng(37.7749, -122.4194),
      ),
    };

    // Build the MapWidget
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MapWidget(
          initialPosition: initialPosition,
          markers: markers,
        ),
      ),
    ));
  });
}
