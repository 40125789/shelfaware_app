import 'package:flutter/material.dart';
import 'package:shelfaware_app/components/donation_request_card.dart';
import 'package:shelfaware_app/components/my_donation_card.dart';
import 'package:shelfaware_app/components/my_donation_status_filter.dart';
import 'package:shelfaware_app/components/withdraw_request_dialog.dart';
import 'package:shelfaware_app/screens/star_review_page.dart';
import 'package:shelfaware_app/providers/auth_provider.dart';
import 'package:shelfaware_app/providers/donation_provider.dart';
import 'package:shelfaware_app/screens/donation_detail_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/components/request_status_filter.dart';

class MyDonationsPage extends ConsumerStatefulWidget {
  const MyDonationsPage({Key? key, required String userId}) : super(key: key);

  @override
  _MyDonationsPageState createState() => _MyDonationsPageState();
}

class _MyDonationsPageState extends ConsumerState<MyDonationsPage> {
  String selectedStatus = 'All';

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (authState is AsyncError ||
        !authState.isAuthenticated ||
        authState.user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
            appBar: AppBar(
            title: Text(
              "Manage Donations",
              style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Theme.of(context).appBarTheme.titleTextStyle?.color ?? Colors.white,
              ),
            ),
            ),
          body: Column(children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TabBar(
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(
                    width: 3.0,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Theme.of(context).primaryColor,
                  ),
                  insets: const EdgeInsets.symmetric(horizontal: 16.0),
                ),
                labelColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Theme.of(context).primaryColor,
                unselectedLabelColor:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey[700],
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'My Donations'),
                  Tab(text: 'Sent Requests'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // My Donations Tab
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: StatusFilterWidget(
                          selectedStatus: selectedStatus,
                          onStatusChanged: (String newStatus) {
                            setState(() {
                              selectedStatus = newStatus;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: myDonationsAsync.when(
                          data: (donations) {
                            final filteredDonations =
                                donations.where((donation) {
                              if (selectedStatus == 'All') return true;
                              return donation['status'] == selectedStatus;
                            }).toList();

                            return filteredDonations.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.inbox_rounded,
                                            size: 64, color: Colors.grey),
                                        SizedBox(height: 16),
                                        Text(
                                          "No donations found",
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          "Start sharing by adding your first donation",
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: filteredDonations.length,
                                    itemBuilder: (context, index) {
                                      final donation = filteredDonations[index];

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
                                                builder: (context) =>
                                                    DonationDetailsPage(
                                                        donationId: donation[
                                                                'donationId'] ??
                                                            '',
                                                        assignedToName: donation[
                                                                'assignedToName'] ??
                                                            ''),
                                              ),
                                            );
                                          },
                                          userId: '',
                                          assignedToName:
                                              donation['assignedToName'] ?? '',
                                        ),
                                        loading: () => const Center(
                                            child: CircularProgressIndicator()),
                                        error: (error, _) {
                                          print(
                                              "Error fetching request count: $error");
                                          return Center(
                                              child: Text("Error: $error"));
                                        },
                                      );
                                    },
                                  );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, _) {
                            print("Error fetching donations: $error");
                            return Center(child: Text("Error: $error"));
                          },
                        ),
                      ),
                    ],
                  ),
                  // Sent Requests Tab
                  sentRequestsAsync.when(
                    data: (requests) => requests.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.send_outlined,
                                    size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  "No requests sent yet",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Browse available donations and send your first request",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              const RequestStatusFilter(),
                              if (requests
                                  .where((request) =>
                                      ref.watch(requestStatusFilterProvider) ==
                                          'All' ||
                                      ref.watch(requestStatusFilterProvider) ==
                                          request['status'])
                                  .isEmpty)
                                Expanded(
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.filter_list,
                                            size: 64, color: Colors.grey),
                                        SizedBox(height: 16),
                                        Text(
                                          "No requests match the filter",
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          "Try adjusting your filter settings",
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: requests.length,
                                    itemBuilder: (context, index) {
                                      final request = requests[index];
                                      final hasLeftReview =
                                          request['hasLeftReview'] ?? false;
                                      final status =
                                          request['status'] ?? 'Pending';

                                      if (ref.watch(
                                                  requestStatusFilterProvider) !=
                                              'All' &&
                                          ref.watch(
                                                  requestStatusFilterProvider) !=
                                              status) {
                                        return Container();
                                      }

                                      return DonationRequestCard(
                                        request: request,
                                        onWithdraw: () async {
                                          if (request['status'] != 'Declined') {
                                            bool? shouldWithdraw =
                                                await showWithdrawDialog(
                                                    context);
                                            if (shouldWithdraw == true) {
                                              try {
                                                await ref
                                                    .read(
                                                        donationServiceProvider)
                                                    .withdrawDonationRequest(
                                                        context,
                                                        request['requestId']);
                                              } catch (e) {
                                                print(
                                                    "Error withdrawing request: $e");
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                      content:
                                                          Text("Error: $e")),
                                                );
                                              }
                                            }
                                          }
                                        },
                                        onLeaveReview: () async {
                                          try {
                                            final hasReviewed = await ref
                                                .read(donationServiceProvider)
                                                .hasUserAlreadyReviewed(
                                                    request['donationId'],
                                                    authState.user!.uid);

                                            if (hasReviewed) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        'You have already left a review for this donation.')),
                                              );
                                            } else {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ReviewPage(
                                                    donorId:
                                                        request['donatorId'] ??
                                                            '',
                                                    donationId:
                                                        request['donationId'] ??
                                                            '',
                                                    donationImage:
                                                        request['imageUrl'] ??
                                                            '',
                                                    donationName: request[
                                                            'productName'] ??
                                                        '',
                                                    donorImageUrl: request[
                                                            'donorImageUrl'] ??
                                                        '',
                                                    donorName:
                                                        request['donorName'] ??
                                                            '',
                                                    isEditing: false,
                                                  ),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            print(
                                                "Error checking review status: $e");
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text("Error: $e")),
                                            );
                                          }
                                        },
                                        hasLeftReview: hasLeftReview,
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) {
                      print("Error fetching sent requests: $error");
                      return Center(child: Text("Error: $error"));
                    },
                  ),
                ],
              ),
            ),
          ])),
    );
  }
}
