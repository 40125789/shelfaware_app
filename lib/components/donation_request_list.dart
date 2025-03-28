import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shelfaware_app/components/accept_decline_request_dialog.dart';
import 'package:shelfaware_app/components/picked_up_donation_dialog.dart';
import 'package:shelfaware_app/components/reserved_donation_dialog.dart';
import 'package:shelfaware_app/services/donation_service.dart';


class DonationRequestList extends StatelessWidget {
  final String donationId;
  final String assignedToName;
  final DonationService donationService;
  final Map<String, dynamic> donation;
  final VoidCallback refreshPage;

  const DonationRequestList({
    Key? key,
    required this.donationId,
    required this.assignedToName,
    required this.donationService,
    required this.donation,
    required this.refreshPage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Donation Requests for this item:",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Expanded(
          child: _buildRequestList(context),
        ),
      ],
    );
  }

  Widget _buildRequestList(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: donationService.getDonationRequests(donationId),
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
            return _buildRequestItem(context, donationRequests[index]);
          },
        );
      },
    );
  }

  Widget _buildRequestItem(BuildContext context, Map<String, dynamic> request) {
    final requesterId = request['requesterId'] ?? '';
    final pickupDateTime = request['pickupDateTime']?.toDate();
    final requestId = request['requestId'] ?? '';
    final message = request['message'] ?? '';
    final status = request['status'] ?? 'Pending';

    return FutureBuilder<String>(
      future: donationService.getRequesterName(requesterId),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (userSnapshot.hasError) {
          return Center(child: Text("Error fetching requester name"));
        }

        final requesterName = userSnapshot.data ?? 'Unknown';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(request['requesterProfileImageUrl'] ?? ''),
              backgroundColor: Colors.green,
              child: request['requesterProfileImageUrl'] == null
                  ? Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            title: Text("Requested by $requesterName"),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Pickup Date & Time: ${DateFormat('dd MMM yyyy, HH:mm').format(pickupDateTime ?? DateTime.now())}",
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 5),
              ],
            ),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () => _handleRequestTap(
              context, 
              donation, 
              requestId, 
              requesterId,
              requesterName,
              pickupDateTime ?? DateTime.now(),
              message,
              request['requesterProfileImageUrl'] ?? '',
            ),
          ),
        );
      },
    );
  }

  void _handleRequestTap(
    BuildContext context,
    Map<String, dynamic> donation,
    String requestId,
    String requesterId,
    String requesterName,
    DateTime pickupDateTime,
    String message,
    String requesterProfileImageUrl,
  ) {
    if (donation['status'] == 'Reserved') {
      _showReservedDialog(context);
    } else if (donation['status'] == 'Picked Up') {
      _showPickedUpDialog(context);
    } else {
      _showAcceptDeclineDialog(
        context,
        requestId,
        requesterId,
        requesterName,
        pickupDateTime,
        message,
        requesterProfileImageUrl,
      );
    }
  }

  void _showReservedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ReservedDonationDialog(
          assignedToName: assignedToName,
          profileImageFuture: donationService.getAssigneeProfileImage(donationId),
        );
      },
    );
  }

  void _showPickedUpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PickedUpDonationDialog();
      },
    );
  }

  void _showAcceptDeclineDialog(
    BuildContext context,
    String requestId,
    String requesterId,
    String requesterName,
    DateTime pickupDateTime,
    String message,
    String requesterProfileImageUrl,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AcceptDeclineRequestDialog(
          requesterName: requesterName,
          requesterProfileImageUrl: requesterProfileImageUrl,
          pickupDateTime: pickupDateTime,
          message: message,
          onAccept: () async {
            await donationService.acceptDonationRequest(
              donationId,
              requestId,
              requesterId,
            );
            Navigator.pop(context);
            refreshPage();
          },
          onDecline: () async {
            await donationService.declineDonationRequest(requestId);
            Navigator.pop(context);
            refreshPage();
          },
        );
      },
    );
  }
}