import 'package:firebase_auth/firebase_auth.dart';
import 'package:shelfaware_app/models/donation_request.dart';
import 'package:shelfaware_app/repositories/donation_request_repository.dart';


class DonationRequestService {
  final DonationRequestRepository _repository;

  DonationRequestService(this._repository);

  Future<void> sendRequest(DonationRequest request) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('You need to be logged in to make a request');
    }

 
    String requesterId = user.uid;

    // Check if the user has already requested this donation
    bool alreadyRequested = await _repository.checkIfAlreadyRequested(request.donationId, requesterId);
    if (alreadyRequested) {
      throw Exception('You have already requested this donation.');
    }



    String? profileImageUrl = await _repository.getUserProfileImageUrl(requesterId);

    DonationRequest updatedRequest = DonationRequest(
      productName: request.productName,
      expiryDate: request.expiryDate,
      status: request.status,
      donorName: request.donorName,
      donatorId: request.donatorId,
      donationId: request.donationId,
      imageUrl: request.imageUrl,
      donorImageUrl: request.donorImageUrl,
      pickupDateTime: request.pickupDateTime,
      message: request.message,
      requesterId: requesterId,
      requestDate: request.requestDate,
      requesterProfileImageUrl: profileImageUrl ?? '',
    );

    await _repository.addDonationRequest(updatedRequest);
  }
}
