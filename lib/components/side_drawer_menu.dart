import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shelfaware_app/pages/chat_list_page.dart';
import 'package:shelfaware_app/pages/history_page.dart';
import 'package:shelfaware_app/pages/icon_selection_page.dart';
import 'package:shelfaware_app/pages/my_donations_page.dart';

class CustomDrawer extends StatefulWidget {
  final String firstName;
  final String lastName;
  final VoidCallback onSignOut;
  final VoidCallback onNavigateToFavorites;

  const CustomDrawer({
    Key? key,
    required this.firstName,
    required this.lastName,
    required this.onSignOut,
    required this.onNavigateToFavorites,
  }) : super(key: key);

  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  // Load the user's profile image from Firestore
  Future<void> _loadProfileImage() async {
    try {
      final String userId = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      // Check if the document exists and profileImageUrl is valid
      if (userDoc.exists) {
        final profileImageUrl = userDoc.data()?['profileImageUrl'] ?? '';
        setState(() {
          _profileImageUrl = profileImageUrl.isNotEmpty ? profileImageUrl : null;
        });
      } else {
        setState(() {
          _profileImageUrl = null; // Use default avatar if no URL is found
        });
      }
    } catch (e) {
      print('Error loading profile image: $e');
    }
  }


    // Navigate to the icon selection screen
  void _navigateToIconSelection() async {
    final selectedIconUrl = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => IconSelectionScreen(),
      ),
    );

    // If an icon is selected, update the user's profile with the selected icon URL
    if (selectedIconUrl != null && selectedIconUrl.isNotEmpty) {
      // Optimistic update: Reflect the change immediately in the UI
      _updateUserProfileWithIcon(selectedIconUrl);
    }
  }

  // Update the user's profile with the selected icon
  Future<void> _updateUserProfileWithIcon(String iconUrl) async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'profileImageUrl': iconUrl,
      });
    } catch (e) {
      print('Error updating profile image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // Profile Picture Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _navigateToIconSelection, // Navigate to Icon Selection Screen
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .snapshots(), // Listen to real-time updates
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircleAvatar(
                          radius: 30,
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError) {
                        return const CircleAvatar(
                          radius: 30,
                          child: Icon(Icons.error, color: Colors.red),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data == null) {
                        return const CircleAvatar(
                          radius: 30,
                          backgroundImage:
                              AssetImage('assets/default_avatar.png'),
                        );
                      }

                      var profileImageUrl = snapshot.data!.get('profileImageUrl');
                      profileImageUrl = profileImageUrl ?? ''; // Default to empty string if null

                      return CircleAvatar(
                        radius: 30,
                        backgroundImage: profileImageUrl.isNotEmpty
                            ? NetworkImage(profileImageUrl)
                            : const AssetImage('assets/default_avatar.png')
                                as ImageProvider,
                        child: profileImageUrl.isEmpty
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${widget.firstName} ${widget.lastName}",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      "Edit Profile Picture",
                      style: TextStyle(fontSize: 14, color: Colors.blue),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(indent: 16, endIndent: 16, color: Colors.grey),
          

          // Drawer List Items
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('My Groups'),
            onTap: () {
              // Define action for My Groups
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('History'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => HistoryPage(
                        userId: FirebaseAuth.instance.currentUser!.uid)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('Recipe Favourites'),
            onTap: widget.onNavigateToFavorites,
          ),
          const Divider(indent: 16, endIndent: 16, color: Colors.grey),
          ListTile(
            leading: const Icon(Icons.message),
            title: const Text('Messages'),
            onTap: () {
              // Navigate to ChatListPage
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatListPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.food_bank),
            title: const Text('My Donation Listings'),
            onTap: () {
              final userId = FirebaseAuth.instance.currentUser!.uid;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyDonationsPage(userId: userId),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              // Define action for Settings
            },
          ),
          const Divider(indent: 16, endIndent: 16, color: Colors.grey),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log off'),
            onTap: widget.onSignOut,
          ),
        ],
      ),
    );
  }
}

