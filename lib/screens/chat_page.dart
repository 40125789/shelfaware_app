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

/// ChatPage Screen
/// 
/// This file implements a real-time chat interface between users discussing a donation.
/// 
/// Some parts of this implementation were developed with assistance from
/// ChatGPT (OpenAI) and modified to fit the application's specific requirements.
/// Specifically, the UI animations, message grouping by date, and profanity filtering
/// logic were implemented with AI assistance.
/// 
/// References:
/// - OpenAI. (2023). ChatGPT [Large language model].
///   https://chat.openai.com

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

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ChatRepository _chatRepository = ChatRepository(
    firebaseFirestore: FirebaseFirestore.instance,
    firebaseAuth: FirebaseAuth.instance,
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();
  final ProfanityFilter _profanityFilter = ProfanityFilter();
  
  late AnimationController _typingController;
  late Animation<double> _typingAnimation;
  String donationstatus = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Animation controller for typing indicator
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    
    _typingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _typingController, curve: Curves.easeInOut)
    );
    
    // Trigger scrolling to bottom and mark messages as read
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final String senderId = _auth.currentUser!.uid;
      final String chatId = _chatService.getChatId(widget.donationId, senderId, widget.receiverId);

      await _chatRepository.markMessagesAsRead(chatId, senderId); // Mark messages as read
      _scrollToBottom();

      // Fetch donation status
      final status = await _chatRepository.getDonationStatus(widget.donationId) ?? '';
      setState(() {
        donationstatus = status;
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _typingController.dispose();
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
          const SnackBar(
            content: Text('Your message contains inappropriate language!'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final String senderId = _auth.currentUser!.uid;
        final String chatId = getChatId(widget.donationId, senderId, widget.receiverId);

        _messageController.clear();
        
        await _chatRepository.sendMessage(
          widget.donationId,
          message,
          widget.receiverId,
          widget.receiverEmail,
          widget.donationName,
        );

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
    return WillPopScope(
      onWillPop: () async {
        final String senderId = _auth.currentUser!.uid;
        final String chatId = getChatId(widget.donationId, senderId, widget.receiverId);
        await _chatRepository.markMessagesAsRead(chatId, senderId); // Mark messages as read
        return true; // Allow back navigation
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 2,
          backgroundColor: Theme.of(context).primaryColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
          ),
          title: Row(
            children: [
              Hero(
                tag: 'profile-${widget.receiverId}',
                child: FutureBuilder<String>(
                  future: _getReceiverProfileImage(widget.receiverId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white24,
                        child: SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                      return CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        child: const Icon(Icons.person, color: Colors.white),
                      );
                    }
                    return CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(snapshot.data!),
                      backgroundColor: Colors.white,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Text(
                widget.donorName,
                style: const TextStyle(
                  fontSize: 18, // Bigger text
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Colors.white, // White text
                ),
              ),
            ],
          ),
        ),
        body: _isLoading 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading conversation...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.1),
                    Colors.white,
                    const Color(0xFFF8F9FA),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: FutureBuilder<String?>(
                      future: _chatRepository.getDonationStatus(widget.donationId),
                      builder: (context, snapshot) {
                        final status = snapshot.data ?? donationstatus;
                        return DonationDetailsHeader(
                          donationName: widget.donationName,
                          donationId: widget.donationId, 
                          status: status,
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildMessageList(chatId),
                  ),
                  UserInput(
                    messageController: _messageController,
                    onSend: _sendMessage,
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildMessageList(String chatId) {
    return StreamBuilder(
      stream: _chatRepository.getMessages(chatId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Theme.of(context).primaryColor.withOpacity(0.8),
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading messages...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        final messages = snapshot.data!.docs;

        // No messages yet
        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline, 
                  size: 70, 
                  color: Theme.of(context).primaryColor.withOpacity(0.5)
                ),
                const SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start the conversation!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        // Trigger scrolling after new messages are rendered
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });

        List<Widget> messageWidgets = [];
        DateTime? lastMessageDate;
        final currentUserId = _auth.currentUser!.uid;
        
        for (var message in messages) {
          final data = message.data() as Map<String, dynamic>;
          final messageDate = (data['timestamp'] as Timestamp).toDate();
          final formattedDate = custom_date_utils.DateUtils.getFormattedDate(messageDate);

          if (lastMessageDate == null || formattedDate != custom_date_utils.DateUtils.getFormattedDate(lastMessageDate)) {
            messageWidgets.add(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 14.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor.withOpacity(0.7),
                          Theme.of(context).primaryColor.withOpacity(0.9),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      formattedDate,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          final isCurrentUser = data['senderId'] == currentUserId;
          
          messageWidgets.add(
            Align(
              alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: MessageItem(
                  key: ValueKey(message.id),
                  doc: message,
                ),
              ),
            ),
          );
          
          lastMessageDate = messageDate;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: ListView(
            controller: _scrollController,
            children: messageWidgets,
          ),
        );
      },
    );
  }
}
