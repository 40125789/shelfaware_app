import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelfaware_app/models/donation_request.dart';

void main() {
  group('DonationRequest', () {
    final donationRequest = DonationRequest(
      productName: 'Canned Beans',
      expiryDate: '2023-12-31',
      status: 'Pending',
      donorName: 'John Doe',
      donatorId: 'donator123',
      donationId: 'donation123',
      imageUrl: 'http://example.com/image.jpg',
      donorImageUrl: 'http://example.com/donor.jpg',
      pickupDateTime: DateTime(2023, 11, 1, 10, 0),
      message: 'Please pick up before expiry date.',
      requesterId: 'requester123',
      requestDate: Timestamp.now(),
      requesterProfileImageUrl: 'http://example.com/requester.jpg',
    );

    test('toMap returns correct map', () {
      final map = donationRequest.toMap();
      expect(map['productName'], 'Canned Beans');
      expect(map['expiryDate'], '2023-12-31');
      expect(map['status'], 'Pending');
      expect(map['donorName'], 'John Doe');
      expect(map['donatorId'], 'donator123');
      expect(map['donationId'], 'donation123');
      expect(map['imageUrl'], 'http://example.com/image.jpg');
      expect(map['donorImageUrl'], 'http://example.com/donor.jpg');
      expect(map['pickupDateTime'], donationRequest.pickupDateTime);
      expect(map['message'], 'Please pick up before expiry date.');
      expect(map['requesterId'], 'requester123');
      expect(map['requestDate'], donationRequest.requestDate);
      expect(
          map['requesterProfileImageUrl'], 'http://example.com/requester.jpg');
      expect(map['requestId'], null);
    });

    test('fromMap returns correct DonationRequest object', () {
      final map = {
        'productName': 'Canned Beans',
        'expiryDate': '2023-12-31',
        'status': 'Pending',
        'donorName': 'John Doe',
        'donatorId': 'donator123',
        'donationId': 'donation123',
        'imageUrl': 'http://example.com/image.jpg',
        'donorImageUrl': 'http://example.com/donor.jpg',
        'pickupDateTime': Timestamp.fromDate(DateTime(2023, 11, 1, 10, 0)),
        'message': 'Please pick up before expiry date.',
        'requesterId': 'requester123',
        'requestDate': Timestamp.now(),
        'requesterProfileImageUrl': 'http://example.com/requester.jpg',
        'requestId': null,
      };

      final donationRequestFromMap = DonationRequest.fromMap(map);

      expect(donationRequestFromMap.productName, 'Canned Beans');
      expect(donationRequestFromMap.expiryDate, '2023-12-31');
      expect(donationRequestFromMap.status, 'Pending');
      expect(donationRequestFromMap.donorName, 'John Doe');
      expect(donationRequestFromMap.donatorId, 'donator123');
      expect(donationRequestFromMap.donationId, 'donation123');
      expect(donationRequestFromMap.imageUrl, 'http://example.com/image.jpg');
      expect(
          donationRequestFromMap.donorImageUrl, 'http://example.com/donor.jpg');
      expect(
          donationRequestFromMap.pickupDateTime, DateTime(2023, 11, 1, 10, 0));
      expect(
          donationRequestFromMap.message, 'Please pick up before expiry date.');
      expect(donationRequestFromMap.requesterId, 'requester123');
      expect(donationRequestFromMap.requestDate, isA<Timestamp>());
      expect(donationRequestFromMap.requesterProfileImageUrl,
          'http://example.com/requester.jpg');
      expect(donationRequestFromMap.requestId, null);
    });
  });
}
