import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shelfaware_app/pages/chat_list_page.dart';
import 'package:shelfaware_app/pages/history_page.dart';
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
  bool _isUploading = false;
  late String uid;
  late Reference storageRef;

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser!.uid;
    storageRef =
        FirebaseStorage.instance.ref().child('user_profile_images/$uid.jpg');
    _loadProfileImage();
  }

  // Load the profile image from Firestore
  Future<void> _loadProfileImage() async {
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists && userDoc.data()?['profileImageUrl'] != null) {
        setState(() {
          _profileImageUrl = userDoc.data()?['profileImageUrl'];
        });
      }
    } catch (e) {
      print('Error loading profile image: $e');
    }
  }

  // Upload a new profile image
  Future<void> _uploadProfileImage() async {
    try {
      // Select image from gallery
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) {
        print('No image selected.');
        return;
      }

      print('Picked file path: ${pickedFile.path}'); // Log the path

      setState(() {
        _isUploading = true;
      });

      // Start uploading the image to Firebase Storage
      final uploadTask = storageRef.putFile(File(pickedFile.path));

      uploadTask.snapshotEvents.listen((taskSnapshot) {
        double progress =
            taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
        print('Upload is $progress% complete');
      });

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Update the user's profile image URL in Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'profileImageUrl': downloadUrl,
      });

      setState(() {
        _profileImageUrl = downloadUrl;
        _isUploading = false;
      });

      print('Profile image uploaded successfully!');
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      print('Error uploading profile image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  onTap: _uploadProfileImage, // Trigger image upload
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: _profileImageUrl != null &&
                                _profileImageUrl!.isNotEmpty
                            ? NetworkImage(_profileImageUrl!)
                            : const AssetImage('assets/default_avatar.png')
                                as ImageProvider,
                        child: _profileImageUrl == null ||
                                _profileImageUrl!.isEmpty
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      if (_isUploading)
                        const CircularProgressIndicator(
                          color: Colors.white,
                        ),
                    ],
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
