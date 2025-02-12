import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shelfaware_app/pages/chat_page.dart';
import 'package:intl/intl.dart';
import 'package:badges/badges.dart' as custom_badge;

class ChatListPage extends StatefulWidget {
  @override
  ChatListPageState createState() => ChatListPageState();
}

class ChatListPageState extends State<ChatListPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  bool _isDescending = true;

  // Fetch the profile image URL of the user
  Future<String> _getProfileImageUrl(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.data()?['profileImageUrl'] ?? ''; // Default to empty if no image URL found
    } catch (e) {
      return ''; // Return empty if there's an error fetching the image
    }
  }

  // Fetch the name of the user/donor
  Future<String> _getUserName(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.data()?['firstName'] ?? 'Unknown User'; // Default if no name found
    } catch (e) {
      return 'Unknown User'; // Return fallback if there's an error
    }
  }

  // Fetch the number of unread messages for a chat
  Future<int> _getUnreadMessagesCount(String chatId, String currentUserId) async {
    try {
      final querySnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .where('receiverId', isEqualTo: currentUserId)
          .get();
      return querySnapshot.docs.length;
    } catch (e) {
      return 0; // Return 0 if there's an error
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = _auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: Icon(_isDescending ? Icons.arrow_downward : Icons.arrow_upward),
            onPressed: () {
              setState(() {
                _isDescending = !_isDescending;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by Name...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: _firestore
                  .collection('chats')
                  .where('participants', arrayContains: currentUserId)
                  .orderBy('lastMessageTimestamp', descending: _isDescending)
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
                    final chat = chats[index].data() as Map<String, dynamic>;
                    return _buildChatListItem(context, chat, currentUserId, chats[index].id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatListItem(
      BuildContext context, Map<String, dynamic> chat, String currentUserId, String chatId) {
    final String otherUserId = (chat['participants'] as List)
        .firstWhere((id) => id != currentUserId); // Get the other user's ID.
    final String productName = chat['product']['productName'];
    final String lastMessage = chat['lastMessage'] ?? '';
    final Timestamp timestamp = chat['lastMessageTimestamp'];

    return FutureBuilder<String>(
      future: _getUserName(otherUserId), // Fetch user name (donor or receiver)
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(
            leading: CircleAvatar(child: CircularProgressIndicator()),
            title: Text('Loading...'),
            subtitle: Text('Loading...'),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildChatListItemWidget(context, chat, currentUserId, '', '', chatId); // Fallback if no name or profile image
        }

        final userName = snapshot.data!;

        if (_searchQuery.isNotEmpty && !userName.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return Container(); // Hide the chat item if it doesn't match the search query
        }

        return FutureBuilder<String>(
          future: _getProfileImageUrl(otherUserId), // Fetch profile image
          builder: (context, profileImageSnapshot) {
            if (profileImageSnapshot.connectionState == ConnectionState.waiting) {
              return const ListTile(
                leading: CircleAvatar(child: CircularProgressIndicator()),
                title: Text('Loading...'),
                subtitle: Text('Loading...'),
              );
            }

            final profileImageUrl = profileImageSnapshot.data ?? ''; // Fallback if no image URL

            return _buildChatListItemWidget(context, chat, currentUserId, userName, profileImageUrl, chatId);
          },
        );
      },
    );
  }

  Widget _buildChatListItemWidget(
      BuildContext context, Map<String, dynamic> chat, String currentUserId, String userName, String profileImageUrl, String chatId) {
    final String otherUserId = (chat['participants'] as List)
        .firstWhere((id) => id != currentUserId); // Get the other user's ID.
    final String productName = chat['product']['productName'];
    final String lastMessage = chat['lastMessage'] ?? '';
    final Timestamp timestamp = chat['lastMessageTimestamp'];

    return FutureBuilder<int>(
      future: _getUnreadMessagesCount(chatId, currentUserId), // Fetch unread messages count
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: profileImageUrl.isEmpty
                ? const AssetImage('assets/default_profile_image.png') // Default image if no URL
                : NetworkImage(profileImageUrl) as ImageProvider,
          ),
          title: Text(
            userName, // Display the name of the other user
            style: TextStyle(
              fontWeight: FontWeight.bold, // Make the name bold
              fontSize: 16, // Increase font size
              // Make the name a dark color to stand out
            ),
          ),
          subtitle: Text(
            "Product: $productName\nLast Message: $lastMessage",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate()),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              if (unreadCount > 0)
                Column(
                  children: [
                    custom_badge.Badge(
                      badgeContent: Text(
                        unreadCount.toString(),
                        style: TextStyle(color: Colors.white),
                      ),
                      child: Icon(Icons.message),
                    ),
                    Text(
                      'Unread messages',
                      style: TextStyle(color: Colors.red, fontSize: 10),
                    ),
                  ],
                ),
            ],
          ),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  receiverEmail: '', // Fetch or pass if available.
                  receiverId: otherUserId,
                  donationId: chat['product']['donationId'],
                  userId: currentUserId,
                  donationName: productName,
                  donorName: userName, chatId: '', // Pass the name of the user here
                ),
              ),
            );
            setState(() {}); // Refresh the chat list to update unread messages count
          },
        );
      },
    );
  }
}
