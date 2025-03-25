import 'package:latlong2/latlong.dart' as latlong2;
import 'package:shelfaware_app/services/donation_filter_logic.dart';
import 'package:test/test.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart'
    as google_maps;
import 'package:shelfaware_app/models/donation.dart'; // Import the correct DonationLocation class

void main() {
  group('filterDonations', () {
    final google_maps.LatLng referenceLocation =
        google_maps.LatLng(52.5200, 13.4050); // Example reference point

    test('filters donations expiring soon', () {
      final donations = [
        DonationLocation(
          id: '1',
          expiryDate: DateTime.now()
              .add(Duration(days: 2))
              .toIso8601String(), // Expiring soon
          addedOn: DateTime.now().toIso8601String(),
          location: google_maps.LatLng(52.5200, 13.4050),
          itemName: '',
          status: '',
          donorId: '',
          donorName: '',
          donorEmail: '',
          donationId: '',
          imageUrl: '',
          pickupTimes: '',
          pickupInstructions: '',
        ),
        DonationLocation(
          id: '2',
          expiryDate: DateTime.now()
              .add(Duration(days: 5))
              .toIso8601String(), // Not expiring soon
          addedOn: DateTime.now().toIso8601String(),
          location: google_maps.LatLng(53.5200, 13.4050),
          itemName: '',
          status: '',
          donorId: '',
          donorName: '',
          donorEmail: '',
          donationId: '',
          imageUrl: '',
          pickupTimes: '',
          pickupInstructions: '',
        ),
      ];

      final filtered = filterDonations(
        donations,
        true, // Filter expiring soon
        false, // Ignore newly added filter
        100.0, // Ignore distance filter
        latlong2.LatLng(
            referenceLocation.latitude, referenceLocation.longitude),
      );

      // Expect only donations that are expiring soon
      expect(filtered.length, 1);
      expect(filtered[0].id, '1');
    });

    test('filters donations added recently', () {
      final donations = [
        DonationLocation(
          id: '1',
          expiryDate: DateTime.now().add(Duration(days: 2)).toIso8601String(),
          addedOn: DateTime.now()
              .subtract(Duration(hours: 1))
              .toIso8601String(), // Added recently
          location: google_maps.LatLng(52.5200, 13.4050),
          itemName: '',
          status: '',
          donorId: '',
          donorName: '',
          donorEmail: '',
          donationId: '',
          imageUrl: '',
          pickupTimes: '',
          pickupInstructions: '',
        ),
        DonationLocation(
          id: '2',
          expiryDate: DateTime.now().add(Duration(days: 2)).toIso8601String(),
          addedOn: DateTime.now()
              .subtract(Duration(hours: 25))
              .toIso8601String(), // Not added recently
          location: google_maps.LatLng(52.5200, 13.4050),
          itemName: '',
          status: '',
          donorId: '',
          donorName: '',
          donorEmail: '',
          donationId: '',
          imageUrl: '',
          pickupTimes: '',
          pickupInstructions: '',
        ),
      ];

      final filtered = filterDonations(
        donations,
        false, // Ignore expiring soon filter
        true, // Filter newly added
        100.0, // Ignore distance filter
        latlong2.LatLng(
            referenceLocation.latitude, referenceLocation.longitude),
      );

      // Expect only donations that were added recently
      expect(filtered.length, 1);
      expect(filtered[0].id, '1');
    });

    test('filters donations within the specified distance', () {
      final donations = [
        DonationLocation(
          id: '1',
          expiryDate: DateTime.now().add(Duration(days: 2)).toIso8601String(),
          addedOn: DateTime.now().toIso8601String(),
          location: google_maps.LatLng(52.5200, 13.4050),
          itemName: '',
          status: '',
          donorId: '',
          donorName: '',
          donorEmail: '',
          donationId: '',
          imageUrl: '',
          pickupTimes: '',
          pickupInstructions: '', // Same location
        ),
        DonationLocation(
          id: '2',
          expiryDate: DateTime.now().add(Duration(days: 2)).toIso8601String(),
          addedOn: DateTime.now().toIso8601String(),
          location: google_maps.LatLng(53.5200, 13.4050),
          itemName: '',
          status: '',
          donorId: '',
          donorName: '',
          donorEmail: '',
          donationId: '',
          imageUrl: '',
          pickupTimes: '',
          pickupInstructions: '', // Different location
        ),
      ];

      final filtered = filterDonations(
        donations,
        false, // Ignore expiring soon filter
        false, // Ignore newly added filter
        50.0, // Set a distance filter
        latlong2.LatLng(
            referenceLocation.latitude, referenceLocation.longitude),
      );

      // Expect only the donation within the specified distance
      expect(filtered.length, 1);
      expect(filtered[0].id, '1');
    });

    test('filters donations with all filters applied', () {
      final donations = [
        DonationLocation(
          id: '1',
          expiryDate: DateTime.now()
              .add(Duration(days: 2))
              .toIso8601String(), // Expiring soon
          addedOn: DateTime.now()
              .subtract(Duration(hours: 1))
              .toIso8601String(), // Added recently
          location: google_maps.LatLng(52.5200, 13.4050),
          itemName: '',
          status: '',
          donorId: '',
          donorName: '',
          donorEmail: '',
          donationId: '',
          imageUrl: '',
          pickupTimes: '',
          pickupInstructions: '', // Same location
        ),
        DonationLocation(
          id: '2',
          expiryDate: DateTime.now()
              .add(Duration(days: 5))
              .toIso8601String(), // Not expiring soon
          addedOn: DateTime.now()
              .subtract(Duration(hours: 25))
              .toIso8601String(), // Not added recently
          location: google_maps.LatLng(53.5200, 13.4050),
          itemName: '',
          status: '',
          donorId: '',
          donorName: '',
          donorEmail: '',
          donationId: '',
          imageUrl: '',
          pickupTimes: '',
          pickupInstructions: '', // Different location
        ),
      ];

      final filtered = filterDonations(
        donations,
        true, // Filter expiring soon
        true, // Filter newly added
        50.0, // Set a distance filter
        latlong2.LatLng(
            referenceLocation.latitude, referenceLocation.longitude),
      );

      // Expect only the donation that meets all criteria
      expect(filtered.length, 1);
      expect(filtered[0].id, '1');
    });

    test('returns empty list when no donations match filters', () {
      final donations = [
        DonationLocation(
          id: '1',
          expiryDate: DateTime.now()
              .add(Duration(days: 5))
              .toIso8601String(), // Not expiring soon
          addedOn: DateTime.now()
              .subtract(Duration(hours: 25))
              .toIso8601String(), // Not added recently
          location: google_maps.LatLng(53.5200, 13.4050),
          itemName: '',
          status: '',
          donorId: '',
          donorName: '',
          donorEmail: '',
          donationId: '',
          imageUrl: '',
          pickupTimes: '',
          pickupInstructions: '', // Different location
        ),
      ];

      final filtered = filterDonations(
        donations,
        true, // Filter expiring soon
        true, // Filter newly added
        50.0, // Set a distance filter
        latlong2.LatLng(
            referenceLocation.latitude, referenceLocation.longitude),
      );

      // Expect an empty list since no donation matches the filters
      expect(filtered.length, 0);
    });
  });
}
