import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelfaware_app/models/donation.dart';

void main() {
  group('DonationLocation', () {
    test('fromFirestore creates a valid DonationLocation object', () {
      final geoPoint = GeoPoint(37.7749, -122.4194);
      final timestamp = Timestamp.now();
      final doc = {
        'id': '123',
        'location': geoPoint,
        'productName': 'Canned Food',
        'expiryDate': timestamp,
        'status': 'available',
        'donorId': 'donor123',
        'donorName': 'John Doe',
        'donorEmail': 'john.doe@example.com',
        'donationId': 'donation123',
        'addedOn': timestamp,
        'imageUrl': 'http://example.com/image.jpg',
        'pickupTimes': '9 AM - 5 PM',
        'pickupInstructions': 'Leave at the front door'
      };

      final donationLocation = DonationLocation.fromFirestore(doc);

      expect(donationLocation.id, '123');
      expect(donationLocation.location, LatLng(37.7749, -122.4194));
      expect(donationLocation.itemName, 'Canned Food');
      expect(
          donationLocation.expiryDate, timestamp.toDate().toLocal().toString());
      expect(donationLocation.status, 'available');
      expect(donationLocation.donorId, 'donor123');
      expect(donationLocation.donorName, 'John Doe');
      expect(donationLocation.donorEmail, 'john.doe@example.com');
      expect(donationLocation.donationId, 'donation123');
      expect(donationLocation.addedOn, timestamp.toDate().toLocal().toString());
      expect(donationLocation.imageUrl, 'http://example.com/image.jpg');
      expect(donationLocation.pickupTimes, '9 AM - 5 PM');
      expect(donationLocation.pickupInstructions, 'Leave at the front door');
    });

    test('filterDistance calculates correct distance between two points', () {
      final donationLocation = DonationLocation(
        id: '123',
        location: LatLng(0, 0),
        itemName: 'Canned Food',
        expiryDate: '2023-12-31',
        status: 'available',
        donorId: 'donor123',
        donorName: 'John Doe',
        donorEmail: 'john.doe@example.com',
        donationId: 'donation123',
        addedOn: '2023-01-01',
        imageUrl: 'http://example.com/image.jpg',
        pickupTimes: '9 AM - 5 PM',
        pickupInstructions: 'Leave at the front door',
      );

      final distance = donationLocation.filterDistance(
          37.7749, -122.4194, 34.0522, -118.2437);
      expect(distance,
          closeTo(559, 1)); // Distance between San Francisco and Los Angeles
    });
  });
}
