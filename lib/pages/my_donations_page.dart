import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'donation_detail_page.dart';

import 'package:intl/intl.dart';

class MyDonationsPage extends StatelessWidget {
  final String userId;

  MyDonationsPage({required this.userId});

  Stream<List<Map<String, dynamic>>> getUserDonations(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .asyncMap((userDoc) async {
          if (!userDoc.exists) {
            return [];
          }

          List<String> donationIds = List<String>.from(userDoc['myDonations'] ?? []);
          if (donationIds.isEmpty) {
            return [];
          }

          final donations = await Future.wait(donationIds.map((donationId) {
            return FirebaseFirestore.instance
                .collection('donations')
                .doc(donationId)
                .get();
          }));

          return donations.map((doc) {
            return doc.exists ? Map<String, dynamic>.from(doc.data() as Map<String, dynamic>) : <String, dynamic>{};
          }).toList();
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Donations"),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getUserDonations(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No donations found"));
          }

          final donations = snapshot.data!;

          return ListView.builder(
            itemCount: donations.length,
            itemBuilder: (context, index) {
              final donation = donations[index];
              final productName = donation['productName'] ?? 'Unnamed Product';
              final donatedAt = donation['donatedAt']?.toDate();
              final recipientName = donation['recipientName'] ?? 'Unknown Recipient';
              final status = donation['status'] ?? 'Pending';

              // Format date
              final formattedDate = donatedAt != null
                  ? DateFormat('dd MMM yyyy, HH:mm').format(donatedAt)
                  : 'Unknown Date';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: const Icon(Icons.food_bank, color: Colors.white),
                  ),
                  title: Text(
                    productName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Donated to: $recipientName"),
                      Text("Status: $status", style: const TextStyle(color: Colors.grey)),
                      Text("Date: $formattedDate", style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DonationDetailsPage(
                          donation: donation,
                          donationId: donation['donationId'] ?? '',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
