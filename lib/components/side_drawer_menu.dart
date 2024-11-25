import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shelfaware_app/pages/chat_list_page.dart';
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

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  // Load profile image from Firestore
  Future<void> _loadProfileImage() async {
    try {
      final String userId = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      // Check if the document exists and the profileImageUrl is present
      if (userDoc.exists && userDoc.data()?['profileImageUrl'] != null) {
        setState(() {
          _profileImageUrl = userDoc.data()?['profileImageUrl'];
        });
      } else {
        setState(() {
          _profileImageUrl = null; // Use default avatar if not found
        });
      }
    } catch (e) {
      print('Error loading profile image: $e');
    }
  }

  // Upload profile image to Firestore
  Future<void> _uploadProfileImage() async {
    try {
      // Select image from gallery
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) {
        print('No image selected.');
        return;
      }

      // Check if the user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('User is not authenticated');
        return;
      }

      final uid = user.uid;
      final storageRef = FirebaseStorage.instance.ref().child('profile_images').child('$uid.jpg');

      // Start uploading the image
      setState(() {
        _isUploading = true;
      });

      await storageRef.putFile(File(pickedFile.path));

      // Get the download URL after the upload is complete
      final downloadUrl = await storageRef.getDownloadURL();

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
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: _profileImageUrl != null
                        ? NetworkImage(_profileImageUrl!)
                        : const AssetImage('assets/default_avatar.png') as ImageProvider,
                    child: _profileImageUrl == null
                        ? _isUploading
                            ? CircularProgressIndicator()  // Show loading spinner while uploading
                            : const Icon(Icons.camera_alt, color: Colors.white)
                        : null,
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
              // Define action for History
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
                  
                  builder: (context) => ChatListPage(
            
                    // Replace `ChatListPage()` with your actual Chat List Page widget.
                  ),
                ),
              );
          
                  
                   
                  
             
                 
               // Replace `ChatListPage()` with your actual Chat List Page widget.
              
            },
          ),
                
              
            
          
          ListTile(
            leading: const Icon(Icons.food_bank),
            title: const Text('My Donation Listings'),
            onTap: () {
              // Retrieve the current user's UID
              final userId = FirebaseAuth.instance.currentUser!.uid;

              // Navigate to MyDonationsPage
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyDonationsPage(
                    userId: userId,
                  ),
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

