import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shelfaware_app/services/chat_service.dart';
import 'package:shelfaware_app/models/message.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shelfaware_app/services/chat_service.dart';
import 'package:shelfaware_app/models/message.dart';

class ChatPage extends StatelessWidget {
  final String receiverEmail;
  final String receiverId;
  final String donationId;
  final String userId;
  final String donationName;
  final String donorName;

  ChatPage({
    Key? key,
    required this.receiverEmail,
    required this.receiverId,
    required this.donationId,
    required this.userId,
    required this.donationName,
    required this.donorName,
  }) : super(key: key);

  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();

  String _currentStatus = 'available'; // Default status

  String getChatId(String donationId, String userId, String receiverId) {
    List<String> ids = [donationId, userId, receiverId];
    ids.sort();
    return ids.join('_');
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      final String senderId = _auth.currentUser!.uid;
      final String chatId = getChatId(donationId, senderId, receiverId);

      await _chatService.sendMessage(
        donationId,
        _messageController.text,
        receiverId,
        receiverEmail,
        donationName,
      );

      _messageController.clear();
      _scrollToBottom();
    }
  }

  Future<void> _updateDonationStatus(BuildContext context, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('donations')
          .doc(donationId)
          .update({'status': newStatus});

      _currentStatus = newStatus;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final String senderId = _auth.currentUser!.uid;
    final String chatId = getChatId(donationId, senderId, receiverId);

    return Scaffold(
      appBar: AppBar(
        title: Text("Chat with $donorName"),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          _buildDonationDetailsHeader(context),
          Expanded(child: _buildMessageList(chatId)),
          _buildUserInput(),
        ],
      ),
    );
  }
Widget _buildDonationDetailsHeader(BuildContext context) {
  // Check if the logged-in user is the donor.
  final bool isDonator = userId == _auth.currentUser!.uid;
  
  // Debugging: Print the values to check if the condition is correct
  print('userId: $userId, logged-in userId: ${_auth.currentUser!.uid}');
  
  return Container(
    width: double.infinity,
    color: Colors.grey.shade200,
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Reduced padding
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Donation Details",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16, // Slightly smaller font size
          ),
        ),
        const SizedBox(height: 4), // Reduced space
        Text(
          "Product Name: $donationName",
          style: const TextStyle(fontSize: 14), // Smaller font size for product name
        ),
        Text(
          "Donor Email: $receiverEmail",
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700), // Smaller font size for email
        ),
        if (isDonator) ...[ // Only show this section if the user is the donor
          const SizedBox(height: 8), // Adjust space for better layout
          Row(
            children: [
              const Text(
                "Update Status: ",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold), // Smaller font size
              ),
              DropdownButton<String>(
                value: _currentStatus,
                onChanged: (String? newStatus) {
                  if (newStatus != null) {
                    _updateDonationStatus(context, newStatus);
                  }
                },
                items: const [
                  DropdownMenuItem(
                    value: 'available',
                    child: Text('Available'),
                  ),
                  DropdownMenuItem(
                    value: 'claimed',
                    child: Text('Claimed'),
                  ),
                  DropdownMenuItem(
                    value: 'completed',
                    child: Text('Completed'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

  

  Widget _buildMessageList(String chatId) {
    return StreamBuilder(
      stream: _chatService.getMessages(chatId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data!.docs;

        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return ListView.builder(
          controller: _scrollController,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            return _buildMessageItem(messages[index]);
          },
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final bool isCurrentUser = data['senderId'] == _auth.currentUser!.uid;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Column(
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            decoration: BoxDecoration(
              color: isCurrentUser ? Colors.blueAccent : Colors.greenAccent,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(15),
                topRight: const Radius.circular(15),
                bottomLeft: isCurrentUser
                    ? const Radius.circular(15)
                    : const Radius.circular(0),
                bottomRight: isCurrentUser
                    ? const Radius.circular(0)
                    : const Radius.circular(15),
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

  Widget _buildUserInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(hintText: 'Type a message'),
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