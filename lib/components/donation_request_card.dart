import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelfaware_app/pages/chat_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shelfaware_app/repositories/donation_request_repository.dart';

class DonationRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onWithdraw;
  final VoidCallback onLeaveReview;
  final bool hasLeftReview;
  final DonationRequestRepository _repository = DonationRequestRepository(
    firebaseFirestore: FirebaseFirestore.instance,
    firebaseAuth: FirebaseAuth.instance,
  );

  DonationRequestCard({
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
          future: _repository.getDonationById(request['donationId']),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError ||
                !snapshot.hasData ||
                !snapshot.data!.exists) {
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
    final donorName = request['donorName'] ?? '';
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
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                  const TextSpan(
                    text: ' from ',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                  TextSpan(
                    text: donorName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
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
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.grey),
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
                    const Icon(Icons.calendar_today,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      "Pickup Date: ",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    Text(
                      formattedPickupDate,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _messageDonor(context),
                      icon: const Icon(Icons.message, color: Colors.white),
                      label: const Text('Message Donor'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        textStyle: const TextStyle(fontSize: 12),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    if (status != "Picked Up")
                      ElevatedButton.icon(
                        onPressed: onWithdraw,
                        icon: const Icon(Icons.cancel, color: Colors.white),
                        label: const Text('Withdraw Request'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          textStyle: const TextStyle(fontSize: 12),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    if (status == "Picked Up" && !hasLeftReview)
                      ElevatedButton.icon(
                        onPressed: onLeaveReview,
                        icon: const Icon(Icons.star_rate, color: Colors.white),
                        label: const Text('Leave a Review'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          textStyle: const TextStyle(fontSize: 12),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    if (hasLeftReview)
                      ElevatedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.star_rate, color: Colors.white),
                        label: const Text('Review Left'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          textStyle: const TextStyle(fontSize: 12),
                          foregroundColor: Colors.white,
                        ),
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
