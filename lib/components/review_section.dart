import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/components/review_card.dart';
import 'package:shelfaware_app/providers/review_provider.dart';

class ReviewSection extends ConsumerWidget {
  final String loggedInUserId;

  const ReviewSection({required this.loggedInUserId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewState = ref.watch(reviewProvider(loggedInUserId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reviews left by others',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700]),
        ),
        SizedBox(height: 10),
        reviewState.when(
          data: (reviews) {
            if (reviews.isEmpty) {
              return Center(child: Text('No reviews yet.'));
            }
            
            // Sort reviews by timestamp in descending order (newest first)
            final sortedReviews = List.from(reviews)
              ..sort((a, b) => (b['timestamp'] ?? DateTime(1970)).compareTo(a['timestamp'] ?? DateTime(1970)));
            
            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: sortedReviews.length,
              itemBuilder: (context, index) {
                var reviewData = sortedReviews[index];
                return ReviewCard(reviewData: reviewData);
              },
            );
          },
          loading: () => Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text('Error loading reviews')),
        ),
      ],
    );
  }
}
