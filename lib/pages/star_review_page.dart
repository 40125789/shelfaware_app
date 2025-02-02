import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ReviewPage extends StatefulWidget {
  final String donorId;
  final String donationId;
  final String donationImage;
  final String donationName;
  final String donorImageUrl;
  final String donorName;

  ReviewPage({
    required this.donorId,
    required this.donationId,
    required this.donationImage,
    required this.donationName,
    required this.donorImageUrl,
    required this.donorName,
    required bool isEditing,
  });

  @override
  _ReviewPageState createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  double communicationRating = 0;
  double foodItemRating = 0;
  double donationProcessRating = 0;
  TextEditingController commentController = TextEditingController();

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
        await FirebaseFirestore.instance.collection('reviews').add({
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
        await FirebaseFirestore.instance.collection('reviews').doc(reviewId).update({
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
    }
  }

  Widget buildRatingSection(String label, double rating, Function(double) onRatingChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        RatingBar.builder(
          initialRating: rating,
          minRating: 1,
          itemSize: 30,
          direction: Axis.horizontal,
          allowHalfRating: true,
          itemBuilder: (context, _) => Icon(
            Icons.star,
            color: Colors.amber,
          ),
          onRatingUpdate: onRatingChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leave a Review'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  widget.donationImage,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.image_not_supported, size: 100, color: Colors.grey);
                  },
                ),
              ),
            ),
            SizedBox(height: 10),
            Text('Review for:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(widget.donorImageUrl),
                  radius: 30,
                ),
                SizedBox(width: 10),
                Text(
                  widget.donorName,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 20),
            buildRatingSection('Communication & Friendliness', communicationRating, (rating) {
              setState(() {
                communicationRating = rating;
              });
            }),
            SizedBox(height: 20),
            buildRatingSection('Food Quality & Freshness', foodItemRating, (rating) {
              setState(() {
                foodItemRating = rating;
              });
            }),
            SizedBox(height: 20),
            buildRatingSection('Pickup Experience', donationProcessRating, (rating) {
              setState(() {
                donationProcessRating = rating;
              });
            }),
            SizedBox(height: 20),
            TextField(
              controller: commentController,
              decoration: InputDecoration(
                labelText: 'Leave a comment',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: communicationRating > 0 && foodItemRating > 0 && donationProcessRating > 0
                    ? () {
                        submitReview(
                          donorId: widget.donorId,
                          donationId: widget.donationId,
                          userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                          communicationRating: communicationRating,
                          foodItemRating: foodItemRating,
                          donationProcessRating: donationProcessRating,
                          comment: commentController.text,
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  textStyle: TextStyle(fontSize: 18),
                  foregroundColor: Colors.white,
                ),
                child: Text('Submit Feedback'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

