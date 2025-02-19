

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelfaware_app/pages/chat_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DonationRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onWithdraw;
  final VoidCallback onLeaveReview;
  final bool hasLeftReview;

  const DonationRequestCard({
    required this.request,
    required this.onWithdraw,
    required this.onLeaveReview,
    required this.hasLeftReview,
  });

  void _messageDonor(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('donations').doc(request['donationId']).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(child: Text('Donation not found')),
              );
            }

            final donationData = snapshot.data!.data() as Map<String, dynamic>;

            return ChatPage(
              donorName: donationData['donorName'] ?? 'Unknown',
              userId: donationData['userId'] ?? '',
              receiverEmail: donationData['donorEmail'] ?? '',
              receiverId: donationData['donorId'] ?? '',
              donationId: request['donationId'] ?? '',
              donationName: donationData['productName'] ?? 'Unnamed Item',
              chatId: '',
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productName = request['productName'] ?? 'Unnamed Product';
    final requestDate = request['requestDate']?.toDate();
    final status = request['status'] ?? 'Pending';
    final pickupDateTime = request['pickupDateTime']?.toDate();
    final donationPhotoUrl = request['imageUrl'] ?? '';

    final formattedRequestDate = requestDate != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(requestDate)
        : 'Unknown Date';
    final formattedPickupDate = pickupDateTime != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(pickupDateTime)
        : 'Unknown Pickup Date';

    IconData getStatusIcon(String status) {
      switch (status) {
        case 'Accepted':
          return FontAwesomeIcons.checkCircle;
        case 'Declined':
          return FontAwesomeIcons.timesCircle;
        case 'Picked Up':
          return FontAwesomeIcons.box;
        default:
          return FontAwesomeIcons.hourglassHalf;
      }
    }

    Color getStatusColor(String status) {
      switch (status) {
        case 'Accepted':
          return Colors.green;
        case 'Declined':
          return Colors.red;
        case 'Picked Up':
          return Colors.blue;
        default:
          return Colors.grey;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          backgroundImage: donationPhotoUrl.isNotEmpty
              ? NetworkImage(donationPhotoUrl)
              : null,
          child: donationPhotoUrl.isEmpty
              ? Icon(Icons.food_bank, color: Colors.white)
              : null,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              productName,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              decoration: BoxDecoration(
                color: getStatusColor(status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    getStatusIcon(status),
                    color: getStatusColor(status),
                    size: 16,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    status,
                    style: TextStyle(
                      color: getStatusColor(status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.send, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      "Request Sent: ",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    Text(
                      formattedRequestDate,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      "Pickup Date: ",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    Text(
                      formattedPickupDate,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'message') {
                          _messageDonor(context);
                        } else if (value == 'withdraw') {
                          onWithdraw();
                        } else if (value == 'review' && !hasLeftReview) {
                          onLeaveReview();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'message',
                          child: ListTile(
                            leading: const Icon(Icons.message, color: Colors.blue),
                            title: const Text('Message Donor'),
                          ),
                        ),
                        if (status != "Picked Up")
                          PopupMenuItem(
                            value: 'withdraw',
                            child: ListTile(
                              leading: const Icon(Icons.cancel, color: Colors.red),
                              title: const Text('Withdraw Request'),
                            ),
                          ),
                        if (status == "Picked Up" && !hasLeftReview)
                          PopupMenuItem(
                            value: 'review',
                            child: ListTile(
                              leading: const Icon(Icons.star_rate, color: Colors.green),
                              title: const Text('Leave a Review'),
                            ),
                          ),
                        if (hasLeftReview)
                          PopupMenuItem(
                            value: 'review',
                            enabled: false,
                            child: ListTile(
                              leading: const Icon(Icons.star_rate, color: Colors.grey),
                              title: const Text('Leave a Review (Already Done)', style: TextStyle(color: Colors.grey)),
                              subtitle: const Text("You've already left a review!", style: TextStyle(color: Colors.grey)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}