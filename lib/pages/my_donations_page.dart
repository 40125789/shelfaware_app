import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shelfaware_app/pages/chat_page.dart';
import 'package:shelfaware_app/pages/star_review_page.dart';
import 'donation_detail_page.dart';
import 'package:intl/intl.dart';

class MyDonationsPage extends StatelessWidget {
  final String userId;

  MyDonationsPage({required this.userId});

  // Fetch donations where the donorId matches the logged-in user's ID
  Stream<List<Map<String, dynamic>>> getUserDonations(String userId) {
    return FirebaseFirestore.instance
        .collection('donations')
        .where('donorId', isEqualTo: userId) // Filter donations by donorId
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        return doc.exists ? Map<String, dynamic>.from(doc.data() as Map<String, dynamic>) : <String, dynamic>{};
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getSentDonationRequests(String userId) {
    return FirebaseFirestore.instance
        .collection('donationRequests')
        .where('requesterId', isEqualTo: userId)
        .snapshots()
        .map((querySnapshot) {
          return querySnapshot.docs.map((doc) {
            return doc.exists ? Map<String, dynamic>.from(doc.data() as Map<String, dynamic>) : <String, dynamic>{};
          }).toList();
        });
  }

@override
Widget build(BuildContext context) {
  return DefaultTabController(
    length: 2, // Number of tabs (Donations and Sent Requests)
    child: Scaffold(
      appBar: AppBar(
        title: const Text("Manage Donations"),
        bottom: const TabBar(
          tabs: [
            Tab(text: 'My Donations'),
            Tab(text: 'Sent Requests'),
          ],
          indicatorColor: Colors.white, // Active tab indicator color
          labelColor: Colors.white,    // Active tab text color
          unselectedLabelColor: Colors.white70, // Inactive tab text color
        ),
      ),
      body: TabBarView(
        children: [
          // Tab for Donations
          StreamBuilder<List<Map<String, dynamic>>>( 
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
                  final status = donation['status'] ?? 'Pending';
                  final imageUrl = donation['imageUrl'] ?? ''; // Fetch donation image URL
                  final assignedToName = donation['assignedToName'] ?? ''; // Fetch assigned recipient name

                  // Format date
                  final formattedDate = donatedAt != null
                      ? DateFormat('dd MMM yyyy, HH:mm').format(donatedAt)
                      : 'Unknown Date';

                  return FutureBuilder<int>(
                    // Fetch the count of requests for the current donation
                    future: FirebaseFirestore.instance
                        .collection('donationRequests')
                        .where('donationId', isEqualTo: donation['donationId'])
                        .get()
                        .then((querySnapshot) => querySnapshot.docs.length), // Count the number of documents
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        // Show a loading indicator while waiting for the data
                        return CircularProgressIndicator();
                      }
                      if (snapshot.hasError) {
                        // Handle any errors during the fetch
                        return Text('Error: ${snapshot.error}');
                      }

                      // Get the count of requests
                      int requestCount = snapshot.data ?? 0;

                      return GestureDetector(
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
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Donation Image (left side)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: imageUrl.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: imageUrl,
                                              width: 120,
                                              height: 120,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  const CircularProgressIndicator(),
                                              errorWidget: (context, url, error) =>
                                                  Image.asset(
                                                    'assets/placeholder.png',
                                                    width: 120,
                                                    height: 120,
                                                    fit: BoxFit.cover,
                                                  ),
                                            )
                                          : Image.asset(
                                              'assets/placeholder.png', // Placeholder image
                                              width: 120,
                                              height: 120,
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                    const SizedBox(width: 12), // Space between image and text

                                    // Text area (right side)
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Product Name (top of the text area)
                                          Text(
                                            productName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),

                                          // Status and Date
                                          Text(
                                            "Status: $status",
                                            style: const TextStyle(color: Colors.grey),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Date Added: $formattedDate",
                                            style: const TextStyle(color: Colors.black),
                                          ),
                                          const SizedBox(height: 4),
                                          // Conditionally show "Reserved for" unless status is "Picked Up"
                                          if (status != 'Picked Up' && assignedToName.isNotEmpty)
                                            Text(
                                              "Reserved for: $assignedToName",
                                              style: const TextStyle(color: Colors.green),
                                            ),
                                          const SizedBox(height: 8),

                                          // Display the request count
                                          Text(
                                            "$requestCount request${requestCount != 1 ? 's' : ''}",
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Overlay for "Complete" status
                              if (status == 'Picked Up')
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.lightGreen.withOpacity(0.5),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'Donated',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                     
                                    ),          
                                  ),  
                                ),
                              ),  
                            ],
                          ),
                        ),
                      );
    
  },
);
},
);
},
),
            

           // Tab for Sent Donation Requests
