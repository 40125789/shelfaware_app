import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shelfaware_app/pages/chat_page.dart';
import 'package:intl/intl.dart';

class ChatListPage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final String currentUserId = _auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder(
        stream: _firestore
            .collection('chats')
            .where('participants', arrayContains: currentUserId)
            .orderBy('lastMessageTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No chats available.'));
          }

          final chats = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index].data();
              return _buildChatListItem(context, chat, currentUserId);
            },
          );
        },
      ),
    );
  }

  Widget _buildChatListItem(
      BuildContext context, Map<String, dynamic> chat, String currentUserId) {
    final String otherUserId = (chat['participants'] as List)
        .firstWhere((id) => id != currentUserId); // Get the other user's ID.
    final String displayName = chat['donorId'] == otherUserId
        ? "Donor"
        : "Receiver"; // Identify if the user is chatting as the donor or receiver.
    final String productName = chat['product']['productName'];
    final String lastMessage = chat['lastMessage'] ?? '';
    final Timestamp timestamp = chat['lastMessageTimestamp'];

    return ListTile(
      leading: CircleAvatar(
        child: Text(displayName[0].toUpperCase()), // First letter of the role.
      ),
      title: Text(displayName),
      subtitle: Text(
        "Product: $productName\nLast Message: $lastMessage",
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate()),
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              receiverEmail: '', // Fetch or pass if available.
              receiverId: otherUserId,
              donationId: chat['product']['donationId'],
              userId: currentUserId,
              donationName: productName,
              donorName: displayName,
            ),
          ),
        );
      },
    );
  }
}




