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
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
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
    required this.donorName, required String chatId,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();

  String _currentStatus = 'available'; // Default status

@override
void initState() {
  super.initState();
  // Trigger scrolling to bottom and mark messages as read
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final String senderId = _auth.currentUser!.uid;
    final String chatId = getChatId(widget.donationId, senderId, widget.receiverId);

    await _markMessagesAsRead(chatId); // Mark messages as read
    _scrollToBottom();
  });
}


  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markMessagesAsRead(String chatId) async {
  try {
    final messagesSnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: _auth.currentUser!.uid)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in messagesSnapshot.docs) {
      await doc.reference.update({'isRead': true});
    }
  } catch (e) {
    print('Error marking messages as read: $e');
  }
}


  Future<void> _sendMessage() async {
  if (_messageController.text.isNotEmpty) {
    final String senderId = _auth.currentUser!.uid;
    final String chatId = getChatId(widget.donationId, senderId, widget.receiverId);

    await _chatService.sendMessage(
      widget.donationId,
      _messageController.text,
      widget.receiverId,
      widget.receiverEmail,
      widget.donationName,
    );

    _messageController.clear();

    // Scroll after UI update
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }
}


  String getChatId(String donationId, String userId, String receiverId) {
    List<String> ids = [donationId, userId, receiverId];
    ids.sort();
    return ids.join('_');
  }

  
  Future<void> _updateDonationStatus(BuildContext context, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('donations')
          .doc(widget.donationId)
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
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  });
}


  Future<String> _getReceiverProfileImage(String receiverId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(receiverId).get();
      return userDoc['profileImageUrl'] ?? '';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String senderId = _auth.currentUser!.uid;
    final String chatId = getChatId(widget.donationId, senderId, widget.receiverId);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            FutureBuilder<String>(
              future: _getReceiverProfileImage(widget.receiverId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return const CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, color: Colors.white),
                  );
                }
                return CircleAvatar(
                  backgroundImage: NetworkImage(snapshot.data!),
                );
              },
            ),
            const SizedBox(width: 10),
            Text("Chat with ${widget.donorName}"),
          ],
        ),
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
    final bool isDonator = widget.userId == _auth.currentUser!.uid;

    return Container(
      width: double.infinity,
      color: Colors.grey.shade200,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Donation Details",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Product Name: ${widget.donationName}",
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            "Donor Email: ${widget.receiverEmail}",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          if (isDonator) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  "Update Status: ",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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

      // Trigger scrolling after new messages are rendered
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      List<Widget> messageWidgets = [];
      DateTime? lastMessageDate;
      for (var message in messages) {
        final data = message.data() as Map<String, dynamic>;
        final messageDate = (data['timestamp'] as Timestamp).toDate();
        final formattedDate = _getFormattedDate(messageDate);

        if (lastMessageDate == null || formattedDate != _getFormattedDate(lastMessageDate)) {
          messageWidgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    formattedDate,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        messageWidgets.add(_buildMessageItem(message));
        lastMessageDate = messageDate;
      }

      return ListView(
        controller: _scrollController,
        children: messageWidgets,
      );
    },
  );
}




  String _getFormattedDate(DateTime date) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    if (isSameDay(today, date)) {
      return "Today";
    } else if (isSameDay(yesterday, date)) {
      return "Yesterday";
    } else {
      final daySuffix = _getDaySuffix(date.day);
      return DateFormat("d'$daySuffix' MMMM yyyy").format(date); 
    }
  }

  bool isSameDay(DateTime day1, DateTime day2) {
    return day1.year == day2.year && day1.month == day2.month && day1.day == day2.day;
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
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