StreamBuilder<List<Map<String, dynamic>>>( 
  stream: getSentDonationRequests(userId), 
  builder: (context, snapshot) { 
    if (snapshot.connectionState == ConnectionState.waiting) { 
      return const Center(child: CircularProgressIndicator()); 
    }

    if (snapshot.hasError) { 
      return Center(child: Text("Error: ${snapshot.error}")); 
    }

    if (!snapshot.hasData || snapshot.data!.isEmpty) { 
      return const Center(child: Text("No sent donation requests")); 
    }

    final donationRequests = snapshot.data!;

    return ListView.builder(
      itemCount: donationRequests.length,
      itemBuilder: (context, index) {
        final request = donationRequests[index];
        final productName = request['productName'] ?? 'Unnamed Product';
        final requestDate = request['requestDate']?.toDate();
        final status = request['status'] ?? 'Pending';
        final pickupDateTime = request['pickupDateTime']?.toDate();
        final donationPhotoUrl = request['imageUrl'] ?? ''; // Image URL from Firebase
        final hasLeftReview = request['hasLeftReview'] ?? false; // Check if user has left a review

        // Format dates
        final formattedRequestDate = requestDate != null
            ? DateFormat('dd MMM yyyy, HH:mm').format(requestDate)
            : 'Unknown Date';
        final formattedPickupDate = pickupDateTime != null
            ? DateFormat('dd MMM yyyy, HH:mm').format(pickupDateTime)
            : 'Unknown Pickup Date';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green,
              backgroundImage: donationPhotoUrl.isNotEmpty
                  ? NetworkImage(donationPhotoUrl)
                  : null,
              child: donationPhotoUrl.isEmpty
                  ? Icon(Icons.food_bank, color: Colors.white)
                  : null,
            ),
            title: Text(
              productName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Request status: $status", style: const TextStyle(color: Colors.grey)),
                Text("Request Date: $formattedRequestDate", style: const TextStyle(color: Colors.grey)),
                Text("Pickup Date: $formattedPickupDate", style: const TextStyle(color: Colors.grey)),
              ],
            ),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.message, color: Colors.blue),
                        title: const Text('Message Donor'),
                        onTap: () {
                          Navigator.pop(context); // Close bottom sheet before navigation
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
                        },
                      ),
                      const Divider(),
                      if (status != "Picked Up") 
                        ListTile(
                          leading: const Icon(Icons.cancel, color: Colors.red),
                          title: const Text('Withdraw Request'),
                          onTap: () async {
                            Navigator.pop(context); // Close bottom sheet before action
                            await withdrawDonationRequest(context, request['requestId'], ['donationId']);
                          },
                        ),
                      if (status == "Picked Up") // Disable withdrawal option
                        ListTile(
                          leading: const Icon(Icons.block, color: Colors.grey),
                          title: const Text('Withdraw Request (Unavailable)'),
                          onTap: null, // No action
                        ),
                      if (status == "Picked Up" && !hasLeftReview) // Show "Leave a Review" only when request is marked as picked up and review is not left
                        ListTile(
                          leading: const Icon(Icons.star_rate, color: Colors.green),
                          title: const Text('Leave a Review'),
                          onTap: () async {
                            final hasReviewed = await hasUserAlreadyReviewed(request['donationId'], userId);

                            if (hasReviewed) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('You have already left a review for this donation.')),
                              );
                            } else {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReviewPage(
                                    donorId: request['donatorId'] ?? '',
                                    donationId: request['donationId'] ?? '',
                                    donationImage: request['imageUrl'] ?? '',
                                    donationName: request['productName'] ?? '',
                                    donorImageUrl: request['donorImageUrl'] ?? '',
                                    donorName: request['donorName'] ?? '', 
                                    isEditing: false, // Pass flag to indicate new review
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      if (hasLeftReview) // Grey out "Leave a Review" with a message if already reviewed
                        ListTile(
                          leading: const Icon(Icons.star_rate, color: Colors.grey),
                          title: const Text('Leave a Review (Already Done)', style: TextStyle(color: Colors.grey)),
                          subtitle: const Text("You've already left a review!", style: TextStyle(color: Colors.grey)),
                          onTap: null, // No action
            ),
        ],
      );
    },
  );
},

          ),
        );
      },
    );
  },
),
          ],
        ),
      ),
    );
  }
}

Future<void> withdrawDonationRequest(BuildContext context, String requestId, List<String> list) async {
  try {
    // Get the donationId from the donationRequest using the requestId
    var requestDoc = await FirebaseFirestore.instance
        .collection('donationRequests')
        .doc(requestId)
        .get();

    if (!requestDoc.exists) {
      throw Exception('Donation request not found');
    }

    // Extract the donationId from the request document
    String donationId = requestDoc['donationId'];
    
    if (donationId.isEmpty) {
      throw Exception('Donation ID is missing from request document');
    }

    // Delete the request from the 'donationRequests' collection
    await requestDoc.reference.delete();

    // Debugging: Check if the donationId is valid
    print('DonationId: $donationId');

    // Update the associated donation in the 'donations' collection
    await FirebaseFirestore.instance.collection('donations').doc(donationId).update({
      'status': 'available', // Set status to 'available'
      'assignedTo': FieldValue.delete(), // Remove assignedTo field
      'assignedToName': FieldValue.delete(), // Remove assignedToName field
    }).then((_) {
      // If the update is successful, show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Donation request withdrawn and donation status updated to available')),
      );
    }).catchError((e) {
      // Handle any errors that occur during the donation update
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating donation: $e')),
      );
    });
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error withdrawing request: $e')),
    );
  }
}




Future<bool> hasUserAlreadyReviewed(String donationId, String userId) async {
  final querySnapshot = await FirebaseFirestore.instance
      .collection('reviews')
      .where('donationId', isEqualTo: donationId)
      .where('reviewerId', isEqualTo: userId)
      .get();

  return querySnapshot.docs.isNotEmpty; // If there's any document, the user has reviewed
}


    