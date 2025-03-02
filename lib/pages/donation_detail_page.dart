import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shelfaware_app/components/status_icon_widget.dart';
import 'package:shelfaware_app/services/donation_service.dart';
import 'package:shelfaware_app/components/reserved_donation_dialog.dart';
import 'package:shelfaware_app/components/picked_up_donation_dialog.dart';
import 'package:shelfaware_app/components/accept_decline_request_dialog.dart';

class DonationDetailsPage extends StatelessWidget {
  final String donationId;
  final String assignedToName;

  final DonationService donationService = DonationService();

  DonationDetailsPage({required this.donationId, required this.assignedToName});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? ''; // Define the userId variable

    return Scaffold(
      appBar: AppBar(
        title: Text("Donation Details"),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: donationService.getDonationDetails(donationId),
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

          // Get the product name and image URL
          final productName =
              donation['productName'] ?? 'No product name available';
          final imageUrl = donation['imageUrl'] ?? '';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image and Product Name Section (Smaller Image on Left with Text on Right)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80, // Smaller image size
                      height: 80,
                      decoration: BoxDecoration(
                        image: imageUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover)
                            : null,
                        color: Colors.grey[300], // Fallback color if no image
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: imageUrl.isNotEmpty
                          ? null
                          : Center(
                              child: Icon(Icons.image,
                                  size: 30, color: Colors.white),
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
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                              "Added On: ${DateFormat('dd MMM yyyy').format(donation['donatedAt'].toDate())}"),
                          SizedBox(height: 8),
                         StatusIconWidget(status: donation['status']),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                SizedBox(height: 20),
                if (donation['status'] == 'Reserved')
                  ElevatedButton(
                    onPressed: () async {
                      // Fetch all requests related to the donation
                      List<Map<String, dynamic>> requests =
                          await donationService
                              .getDonationRequests(donationId)
                              .first;

                      // Find the request with status "Accepted"
                      var acceptedRequest = requests.firstWhere(
                        (request) => request['status'] == 'Accepted',
                        orElse: () =>
                            {}, // Provide a default empty object if no match is found
                      );

                      // Ensure there's an accepted request before proceeding
                      if (acceptedRequest.isNotEmpty) {
                        final String requestId = acceptedRequest['requestId'];

                        // Update both the donation and the accepted request status
                        await donationService.updateDonationStatus(
                            donationId, 'Picked Up');
                        await donationService.updateDonationRequestStatus(
                            donationId, requestId, 'Picked Up');

                        // Refresh the UI
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DonationDetailsPage(donationId: donationId, assignedToName: assignedToName),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'No accepted request found for this donation')),
                        );
                      }
                    },
                    child: Text("Mark as Picked Up"),
                  ),

                SizedBox(height: 20),

                // Donation Requests Section
                Text(
                  "Donation Requests for this item:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),

                // StreamBuilder to fetch and display the donation requests
                Expanded(
                  // Make donation requests scrollable
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: donationService.getDonationRequests(
                        donationId), // Replace 'additionalArgument' with the actual argument needed
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text("Error: ${snapshot.error}"));
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text("No requests found"));
                      }

                      final donationRequests = snapshot.data!;

                      return ListView.builder(
                        itemCount: donationRequests.length,
                        itemBuilder: (context, index) {
                          final request = donationRequests[index];
                          final requesterId = request['requesterId'] ?? '';
                          final pickupDateTime =
                              request['pickupDateTime']?.toDate();
                          final message = request['message'] ?? 'No message';
                          final status = request['status'] ?? 'Pending';
                          final requestId = request['requestId'] ?? '';

                          // Fetch requester's name asynchronously
                          return FutureBuilder<String>(
                            future:
                                donationService.getRequesterName(requesterId),
                            builder: (context, userSnapshot) {
                              if (userSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }

                              if (userSnapshot.hasError) {
                                return Center(
                                    child:
                                        Text("Error fetching requester name"));
                              }

                              final requesterName =
                                  userSnapshot.data ?? 'Unknown';

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 16),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: NetworkImage(
                                        request['requesterProfileImageUrl'] ??
                                            ''),
                                    backgroundColor: Colors.green,
                                    child:
                                        request['requesterProfileImageUrl'] ==
                                                null
                                            ? Icon(Icons.person,
                                                color: Colors.white)
                                            : null,
                                  ),
                                  title: Text("Requested by $requesterName"),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Pickup Date & Time: ${DateFormat('dd MMM yyyy, HH:mm').format(pickupDateTime ?? DateTime.now())}",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                      SizedBox(height: 5),
                                    ],
                                  ),
                                  trailing: Icon(Icons.arrow_forward_ios),
                                  onTap: () {
                                    if (donation['status'] == 'Reserved') {
                                      // Show alert for a reserved donation
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return ReservedDonationDialog(
                                            assignedToName: assignedToName,
                                            profileImageFuture: donationService.getAssigneeProfileImage(donationId),
                                          );
                                        },
                                      );
                                    } else if (donation['status'] ==
                                        'Picked Up') {
                                      // Show alert for a picked-up donation
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return PickedUpDonationDialog();
                                        },
                                      );
                                    } else {
                                      // Open the alert dialog to accept or decline the request
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AcceptDeclineRequestDialog(
                                            requesterName: requesterName,
                                            requesterProfileImageUrl: request['requesterProfileImageUrl'] ?? '',
                                            pickupDateTime: pickupDateTime ?? DateTime.now(),
                                            message: message,
                                            onAccept: () async {
                                              // Accept action
                                              await donationService.acceptDonationRequest(
                                                  donationId,
                                                  requestId,
                                                  requesterId);
                                              Navigator.pop(context); // Close the dialog
                                            },
                                            onDecline: () async {
                                              // Decline action
                                              await donationService.declineDonationRequest(requestId);
                                              Navigator.pop(context); // Close the dialog
                                            },
                                          );
                                        },
                                      );
                                    }
                                  },
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}