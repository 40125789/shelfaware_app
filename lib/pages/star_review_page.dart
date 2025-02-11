import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shelfaware_app/services/review_service.dart';

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
  final ReviewService _reviewService = ReviewService();

  Future<void> submitReview() async {
    try {
      await _reviewService.submitReview(
        donorId: widget.donorId,
        donationId: widget.donationId,
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        communicationRating: communicationRating,
        foodItemRating: foodItemRating,
        donationProcessRating: donationProcessRating,
        comment: commentController.text,
      );
      showSuccessDialog(); // Show success dialog after submitting the review
    } catch (e) {
      print('Error submitting/updating review: $e');
    }
  }

  void showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/animations/success_tick.json',
                width: 150,
                height: 150,
                repeat: false,
              ),
              SizedBox(height: 20),
              Text(
                'Thanks for your review!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(); // Navigate back to the previous page
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
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
                    ? submitReview
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