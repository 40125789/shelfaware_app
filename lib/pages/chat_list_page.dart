import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shelfaware_app/pages/chat_page.dart';
import 'package:intl/intl.dart';

class ChatListPage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> _getProfileImageUrl(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.data()?['profileImageUrl'] ?? ''; // Default to empty if no image URL found
    } catch (e) {
      return ''; // Return empty if there's an error fetching the image
    }
  }

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

    return FutureBuilder<String>(
      future: _getProfileImageUrl(otherUserId), // Fetch profile image
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(
            leading: CircleAvatar(child: CircularProgressIndicator()),
            title: Text('Loading...'),
            subtitle: Text('Loading...'),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildChatListItemWidget(context, chat, currentUserId, ''); // Fallback if no profile image
        }

        final profileImageUrl = snapshot.data!;

        return _buildChatListItemWidget(context, chat, currentUserId, profileImageUrl);
      },
    );
  }

  Widget _buildChatListItemWidget(
      BuildContext context, Map<String, dynamic> chat, String currentUserId, String profileImageUrl) {
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
        backgroundImage: profileImageUrl.isEmpty
            ? const AssetImage('assets/default_profile_image.png') // Default image if no URL
            : NetworkImage(profileImageUrl) as ImageProvider,
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
