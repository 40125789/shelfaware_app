import 'package:flutter/material.dart';
import 'package:shelfaware_app/components/donation_request_card.dart';
import 'package:shelfaware_app/components/my_donation_card.dart';
import 'package:shelfaware_app/pages/star_review_page.dart';
import 'package:shelfaware_app/providers/auth_provider.dart';
import 'package:shelfaware_app/providers/donation_provider.dart';
import 'package:shelfaware_app/pages/donation_detail_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class MyDonationsPage extends ConsumerWidget {
  const MyDonationsPage({Key? key, required String userId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState is AsyncError || !authState.isAuthenticated || authState.user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login'); // Use pushReplacementNamed to avoid stack issues
      });
      return Scaffold(
        appBar: AppBar(
          title: const Text("Manage Donations"),
        ),
        body: const Center(
          child: Text("You need to be logged in to view this page."),
        ),
      );
    }

    final myDonationsAsync = ref.watch(userDonationsProvider);
    final sentRequestsAsync = ref.watch(sentRequestsProvider);
    final returnRequestCountAsync = ref.watch(donationRequestCountProvider(''));

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
            // My Donations Tab
            myDonationsAsync.when(
              data: (donations) => donations.isEmpty
                  ? const Center(child: Text("No donations found"))
                  : ListView.builder(
                      itemCount: donations.length,
                      itemBuilder: (context, index) {
                        final donation = donations[index];

                        final requestCountAsync = ref.watch(
                            donationRequestCountProvider(
                                donation['donationId'] ?? ''));

                        return requestCountAsync.when(
                          data: (requestCount) => MyDonationCard(
                            donation: donation,
                            requestCount: requestCount,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DonationDetailsPage(
                                      donationId: donation['donationId'] ?? ''),
                                ),
                              );
                            }, userId: '',
                          ),
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, _) {
                            print("Error fetching request count: $error");
                            return Center(child: Text("Error: $error"));
                          },
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) {
                print("Error fetching donations: $error");
                return Center(child: Text("Error: $error"));
              },
            ),
            // Sent Requests Tab
            sentRequestsAsync.when(
              data: (requests) => requests.isEmpty
                  ? const Center(child: Text("No sent donation requests"))
                  : ListView.builder(
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final request = requests[index];
                        final hasLeftReview = request['hasLeftReview'] ?? false;

                        return DonationRequestCard(
                          request: request,
                          onWithdraw: () async {
                            try {
                              await ref
                                  .read(donationServiceProvider)
                                  .withdrawDonationRequest(
                                      context, request['requestId']);
                            } catch (e) {
                              print("Error withdrawing request: $e");
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error: $e")),
                              );
                            }
                          },
                          onLeaveReview: () async {
                            try {
                              final hasReviewed = await ref
                                  .read(donationServiceProvider)
                                  .hasUserAlreadyReviewed(
                                      request['donationId'], authState.user!.uid);

                              if (hasReviewed) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'You have already left a review for this donation.')),
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
                                      donorImageUrl:
                                          request['donorImageUrl'] ?? '',
                                      donorName: request['donorName'] ?? '',
                                      isEditing: false,
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              print("Error checking review status: $e");
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error: $e")),
                              );
                            }
                          },
                          hasLeftReview: hasLeftReview,
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) {
                print("Error fetching sent requests: $error");
                return Center(child: Text("Error: $error"));
              },
            ),
          ],
        ),
      ),
    );
  }
}