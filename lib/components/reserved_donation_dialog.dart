import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

class ReservedDonationDialog extends StatelessWidget {
  final String assignedToName;
  final Future<String?> profileImageFuture;

  ReservedDonationDialog({
    required this.assignedToName,
    required this.profileImageFuture,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      backgroundColor: Colors.white,
      title: Center(
        child: Text(
          "This Donation has been reserved for:",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
          textAlign: TextAlign.center,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FutureBuilder<String?>(
            future: profileImageFuture,
            builder: (context, imageSnapshot) {
              if (imageSnapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }
              if (imageSnapshot.hasError) {
                return Icon(Icons.error, color: Colors.red);
              }
              final profileImageUrl = imageSnapshot.data ?? '';
              return CircleAvatar(
                backgroundImage: profileImageUrl.isNotEmpty
                    ? NetworkImage(profileImageUrl)
                    : null,
                radius: 40,
                child: profileImageUrl.isEmpty
                    ? Icon(Icons.person, color: Colors.white, size: 40)
                    : null,
              );
            },
          ),
          SizedBox(height: 16),
          Text(
            assignedToName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
            },
            child: Text("OK"),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ),
      ],
      actionsAlignment: MainAxisAlignment.center, // Center the button
    );
  }
}