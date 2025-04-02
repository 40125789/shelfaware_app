import 'package:flutter/material.dart';
import 'package:shelfaware_app/services/donation_service.dart';
import 'package:shelfaware_app/components/edit_pickup_details_dialog.dart';
import 'package:shelfaware_app/utils/donation_details_util.dart';

class DonationActionButtons extends StatelessWidget {
  final String donationId;
  final String userId;
  final String donorId;
  final String status;
  final Map<String, dynamic> donation;
  final DonationService donationService;
  final VoidCallback refreshPage;

  const DonationActionButtons({
    Key? key,
    required this.donationId,
    required this.userId,
    required this.donorId,
    required this.status,
    required this.donation,
    required this.donationService,
    required this.refreshPage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (userId != donorId || status == 'Picked Up') {
      return SizedBox.shrink();
    }

    // Available status shows edit button and delete button in a row
    if (status == 'Available') {
      return Row(
        children: [
          // Edit pickup details button
          Expanded(
            child: _buildEditButton(context),
          ),
          SizedBox(width: 10),
          // Delete button
          Expanded(
            child: _buildDeleteButton(context),
          ),
        ],
      );
    }
    // Reserved status shows mark as picked up button
    else if (status == 'Reserved') {
      return Row(
        children: [
          SizedBox(width: 10),
          // Mark as picked up button
          Expanded(
            child: _buildPickedUpButton(context),
          ),
        ],
      );
    }

    return SizedBox.shrink();
  }

  Widget _buildEditButton(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      label: Text("Edit Pickup Details", style: TextStyle(color: Colors.white)),
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return EditPickupDetailsDialog(
              donationId: donationId,
              initialPickupTimes: donation['pickupTimes'] ?? '',
              initialPickupInstructions: donation['pickupInstructions'] ?? '',
              donationService: donationService,
              refreshPage: refreshPage,
            );
          },
        );
      },
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      label: Text("Delete Donation", style: TextStyle(color: Colors.white)),
      onPressed: () async {
        bool? confirm = await DonationUtils.showConfirmDialog(
          context: context,
          title: "Confirm Deletion",
          content: "Are you sure you want to delete this donation?",
          confirmText: "Delete",
        );

        if (confirm == true) {
          await donationService.removeDonation(context, donationId, userId);
          Navigator.pop(context); // Go back after deleting
        }
      },
    );
  }

  Widget _buildPickedUpButton(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      icon: Icon(Icons.check_circle, color: Colors.white),
      label: Text("Mark as Picked Up", style: TextStyle(color: Colors.white)),
      onPressed: () async {
        // Store the context before the async gap
        final currentContext = context;
        
        List<Map<String, dynamic>> requests =
            await donationService.getDonationRequests(donationId).first;

        var acceptedRequest = requests.firstWhere(
          (request) => request['status'] == 'Accepted',
          orElse: () => {},
        );

        if (acceptedRequest.isNotEmpty) {
          final String requestId = acceptedRequest['requestId'];

          await donationService.updateDonationStatus(donationId, 'Picked Up');
          await donationService.updateDonationRequestStatus(
              donationId, requestId, 'Picked Up');

          // Call refreshPage to update the UI
          refreshPage();
          
          // Removed the Navigator.pop line to stay on the current screen
        } else {
          // Check if the widget is still in the tree before using context
          if (currentContext.mounted) {
            ScaffoldMessenger.of(currentContext).showSnackBar(
              SnackBar(
                content: Text('No accepted request found for this donation'),
              ),
            );
          }
        }
      },
    );
  }
  }

