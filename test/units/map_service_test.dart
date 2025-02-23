import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shelfaware_app/models/donation.dart';
import 'package:shelfaware_app/services/map_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('MapService', () {
    final mapService = MapService();

    test('getMarkers returns markers excluding user donations', () async {
      final currentLocation = LatLng(51.5074, -0.1278); // Example location
      final userId = 'user123';
      final donationLocations = [
        DonationLocation(
          id: '1',
          status: 'active',
          donorName: 'Donor 1',
          donorEmail: 'donor1@example.com',
          donationId: 'donation1',
          addedOn: '2023-01-01',
          imageUrl: 'http://example.com/image1.jpg',
          pickupTimes: '9am-5pm',
          pickupInstructions: 'Leave at the door',
          donorId: 'user123',
          itemName: 'Item 1',
          location: LatLng(51.5075, -0.1279),
          expiryDate: '2023-12-31',
        ),
        DonationLocation(
          id: '2',
          status: 'active',
          donorName: 'Donor 2',
          donorEmail: 'donor2@example.com',
          donationId: 'donation2',
          addedOn: '2023-01-02',
          imageUrl: 'http://example.com/image2.jpg',
          pickupTimes: '10am-6pm',
          pickupInstructions: 'Ring the bell',
          donorId: 'user456',
          itemName: 'Item 2',
          location: LatLng(51.5076, -0.1280),
          expiryDate: '2023-12-31',
        ),
      ];
      final predefinedDonationPoints = [
        LatLng(51.5077, -0.1281),
      ];

      donationLocations.add(
        DonationLocation(
          id: '3',
          status: 'active',
          donorName: 'Donor 3',
          donorEmail: 'donor3@example.com',
          donationId: 'donation3',
          addedOn: '2023-01-03',
          imageUrl: 'http://example.com/image3.jpg',
          pickupTimes: '11am-7pm',
          pickupInstructions: 'Call on arrival',
          donorId: 'user123', // Change donorId to user123 to match userId
          itemName: 'Item 1',
          location: LatLng(51.5075, -0.1279),
          expiryDate: '2023-12-31',
        ),
      );

      final markers = await mapService.getMarkers(
        currentLocation,
        donationLocations,
        predefinedDonationPoints,
        userId,
        (donation) {},
      );

      expect(markers.length,
          3); // 1 current location + 1 other donation + 1 predefined point
      expect(
          markers.any((marker) => marker.markerId.value == 'currentLocation'),
          isTrue);
      expect(
          markers.any((marker) => marker.markerId.value == 'donation_Item 2_1'),
          isTrue);
      expect(
          markers.any((marker) => marker.markerId.value == 'donationPoint_0'),
          isTrue);
    });

    test('getMarkers formats expiry date correctly', () async {
      final currentLocation = LatLng(51.5074, -0.1278); // Example location
      final userId = 'user123';
      final donationLocations = [
        DonationLocation(
          id: '3',
          status: 'active',
          donorName: 'Donor 3',
          donorEmail: 'donor3@example.com',
          donationId: 'donation3',
          addedOn: '2023-01-03',
          imageUrl: 'http://example.com/image3.jpg',
          pickupTimes: '11am-7pm',
          pickupInstructions: 'Call on arrival',
          donorId: 'user456',
          itemName: 'Item 1',
          location: LatLng(51.5075, -0.1279),
          expiryDate: '2023-12-31',
        ),
      ];
      final List<LatLng> predefinedDonationPoints = [];

      final markers = await mapService.getMarkers(
        currentLocation,
        donationLocations,
        predefinedDonationPoints,
        userId,
        (donation) {},
      );

      final donationMarker = markers
          .firstWhere((marker) => marker.markerId.value == 'donation_Item 1_0');
      expect(donationMarker.infoWindow.snippet, 'Expires: 31/12/2023');
    });
  });
}
