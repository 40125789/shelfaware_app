import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shelfaware_app/components/review_rating_row.dart';

class ReviewCard extends StatelessWidget {
  final Map<String, dynamic> reviewData;

  ReviewCard({required this.reviewData});

  @override
  Widget build(BuildContext context) {
    String reviewerId = reviewData['reviewerId'];
    String comment = reviewData['comment'];
    double communicationRating = reviewData['communicationRating'];
    double foodItemRating = reviewData['foodItemRating'];
    double donationProcessRating = reviewData['donationProcessRating'];
    Timestamp reviewTimestamp = reviewData['timestamp'];

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(reviewerId).get(),
      builder: (context, reviewerSnapshot) {
        if (reviewerSnapshot.connectionState == ConnectionState.waiting) {
          return SizedBox.shrink();
        }

        var reviewerData = reviewerSnapshot.data?.data() as Map<String, dynamic>;
        String reviewerName = '${reviewerData?['firstName']}';
        String reviewerProfileImage = reviewerData?['profileImageUrl'] ?? '';
        DateTime reviewDate = reviewTimestamp.toDate();
   
   
   
   return Card(
          margin: EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: reviewerProfileImage.isNotEmpty
                  ? NetworkImage(reviewerProfileImage)
                  : AssetImage('assets/default_avatar.png') as ImageProvider,
            ),
            title: Text(
              '$reviewerName on ${DateFormat('dd MMM yyyy').format(reviewDate)}',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RatingRow(label: 'Communication', rating: communicationRating),
                SizedBox(height: 5),
                RatingRow(label: 'Food Quality', rating: foodItemRating),
                SizedBox(height: 5),
                RatingRow(label: 'Pickup Process', rating: donationProcessRating),
                SizedBox(height: 5),
                Text('"$comment"', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
              ],
            ),
          ),
        );
      },
    );
  }
}