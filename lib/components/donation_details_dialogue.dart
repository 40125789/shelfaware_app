import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shelfaware_app/components/status_icon_widget.dart';
import 'package:shelfaware_app/pages/user_donation_map.dart';
import 'package:intl/intl.dart';
import 'package:shelfaware_app/repositories/user_repository.dart';
import 'package:shelfaware_app/services/user_service.dart';
class DonationDetailsDialog extends StatefulWidget {
  final double donationLatitude;
  final double donationLongitude;
  final double userLatitude;
  final double userLongitude;
  final String productName;
  final String expiryDate;
  final String status;
  final String donorName;
  final String chatId;
  final String donorEmail;
  final String donatorId;
  final String donationId;
  final String imageUrl;
  final String donorImageUrl;
  final DateTime donationTime;
  final String pickupTimes;
  final String pickupInstructions;

  DonationDetailsDialog({
    Key? key,
    required this.donationLatitude,
    required this.donationLongitude,
    required this.userLatitude,
    required this.userLongitude,
    required this.productName,
    required this.expiryDate,
    required this.status,
    required this.donorEmail,
    required this.donatorId,
    required this.chatId,
    required this.donorName,
    required this.donorImageUrl,
    required this.donationTime,
    required this.imageUrl,
    required this.donationId,
    required this.pickupTimes,
    required this.pickupInstructions, required String receiverEmail,
  }) : super(key: key);

  @override
  _DonationDetailsDialogState createState() => _DonationDetailsDialogState();
}

class _DonationDetailsDialogState extends State<DonationDetailsDialog> {
  double? donorRating;
  final UserService _userService = UserService(UserRepository(auth: FirebaseAuth.instance, firestore: FirebaseFirestore.instance));

  @override
  void initState() {
    super.initState();
    fetchDonorRating();
  }

  Future<void> fetchDonorRating() async {
    double? rating = await _userService.fetchDonorRating(widget.donatorId);
        donorRating = rating;
      
  }

  String formatDate(String date) {
    try {
      DateTime parsedDate = DateTime.parse(date);
      return DateFormat('dd/MM/yy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.imageUrl,
                      height: 120,
                      width: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.broken_image, size: 50, color: Colors.grey),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.productName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Text('Donor:', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(width: 5),
                          Text(widget.donorName, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                  
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Text('Expiry:', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(width: 5),
                          Text(
                            formatDate(widget.expiryDate),
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(width: 5),
                          StatusIconWidget(status: widget.status),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  backgroundColor: Colors.blue,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DonationMapScreen(
                        donationLatitude: widget.donationLatitude,
                        donationLongitude: widget.donationLongitude,
                        userLatitude: widget.userLatitude,
                        userLongitude: widget.userLongitude,
                        productName: widget.productName,
                        expiryDate: widget.expiryDate,
                        status: widget.status,
                        donorName: widget.donorName,
                        chatId: widget.chatId,
                        donorEmail: widget.donorEmail,
                        donatorId: widget.donatorId,
                        donationId: widget.donationId,
                        imageUrl: widget.imageUrl,
                        donorImageUrl: widget.donorImageUrl,
                        donationTime: widget.donationTime,
                        pickupTimes: widget.pickupTimes,
                        pickupInstructions: widget.pickupInstructions,
                        receiverEmail: '',
                        userId: '',
                        donorRating: donorRating ?? 0.0,
                      ),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info, color: Colors.white),
                    SizedBox(width: 5),
                    Text('View Details', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
