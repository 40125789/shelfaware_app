import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DonationDetailsHeader extends StatelessWidget {
  final String donationName;
  final String receiverEmail;
  final String donationId;
  final String currentStatus;
  final Function(String) onUpdateStatus;

  DonationDetailsHeader({
    required this.donationName,
    required this.receiverEmail,
    required this.donationId,
    required this.currentStatus,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final bool isReceiver = _auth.currentUser!.uid == receiverEmail;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Donation Details",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Product Name: $donationName",
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            "Donor Email: $receiverEmail",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          if (isReceiver) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  "Update Status: ",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: currentStatus,
                  onChanged: (String? newStatus) {
                    if (newStatus != null) {
                      onUpdateStatus(newStatus);
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: 'Available',
                      child: Text('Available'),
                    ),
                    DropdownMenuItem(
                      value: 'Reserved',
                      child: Text('Claimed'),
                    ),
                    DropdownMenuItem(
                      value: 'Picked Up',
                      child: Text('Completed'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}