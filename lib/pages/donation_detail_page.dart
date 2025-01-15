import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DonationDetailsPage extends StatelessWidget {
  final String donationId;

  DonationDetailsPage({required this.donationId, required Map<String, dynamic> donation});

  // Fetch donation details based on the donationId
  Future<Map<String, dynamic>> getDonationDetails() async {
    DocumentSnapshot donationDoc = await FirebaseFirestore.instance
        .collection('donations')
        .doc(donationId)
        .get();
    return donationDoc.exists ? donationDoc.data() as Map<String, dynamic> : {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Donation Details"),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: getDonationDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("Donation not found"));
          }

          final donation = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Product Name: ${donation['productName'] ?? 'N/A'}", style: TextStyle(fontSize: 18)),
                SizedBox(height: 10),
                Text("Donated by: ${donation['donorName'] ?? 'N/A'}", style: TextStyle(fontSize: 16)),
                SizedBox(height: 10),
                Text("Donation Date: ${donation['donatedAt'].toDate()}"),
                SizedBox(height: 10),
                Text("Status: ${donation['status']}"),
                SizedBox(height: 20),
                if (donation['status'] == 'available')
                  ElevatedButton(
                    onPressed: () {
                      // Allow the user to change the donation status or take action.
                      // For example, you can provide a button to mark it as "Taken" or "Pending."
                      // You can also allow them to update the donation info.
                    },
                    child: Text("Update Status or Manage Donation"),
                  ),
                SizedBox(height: 20),
                Text(
                  "If you wish to interact with other users regarding this donation, check the chat page.",
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
