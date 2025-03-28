import 'package:flutter/material.dart';
import 'package:shelfaware_app/services/donation_service.dart';

class EditPickupDetailsDialog extends StatelessWidget {
  final String donationId;
  final String initialPickupTimes;
  final String initialPickupInstructions;
  final DonationService donationService;
  final Function() refreshPage;

  EditPickupDetailsDialog({
    Key? key,
    required this.donationId,
    required this.initialPickupTimes,
    required this.initialPickupInstructions,
    required this.donationService,
    required this.refreshPage,
  }) : super(key: key);

  final TextEditingController _pickupTimesController = TextEditingController();
  final TextEditingController _pickupInstructionsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    _pickupTimesController.text = initialPickupTimes;
    _pickupInstructionsController.text = initialPickupInstructions;

    return AlertDialog(
      title: Text("Edit Pickup Details"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pickupTimesController,
            decoration: InputDecoration(labelText: "Pickup Times"),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _pickupInstructionsController,
            decoration: InputDecoration(labelText: "Pickup Instructions"),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        TextButton(
          onPressed: () => _savePickupDetails(context),
          child: Text("Save"),
        ),
      ],
    );
  }

  Future<void> _savePickupDetails(BuildContext context) async {
    await donationService.updateDonationPickupDetails(
      donationId,
      _pickupTimesController.text.trim(),
      _pickupInstructionsController.text.trim(),
    );
    Navigator.pop(context);
    refreshPage();

    // Show success snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pickup details updated successfully'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
}