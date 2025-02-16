import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shelfaware_app/pages/chat_page.dart';
import 'package:intl/intl.dart';
import 'package:badges/badges.dart' as custom_badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/providers/chat_list_provider.dart';
import 'package:shelfaware_app/providers/auth_provider.dart';

class ChatListPage extends ConsumerStatefulWidget {
  @override
  ChatListPageState createState() => ChatListPageState();
}

class ChatListPageState extends ConsumerState<ChatListPage> {
  String _searchQuery = '';
  bool _isDescending = true;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
          return Scaffold(
            appBar: AppBar(
              title: const Text('Chat List'),
            ),
            body: const Center(
              child: Text("You need to be logged in to view this page."),
            ),
          );
        }

        final String currentUserId = user.uid;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Chat List'),
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
                child: ref.watch(chatStreamProvider(_isDescending)).when(
                  data: (snapshot) {
                    if (snapshot.docs.isEmpty) {
                      return const Center(child: Text('No chats available.'));
                    }

                    final chats = snapshot.docs;

                    return ListView.builder(
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final chat = chats[index].data() as Map<String, dynamic>;
                        return _buildChatListItem(context, chat, currentUserId, chats[index].id);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) {
                    print("Error fetching chat data: $error");
                    return const Center(child: Text('Something went wrong. Please check your permissions.'));
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => const Center(child: Text('Something went wrong. Please try again later.')),
    );
  }

  Widget _buildChatListItem(
      BuildContext context, Map<String, dynamic> chat, String currentUserId, String chatId) {
    final participants = chat['participants'];
    List<dynamic> participantsList;
    if (participants is Map) {
      participantsList = participants.values.toList();
    } else if (participants is List) {
      participantsList = participants;
    } else {
      print("Error: participants is not a List or Map");
      return Container(); // Return an empty container if participants is not a List or Map
    }
    final String otherUserId = participantsList.firstWhere((id) => id != currentUserId) as String; // Get the other user's ID.

    print("Other User ID: $otherUserId"); // Debugging line to check if the correct user is being selected.

    return FutureBuilder<String>(
      future: ref.read(chatListServiceProvider).getUserName(otherUserId), // Fetch user name (donor or receiver)
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(
            leading: CircleAvatar(child: CircularProgressIndicator()),
            title: Text('Loading...'),
            subtitle: Text('Loading...'),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          print("Error fetching user name: ${snapshot.error}");
          return _buildChatListItemWidget(context, chat, currentUserId, otherUserId, '', chatId); // Fallback if no name or profile image
        }

        final userName = snapshot.data!;

        // Log the username to verify that it's fetched correctly
        print("User Name: $userName");

        if (_searchQuery.isNotEmpty && !userName.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return Container(); // Hide the chat item if it doesn't match the search query
        }

        return FutureBuilder<String>(
          future: ref.read(chatListServiceProvider).getProfileImageUrl(otherUserId), // Fetch profile image
          builder: (context, profileImageSnapshot) {
            if (profileImageSnapshot.connectionState == ConnectionState.waiting) {
              return const ListTile(
                leading: CircleAvatar(child: CircularProgressIndicator()),
                title: Text('Loading...'),
                subtitle: Text('Loading...'),
              );
            }

            if (profileImageSnapshot.hasError) {
              print("Error fetching profile image: ${profileImageSnapshot.error}");
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
    final participants = chat['participants'];
    List<dynamic> participantsList;
    if (participants is Map) {
      participantsList = participants.values.toList();
    } else if (participants is List) {
      participantsList = participants;
    } else {
      print("Error: participants is not a List or Map");
      return Container(); // Return an empty container if participants is not a List or Map
    }
    final String otherUserId = participantsList.firstWhere((id) => id != currentUserId) as String; // Get the other user's ID.
    final String productName = chat['product']['productName'];
    final String lastMessage = chat['lastMessage'] ?? '';
    final Timestamp timestamp = chat['lastMessageTimestamp'];

    return FutureBuilder<int>(
      future: ref.read(chatListServiceProvider).getUnreadMessagesCount(chatId, currentUserId), // Fetch unread messages count
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print("Error fetching unread messages count: ${snapshot.error}");
        }

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