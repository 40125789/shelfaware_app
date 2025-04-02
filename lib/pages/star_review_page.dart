import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shelfaware_app/services/review_service.dart';

class ReviewPage extends StatefulWidget {
  final String donorId, donationId, donationImage, donationName, donorImageUrl, donorName;
  final bool isEditing;

  ReviewPage({
    required this.donorId,
    required this.donationId,
    required this.donationImage,
    required this.donationName,
    required this.donorImageUrl,
    required this.donorName,
    required this.isEditing,
  });

  @override
  _ReviewPageState createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  double communicationRating = 0, foodItemRating = 0, donationProcessRating = 0;
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
      showSuccessDialog();
    } catch (e) {
      print('Error submitting/updating review: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit review. Please try again.')),
      );
    }
  }

  void showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset('assets/animations/success_tick.json', width: 100, height: 100, repeat: false),
            SizedBox(height: 10),
            Text('Thanks for your review!', 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), 
                textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget buildRatingSection(String label, double rating, Function(double) onRatingChanged) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: Offset(0, 1)
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          Align(
            alignment: Alignment.centerLeft,
            child: RatingBar.builder(
              initialRating: rating,
              minRating: 1,
              itemSize: 30,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemBuilder: (context, _) => Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: onRatingChanged,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Leave a Review'), elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.donationImage,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 80,
                              width: 80,
                              color: Theme.of(context).disabledColor.withOpacity(0.1),
                              child: Icon(Icons.image_not_supported, size: 30, color: Theme.of(context).disabledColor),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Reviewing ${widget.donationName}',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: NetworkImage(widget.donorImageUrl),
                                    radius: 12,
                                    backgroundColor: Theme.of(context).disabledColor.withOpacity(0.1),
                                  ),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Donated by:', style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
                                        Text(widget.donorName, 
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text('Rate your experience:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                buildRatingSection('Communication & Friendliness', communicationRating, 
                  (rating) => setState(() => communicationRating = rating)),
                buildRatingSection('Food Quality & Freshness', foodItemRating, 
                  (rating) => setState(() => foodItemRating = rating)),
                buildRatingSection('Pickup Experience', donationProcessRating, 
                  (rating) => setState(() => donationProcessRating = rating)),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).shadowColor.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 2,
                        offset: Offset(0, 1)
                      )
                    ],
                  ),
                  child: TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      labelText: 'Leave a comment! (optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: EdgeInsets.all(12),
                    ),
                    maxLines: 3,
                  ),
                ),
                SizedBox(height: 20),
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: ElevatedButton(
                      onPressed: communicationRating > 0 && foodItemRating > 0 && donationProcessRating > 0
                          ? submitReview : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 35, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Submit Review', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      resizeToAvoidBottomInset: true,
    );
  }
}
