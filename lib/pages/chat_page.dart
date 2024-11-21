import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shelfaware_app/services/chat_service.dart';
import 'package:shelfaware_app/models/message.dart';

class ChatPage extends StatelessWidget {
  final String receiverEmail;
  final String receiverId;
  final String donationId;
  final String userId;
  final String donationName;
  final String donorName;

  // Constructor to accept parameters and store them
  ChatPage({
    super.key,
    required this.receiverEmail,
    required this.receiverId,
    required this.donationId,
    required this.userId,
    required this.donationName,
    required this.donorName,
     required String productName, 
     required String chatId, 
     required String donatorId,
  });

  // Text controller for message input
  final TextEditingController _messageController = TextEditingController();

  // Chat and auth service
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate a unique chatId based on donationId and userIds
  String getChatId(String donationId, String userId, String receiverId) {
    List<String> ids = [donationId, userId, receiverId];
    ids.sort(); // Ensure chatId is consistently created
    return ids.join('_');
  }

  // Send message
  Future<void> _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      // Generate the chatId dynamically
      String chatId = getChatId(donationId, userId, receiverId);

      // Send message using the new chatId
      await _chatService.sendMessage(
        donationId,
        _messageController.text,
        receiverId,
        userId,
        _auth.currentUser!.email!,
        receiverEmail,
        chatId,
        donationName,
        donorName,

      );

      // Clear the text field
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat with $donorName"),
      ),
      body: Column(
        children: [
          // Donation details header
          _buildDonationDetailsHeader(),

          // Messages list
          Expanded(child: _buildMessageList()),

          // User input
          _buildUserInput(),
        ],
      ),
    );
  }

  // Build the donation details header
  Widget _buildDonationDetailsHeader() {
    return Container(
      width: double.infinity,
      color: Colors.grey.shade200,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Donation Details",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Product Name: $donationName",
            style: TextStyle(fontSize: 16),
          ),
          Text(
            "Donor Email: $receiverEmail",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  // Build the message list
  Widget _buildMessageList() {
    String senderId = _auth.currentUser!.uid;

    return StreamBuilder(
      stream: _chatService.getMessages(donationId, senderId, receiverId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          children: snapshot.data!.docs.map((doc) => _buildMessageItem(doc)).toList(),
        );
      },
    );
  }

  // Build individual message item
  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return ListTile(
      title: Text(data['message']),
      subtitle: Text(data['senderEmail']), // Display sender's email (optional)
    );
  }

  // Build the user input field (message text field)
  Widget _buildUserInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(hintText: 'Type a message'),
              obscureText: false,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
