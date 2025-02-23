import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shelfaware_app/components/user_donation_map_widget.dart';

void main() {
  testWidgets('UserDonationMap displays correctly',
      (WidgetTester tester) async {
    final LatLng testLocation = LatLng(37.7749, -122.4194);
    final Set<Marker> testMarkers = {
      Marker(
        markerId: MarkerId('testMarker'),
        position: testLocation,
      ),
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UserDonationMap(
            currentLocation: testLocation,
            markers: testMarkers,
            onTap: (context, donation) {},
          ),
        ),
      ),
    );

    expect(find.byType(GoogleMap), findsOneWidget);
  });
}
