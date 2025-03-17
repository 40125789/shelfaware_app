import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shelfaware_app/components/accept_decline_request_dialog.dart';
import 'package:shelfaware_app/components/picked_up_donation_dialog.dart';
import 'package:shelfaware_app/components/reserved_donation_dialog.dart';
import 'package:shelfaware_app/components/status_icon_widget.dart';
import 'package:shelfaware_app/services/donation_service.dart';


class DonationDetailsPage extends StatefulWidget {
  final String donationId;
  final String assignedToName;

  DonationDetailsPage({required this.donationId, required this.assignedToName});

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

  void _confirmDelete(BuildContext context, String donationId, String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Deletion"),
          content: Text("Are you sure you want to delete this donation?"),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: Text("Cancel")),
            TextButton(
              onPressed: () async {
                await donationService.removeDonation(context, donationId, userId);
                Navigator.pop(context);
                Navigator.pop(context); // Go back after deleting
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
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
          final productName =
              donation['productName'] ?? 'No product name available';
          final imageUrl = donation['imageUrl'] ?? '';
          final String donorId = donation['donorId'] ?? '';
          final String status = donation['status'] ?? 'Pending';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        image: imageUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover)
                            : null,
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: imageUrl.isNotEmpty
                          ? null
                          : Center(
                              child: Icon(Icons.image,
                                  size: 30, color: Colors.white)),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(productName,
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text(
                              "Added On: ${DateFormat('dd MMM yyyy').format(donation['donatedAt'].toDate())}"),
                          SizedBox(height: 8),
                          StatusIconWidget(status: status),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                if (status == 'Reserved')
ElevatedButton.icon(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blue, // Changed to blue
    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20), // Added more horizontal padding
    textStyle: TextStyle(fontSize: 14, color: Colors.white), // Changed font size and color to white
  ),
  icon: Icon(Icons.check_circle, color: Colors.white),
  onPressed: () async {
    List<Map<String, dynamic>> requests =
        await donationService.getDonationRequests(widget.donationId).first;

    var acceptedRequest = requests.firstWhere(
      (request) => request['status'] == 'Accepted',
      orElse: () => {},
    );

    if (acceptedRequest.isNotEmpty) {
      final String requestId = acceptedRequest['requestId'];

      await donationService.updateDonationStatus(widget.donationId, 'Picked Up');
      await donationService.updateDonationRequestStatus(widget.donationId, requestId, 'Picked Up');

      _refreshPage();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No accepted request found for this donation')),
      );
    }
  },
  label: Text("Mark as Picked Up", style: TextStyle(color: Colors.white)),
),

                SizedBox(height: 20),

                // Delete Button (Only for the donor and if not picked up)
                if (userId == donorId && status != 'Picked Up' && status != 'Reserved')
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () {
                      _confirmDelete(context, widget.donationId, userId);
                    },
                    child: Text("Delete Donation", style: TextStyle(color: Colors.white)),
                  ),

                SizedBox(height: 20),
                Text("Donation Requests for this item:",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),

                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: donationService.getDonationRequests(widget.donationId),
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
                          final requestId = request['requestId'] ?? '';
                          final message = request['message'] ?? '';
                          final status = request['status'] ?? 'Pending';

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
                                            assignedToName: widget.assignedToName,
                                            profileImageFuture: donationService.getAssigneeProfileImage(widget.donationId),
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
                                            widget.donationId,
                                            requestId,
                                            requesterId);
                                          Navigator.pop(context); // Close the dialog
                                          _refreshPage(); // Refresh the page
                                        },
                                        onDecline: () async {
                                          // Decline action
                                          await donationService.declineDonationRequest(requestId);
                                          Navigator.pop(context); // Close the dialog
                                          _refreshPage(); // Refresh the page
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
                                  
                                
                              
                            
                          
                        
                      
                  
                  
                
              
            
          
        
      
    

