import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DonationDetailsHeader extends StatelessWidget {
  final String donationName;


  final String donationId;

  DonationDetailsHeader({
    required this.donationName,
    required this.donationId,
  
  });

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth _auth = FirebaseAuth.instance;

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
          const SizedBox(height: 4),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
