import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shelfaware_app/pages/user_donation_map.dart';
import 'package:intl/intl.dart';

class DonationDetailsDialog extends StatelessWidget {
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
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

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
    required receiverEmail,
    required this.pickupTimes,
    required this.pickupInstructions,
  }) : super(key: key);

  String formatDate(String date) {
    try {
      DateTime parsedDate = DateTime.parse(date);
      return DateFormat('dd/MM/yy').format(parsedDate);
    } catch (e) {
      return date; // Fallback if parsing fails
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
                if (imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      height: 120,
                      width: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.grey,
                      ),
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
                        productName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.person, color: Colors.green),
                          SizedBox(width: 10),
                          Text('Donor:', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(width: 5),
                          Flexible(child: Text(donorName, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.date_range, color: Colors.blue),
                          SizedBox(width: 10),
                          Text('Expiry:', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              formatDate(expiryDate),
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.orange),
                          SizedBox(width: 10),
                          Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(width: 5),
                          Flexible(child: Text(status, overflow: TextOverflow.ellipsis)),
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
                    borderRadius: BorderRadius.circular(30), // Rounded button
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  backgroundColor: Colors.blue, // Adjust color if needed
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DonationMapScreen(
                        donationLatitude: donationLatitude,
                        donationLongitude: donationLongitude,
                        userLatitude: userLatitude,
                        userLongitude: userLongitude,
                        productName: productName,
                        expiryDate: expiryDate,
                        status: status,
                        donorName: donorName,
                        chatId: chatId,
                        donorEmail: donorEmail,
                        donatorId: donatorId,
                        donationId: donationId,
                        imageUrl: imageUrl,
                        donorImageUrl: donorImageUrl,
                        donationTime: donationTime,
                        pickupTimes: pickupTimes,
                        pickupInstructions: pickupInstructions,
                        receiverEmail: '',
                        userId: '',
                      ),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  Icon(Icons.info, size: 18, color: Colors.white),
                  SizedBox(width: 5),
                  Text(
                    'View Details',
                    style: TextStyle(color: Colors.white),
                  ),
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
