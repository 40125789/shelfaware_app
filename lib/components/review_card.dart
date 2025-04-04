import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shelfaware_app/components/review_rating_row.dart';

class ReviewCard extends StatelessWidget {
  final Map<String, dynamic> reviewData;

  const ReviewCard({Key? key, required this.reviewData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String reviewerId = reviewData['reviewerId'];
    final String comment = reviewData['comment'];
    final double communicationRating = reviewData['communicationRating'];
    final double foodItemRating = reviewData['foodItemRating'];
    final double donationProcessRating = reviewData['donationProcessRating'];
    final Timestamp reviewTimestamp = reviewData['timestamp'];
    final DateTime reviewDate = reviewTimestamp.toDate();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(reviewerId).get(),
      builder: (context, reviewerSnapshot) {
        if (reviewerSnapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final reviewerData = reviewerSnapshot.data?.data() as Map<String, dynamic>?;
        final String reviewerName = reviewerData?['firstName'] ?? 'Anonymous';
        final String reviewerProfileImage = reviewerData?['profileImageUrl'] ?? '';
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                      backgroundImage: reviewerProfileImage.isNotEmpty
                          ? NetworkImage(reviewerProfileImage)
                          : const AssetImage('assets/default_avatar.png') as ImageProvider,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reviewerName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            DateFormat('MMMM d, yyyy').format(reviewDate),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      RatingRow(label: 'Communication', rating: communicationRating),
                      Divider(height: 16, color: Theme.of(context).dividerColor),
                      RatingRow(label: 'Food Quality', rating: foodItemRating),
                      Divider(height: 16, color: Theme.of(context).dividerColor),
                      RatingRow(label: 'Pickup Process', rating: donationProcessRating),
                    ],
                  ),
                ),
                if (comment.isNotEmpty) 
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      '"$comment"',
                      style: TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}