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
    required this.donorName, required bool isEditing,
  });

  @override
  _ReviewPageState createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  double communicationRating = 0;
  double foodItemRating = 0;
  double donationProcessRating = 0;

  // Function to submit or update the review to Firestore
  Future<void> submitReview({
    required String donorId,
    required String donationId,
    required String userId,
    required double communicationRating,
    required double foodItemRating,
    required double donationProcessRating,
    String? reviewId, // For update case
  }) async {
    try {
      Timestamp timestamp = Timestamp.now();

      // If reviewId is null, it's a new review, otherwise, it's an update
      if (reviewId == null) {
        // Add new review
        await FirebaseFirestore.instance.collection('reviews').add({
          'donorId': donorId,
          'donationId': donationId,
          'reviewerId': userId, // Current logged-in user's ID
          'communicationRating': communicationRating,
          'foodItemRating': foodItemRating,
          'donationProcessRating': donationProcessRating,
          'timestamp': timestamp,
        });
      } else {
        // Update existing review
        await FirebaseFirestore.instance.collection('reviews').doc(reviewId).update({
          'communicationRating': communicationRating,
          'foodItemRating': foodItemRating,
          'donationProcessRating': donationProcessRating,
          'timestamp': timestamp,
        });
      }

      print('Review submitted/updated successfully!');
    } catch (e) {
      print('Error submitting/updating review: $e');
    }
  }

  // Function to get the current logged-in user's ID
  Future<String?> getCurrentUserId() async {
    User? user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  // Function to check if a review already exists for the current user
  Future<Map<String, dynamic>?> getExistingReview(String donationId, String donorId, String userId) async {
    try {
      // Query Firestore for the review
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('donationId', isEqualTo: donationId)
          .where('donorId', isEqualTo: donorId)
          .where('reviewerId', isEqualTo: userId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Return the first review found (there should only be one)
        return querySnapshot.docs.first.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error fetching existing review: $e');
    }
    return null;
  }

  void _submitFeedback() async {
    if (communicationRating > 0 && foodItemRating > 0 && donationProcessRating > 0) {
      String? userId = await getCurrentUserId();

      if (userId != null) {
        // Check if a review already exists for this user
        var existingReview = await getExistingReview(widget.donationId, widget.donorId, userId);

        if (existingReview != null) {
          // Update the review
          String reviewId = existingReview['id'];  // Assuming 'id' is the document ID
          await submitReview(
            donorId: widget.donorId,
            donationId: widget.donationId,
            userId: userId,
            communicationRating: communicationRating,
            foodItemRating: foodItemRating,
            donationProcessRating: donationProcessRating,
            reviewId: reviewId, // Pass the review ID to update the existing review
          );
        } else {
          // Submit new review
          await submitReview(
            donorId: widget.donorId,
            donationId: widget.donationId,
            userId: userId,
            communicationRating: communicationRating,
            foodItemRating: foodItemRating,
            donationProcessRating: donationProcessRating,
          );
        }

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
                  Text('Your feedback has been submitted/updated successfully!')
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

  @override
  void initState() {
    super.initState();
    _prefillReview();
  }

  // Prefill the review form if a review already exists
  Future<void> _prefillReview() async {
    String? userId = await getCurrentUserId();

    if (userId != null) {
      var existingReview = await getExistingReview(widget.donationId, widget.donorId, userId);

      if (existingReview != null) {
        setState(() {
          communicationRating = existingReview['communicationRating'] ?? 0;
          foodItemRating = existingReview['foodItemRating'] ?? 0;
          donationProcessRating = existingReview['donationProcessRating'] ?? 0;
        });
      }
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
