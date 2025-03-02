import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shelfaware_app/services/chat_service.dart';
import 'package:profanity_filter/profanity_filter.dart';
import 'package:shelfaware_app/repositories/chat_repository.dart';
import 'package:shelfaware_app/utils/date_utils.dart' as custom_date_utils;
import 'package:shelfaware_app/components/message_item.dart';
import 'package:shelfaware_app/components/donation_details_chat_header.dart';
import 'package:shelfaware_app/components/chat_user_input.dart';

class ChatPage extends StatefulWidget {
  final String receiverEmail;
  final String receiverId;
  final String donationId;
  final String userId;
  final String donationName;
  final String donorName;
  final String chatId;

  ChatPage({
    Key? key,
    required this.receiverEmail,
    required this.receiverId,
    required this.donationId,
    required this.userId,
    required this.donationName,
    required this.donorName,
    required this.chatId,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ChatRepository _chatRepository = ChatRepository(
    firebaseFirestore: FirebaseFirestore.instance,
    firebaseAuth: FirebaseAuth.instance,
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();
  final ProfanityFilter _profanityFilter = ProfanityFilter();

  String _currentStatus = 'available'; // Default status

  @override
  void initState() {
    super.initState();
    // Trigger scrolling to bottom and mark messages as read
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final String senderId = _auth.currentUser!.uid;
      final String chatId = _chatService.getChatId(widget.donationId, senderId, widget.receiverId);

      await _chatRepository.markMessagesAsRead(chatId, senderId); // Mark messages as read
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    String message = _messageController.text;

    if (message.isNotEmpty) {
      // Check for profanity before sending
      bool hasProfanity = _profanityFilter.hasProfanity(message);

      if (hasProfanity) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your message contains inappropriate language!')),
        );
      } else {
        final String senderId = _auth.currentUser!.uid;
        final String chatId = getChatId(widget.donationId, senderId, widget.receiverId);

        await _chatRepository.sendMessage(
          widget.donationId,
          message,
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

      setState(() {
        _currentStatus = newStatus;
      });

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
      return await _chatRepository.getReceiverProfileImage(receiverId);
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
      ),
      body: Column(
        children: [
          DonationDetailsHeader(
            donationName: widget.donationName,
           
          
            donationId: widget.donationId,
        
          ),
          Expanded(child: _buildMessageList(chatId)),
          UserInput(
            messageController: _messageController,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(String chatId) {
    return StreamBuilder(
      stream: _chatRepository.getMessages(chatId),
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
          final formattedDate = custom_date_utils.DateUtils.getFormattedDate(messageDate);

          if (lastMessageDate == null || formattedDate != custom_date_utils.DateUtils.getFormattedDate(lastMessageDate)) {
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

          messageWidgets.add(MessageItem(doc: message));
          lastMessageDate = messageDate;
        }

        return ListView(
          controller: _scrollController,
          children: messageWidgets,
        );
      },
    );
  }
}