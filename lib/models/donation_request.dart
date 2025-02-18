import 'package:cloud_firestore/cloud_firestore.dart';

class DonationRequest {
  final String productName;
  final String expiryDate;
  final String status;
  final String donorName;
  final String donatorId;
  final String donationId;
  final String imageUrl;
  final String donorImageUrl;
  final DateTime pickupDateTime;
  final String message;
  final String requesterId;
  final Timestamp requestDate;
  final String requesterProfileImageUrl;
  String? requestId;

  DonationRequest({
    required this.productName,
    required this.expiryDate,
    required this.status,
    required this.donorName,
    required this.donatorId,
    required this.donationId,
    required this.imageUrl,
    required this.donorImageUrl,
    required this.pickupDateTime,
    required this.message,
    required this.requesterId,
    required this.requestDate,
    required this.requesterProfileImageUrl,
    this.requestId,
  });

  Map<String, dynamic> toMap() {
    return {
      'productName': productName,
      'expiryDate': expiryDate,
      'status': status,
      'donorName': donorName,
      'donatorId': donatorId,
      'donationId': donationId,
      'imageUrl': imageUrl,
      'donorImageUrl': donorImageUrl,
      'pickupDateTime': pickupDateTime,
      'message': message,
      'requesterId': requesterId,
      'requestDate': requestDate,
      'requesterProfileImageUrl': requesterProfileImageUrl,
      'requestId': requestId,
    };
  }

  factory DonationRequest.fromMap(Map<String, dynamic> map) {
    return DonationRequest(
      productName: map['productName'],
      expiryDate: map['expiryDate'],
      status: map['status'],
      donorName: map['donorName'],
      donatorId: map['donatorId'],
      donationId: map['donationId'],
      imageUrl: map['imageUrl'],
      donorImageUrl: map['donorImageUrl'],
      pickupDateTime: (map['pickupDateTime'] as Timestamp).toDate(),
      message: map['message'],
      requesterId: map['requesterId'],
      requestDate: map['requestDate'],
      requesterProfileImageUrl: map['requesterProfileImageUrl'],
      requestId: map['requestId'],
    );
  }
}