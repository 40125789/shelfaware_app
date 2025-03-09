import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/components/review_card.dart';
import 'package:shelfaware_app/providers/review_provider.dart';

class ReviewSection extends ConsumerWidget {
  final String loggedInUserId;

  ReviewSection({required this.loggedInUserId});

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
            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                var reviewData = reviews[index];
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
