import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  });

  @override
  _ReviewPageState createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  double communicationRating = 0;
  double foodItemRating = 0;
  double donationProcessRating = 0;

  // Function to submit the review to Firestore
  Future<void> submitReview({
    required String donorId,
    required String donationId,
    required String userId,
    required double communicationRating,
    required double foodItemRating,
    required double donationProcessRating,
  }) async {
    try {
      // Get the current timestamp
      Timestamp timestamp = Timestamp.now();

      // Add the review to the 'reviews' collection
      await FirebaseFirestore.instance.collection('reviews').add({
        'donorId': donorId,
        'donationId': donationId,
        'reviewerId': userId, // Current logged-in user's ID
        'communicationRating': communicationRating,
        'foodItemRating': foodItemRating,
        'donationProcessRating': donationProcessRating,
        'timestamp': timestamp,
      });

      // Optionally, you can call the Cloud Function to update the donor's rating
      // The function will handle the average calculation in Firebase Cloud Functions
      print('Review submitted successfully!');
    } catch (e) {
      print('Error submitting review: $e');
    }
  }

  // Function to get the current logged-in user's ID
  Future<String?> getCurrentUserId() async {
    User? user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  void _submitFeedback() async {
    if (communicationRating > 0 && foodItemRating > 0 && donationProcessRating > 0) {
      String? userId = await getCurrentUserId();

      if (userId != null) {
        await submitReview(
          donorId: widget.donorId,
          donationId: widget.donationId,
          userId: userId,
          communicationRating: communicationRating,
          foodItemRating: foodItemRating,
          donationProcessRating: donationProcessRating,
        );

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Thanks!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.network(
                    'https://lottie.host/79cbd2da-0505-4e98-a171-c385cacdb7d2/muG5mShz7u.json',
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                    repeat: false,
                  ),
                  SizedBox(height: 10),
                  Text('Your feedback has been submitted successfully!')
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the pop-up
                  },
                  child: Text('Close'),
                ),
              ],
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not logged in. Please sign in to submit feedback.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please provide ratings for all categories.')),
      );
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
        backgroundColor: Colors.green,
      ),
      body: Padding(
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

            Text(
              'Review for:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
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

            buildRatingSection('How would you rate the communication?', communicationRating, (rating) {
              setState(() {
                communicationRating = rating;
              });
            }),
            SizedBox(height: 20),

            buildRatingSection('How would you rate the food items?', foodItemRating, (rating) {
              setState(() {
                foodItemRating = rating;
              });
            }),
            SizedBox(height: 20),

            buildRatingSection('How easy was the donation process?', donationProcessRating, (rating) {
              setState(() {
                donationProcessRating = rating;
              });
            }),
            SizedBox(height: 40),

            Center(
              child: ElevatedButton(
                onPressed: communicationRating > 0 && foodItemRating > 0 && donationProcessRating > 0
                    ? _submitFeedback
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
