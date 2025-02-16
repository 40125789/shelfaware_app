import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelfaware_app/repositories/watched_donations_repository.dart';

class WatchedDonationsService {
  final WatchedDonationsRepository _watchedDonationsRepository;

  WatchedDonationsService(this._watchedDonationsRepository);

  Stream<QuerySnapshot> getWatchedDonations(String userId) {
    return _watchedDonationsRepository.getWatchedDonations(userId);
  }

  Future<DocumentSnapshot> getDonorData(String donorId) {
    return _watchedDonationsRepository.getDonorData(donorId);
  }

  Future<void> toggleWatchlist(String userId, String donationId, Map<String, dynamic> donation) {
    return _watchedDonationsRepository.toggleWatchlist(userId, donationId, donation);
  }

  Future<bool> isDonationInWatchlist(String userId, String donationId) {
    return _watchedDonationsRepository.isDonationInWatchlist(userId, donationId);
  }

  Future<void> addToWatchlist(String userId, String donationId, Map<String, dynamic> donationData) {
    return _watchedDonationsRepository.addToWatchlist(userId, donationId, donationData);
  }

  Future<void> removeFromWatchlist(String userId, String donationId) {
    return _watchedDonationsRepository.removeFromWatchlist(userId, donationId);
  }
}