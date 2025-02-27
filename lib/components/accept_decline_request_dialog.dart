import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AcceptDeclineRequestDialog extends StatelessWidget {
  final String requesterName;
  final String requesterProfileImageUrl;
  final DateTime pickupDateTime;
  final String message;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  AcceptDeclineRequestDialog({
    required this.requesterName,
    required this.requesterProfileImageUrl,
    required this.pickupDateTime,
    required this.message,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0), // Rounded corners
      ),
      backgroundColor: Colors.white, // Background color for the dialog
      title: Column(
        children: [
          Text(
            "Request from $requesterName",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          // Requester's profile picture with a little margin
          CircleAvatar(
            backgroundImage: NetworkImage(requesterProfileImageUrl),
            radius: 30,
          ),
        ],
      ),
      content: SingleChildScrollView(
        // Added to ensure dialog size is limited and scrollable
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // Centered the entire content
            children: [
              // Pickup Date & Time with only the label being bold
              Text(
                "Pickup Date & Time",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                "${DateFormat('dd MMM yyyy, HH:mm').format(pickupDateTime)}",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Message:",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 4),
              // Centered message text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0), // Added padding for message
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center, // Centered the message text
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: onAccept,
              child: Text("Accept", style: TextStyle(fontSize: 16, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(100, 40),
              ),
            ),
            ElevatedButton(
              onPressed: onDecline,
              child: Text("Decline", style: TextStyle(fontSize: 16, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: Size(100, 40),
              ),
            ),
          ],
        ),
      ],
    );
  }
}