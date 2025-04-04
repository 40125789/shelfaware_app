import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessageItem extends StatelessWidget {
  final DocumentSnapshot doc;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  MessageItem({required this.doc, required ValueKey<String> key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final bool isCurrentUser = data['senderId'] == _auth.currentUser!.uid;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Column(
        crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            decoration: BoxDecoration(
              color: isCurrentUser ? Colors.blueAccent : Colors.greenAccent,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(15),
                topRight: const Radius.circular(15),
                bottomLeft: isCurrentUser ? const Radius.circular(15) : const Radius.circular(0),
                bottomRight: isCurrentUser ? const Radius.circular(0) : const Radius.circular(15),
              ),
            ),
            child: Text(
              data['message'],
              style: TextStyle(
                color: isCurrentUser ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${DateFormat('HH:mm').format(data['timestamp'].toDate())} - ${data['senderEmail']}",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}