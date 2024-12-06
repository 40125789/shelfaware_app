import 'package:flutter/material.dart';

class DonationDetailsDialog extends StatelessWidget {
  final String itemName;
  final String formattedExpiryDate;
  final String donorName;
  final String address;
  final Function onContactDonor;

  const DonationDetailsDialog({
    Key? key,
    required this.itemName,
    required this.formattedExpiryDate,
    required this.donorName,
    required this.address,
    required this.onContactDonor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Product Name: $itemName',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: Padding(
        padding: const EdgeInsets.all(10.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.date_range, color: Colors.blue),
                  SizedBox(width: 10),
                  Text(
                    'Expires on:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 5),
                  Text(
                    formattedExpiryDate,
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.person, color: Colors.green),
                  SizedBox(width: 10),
                  Text(
                    'Donor:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 5),
                  Text(donorName),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.orange),
                  SizedBox(width: 10),
                  Text(
                    'Location:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      address,
                      style: TextStyle(color: Colors.blue),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onContactDonor(); // Trigger the contact donor action
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.message, size: 18, color: Colors.green),
              SizedBox(width: 5),
              Text('Contact Donor'),
            ],
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    );
  }
}
