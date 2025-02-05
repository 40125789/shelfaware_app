
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shelfaware_app/components/donation_request_card.dart';
import 'package:shelfaware_app/components/my_donation_card.dart';
import 'package:shelfaware_app/pages/star_review_page.dart';
import 'package:shelfaware_app/services/donation_service.dart';
import 'package:shelfaware_app/services/donation_firebase_service.dart'; 
import 'package:shelfaware_app/pages/donation_detail_page.dart';


class MyDonationsPage extends StatelessWidget {
  final String userId;
  final DonationService donationService = DonationService();

  MyDonationsPage({required this.userId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Manage Donations"),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My Donations'),
              Tab(text: 'Sent Requests'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: TabBarView(
          children: [
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: DonationFireBaseService().getUserDonations(userId),
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

                    return FutureBuilder<int>(
                      future: FirebaseFirestore.instance
                          .collection('donationRequests')
                          .where('donationId', isEqualTo: donation['donationId'])
                          .get()
                          .then((querySnapshot) => querySnapshot.docs.length),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }

                        int requestCount = snapshot.data ?? 0;

                        return MyDonationCard(
                          donation: donation,
                          requestCount: requestCount,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DonationDetailsPage(
                                  donationId: donation['donationId'] ?? '', donation: {},
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: DonationFireBaseService().getSentDonationRequests(userId),
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
                    final hasLeftReview = request['hasLeftReview'] ?? false;

                    return DonationRequestCard(
                      request: request,
                      onWithdraw: () async {
                        await DonationFireBaseService().withdrawDonationRequest(context, request['requestId']);
                      },
                      onLeaveReview: () async {
                        final hasReviewed = await DonationFireBaseService().hasUserAlreadyReviewed(request['donationId'], userId);

                        if (hasReviewed) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('You have already left a review for this donation.')),
                          );
                        } else {
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
                                isEditing: false,
                              ),
                            ),
                          );
                        }
                      },
                      hasLeftReview: hasLeftReview,
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
