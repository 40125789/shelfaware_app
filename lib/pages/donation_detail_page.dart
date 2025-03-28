import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shelfaware_app/components/accept_decline_request_dialog.dart';
import 'package:shelfaware_app/components/picked_up_donation_dialog.dart';
import 'package:shelfaware_app/components/reserved_donation_dialog.dart';
import 'package:shelfaware_app/components/status_icon_widget.dart';
import 'package:shelfaware_app/services/donation_service.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shelfaware_app/components/donation_action_buttons.dart';
import 'package:shelfaware_app/components/donation_product_details.dart';
import 'package:shelfaware_app/components/donation_request_list.dart';
import 'package:shelfaware_app/services/donation_service.dart';

class DonationDetailsPage extends StatefulWidget {
  final String donationId;
  final String assignedToName;

  DonationDetailsPage({
    required this.donationId, 
    required this.assignedToName
  });

  @override
  _DonationDetailsPageState createState() => _DonationDetailsPageState();
}

class _DonationDetailsPageState extends State<DonationDetailsPage> {
  final DonationService donationService = DonationService();
  late Future<Map<String, dynamic>> donationDetails;

  @override
  void initState() {
    super.initState();
    donationDetails = donationService.getDonationDetails(widget.donationId);
  }

  void _refreshPage() {
    setState(() {
      donationDetails = donationService.getDonationDetails(widget.donationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text("Donation Details"),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: donationDetails,
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
          return _buildContent(context, donation, userId);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, 
    Map<String, dynamic> donation, 
    String userId
  ) {
    final productName = donation['productName'] ?? 'No product name available';
    final imageUrl = donation['imageUrl'] ?? '';
    final String donorId = donation['donorId'] ?? '';
    final String status = donation['status'] ?? 'Pending';
    final String pickupDateTime = donation['pickupTimes'] ?? '';
    final String pickupInstructions = donation['pickupInstructions'] ?? '';
    final donatedAt = donation['donatedAt'].toDate();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product details
          DonationProductDetails(
            productName: productName,
            imageUrl: imageUrl,
            donatedAt: donatedAt,
            status: status,
            pickupDateTime: pickupDateTime,
            pickupInstructions: pickupInstructions,
          ),
          
          SizedBox(height: 15),
          
          // Action buttons
          DonationActionButtons(
            donationId: widget.donationId,
            userId: userId,
            donorId: donorId,
            status: status,
            donation: donation,
            donationService: donationService,
            refreshPage: _refreshPage,
          ),
          
          SizedBox(height: 20),
          
          // Donation requests
          Expanded(
            child: DonationRequestList(
              donationId: widget.donationId,
              assignedToName: widget.assignedToName,
              donationService: donationService,
              donation: donation,
              refreshPage: _refreshPage,
            ),
          ),
        ],
      ),
    );
  }
}
