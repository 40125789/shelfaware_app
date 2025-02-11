import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> submitReview({
    required String donorId,
    required String donationId,
    required String userId,
    required double communicationRating,
    required double foodItemRating,
    required double donationProcessRating,
    String? reviewId,
    String? comment,
  }) async {
    try {
      Timestamp timestamp = Timestamp.now();
      if (reviewId == null) {
        await _firestore.collection('reviews').add({
          'donorId': donorId,
          'donationId': donationId,
          'reviewerId': userId,
          'communicationRating': communicationRating,
          'foodItemRating': foodItemRating,
          'donationProcessRating': donationProcessRating,
          'comment': comment,
          'timestamp': timestamp,
        });
      } else {
        await _firestore.collection('reviews').doc(reviewId).update({
          'communicationRating': communicationRating,
          'foodItemRating': foodItemRating,
          'donationProcessRating': donationProcessRating,
          'comment': comment,
          'timestamp': timestamp,
        });
      }
      print('Review submitted/updated successfully!');
    } catch (e) {
      print('Error submitting/updating review: $e');
      throw e;
    }
  }
}