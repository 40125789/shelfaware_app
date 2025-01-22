import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:shelfaware_app/pages/chat_list_page.dart';
import 'package:shelfaware_app/pages/groups_page.dart';
import 'package:shelfaware_app/pages/history_page.dart';
import 'package:shelfaware_app/pages/my_donations_page.dart';
import 'package:shelfaware_app/pages/my_profile.dart';
import 'package:shelfaware_app/pages/watched_donations_page.dart';


class CustomDrawer extends StatefulWidget {
  final String firstName;
  final String lastName;
  final VoidCallback onSignOut;
  final VoidCallback onNavigateToFavorites;
  final VoidCallback onNavigateToDonationWatchList;

  const CustomDrawer({
    Key? key,
    required this.firstName,
    required this.lastName,
    required this.onSignOut,
    required this.onNavigateToFavorites,
    required this.onNavigateToDonationWatchList,
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
      debugPrint('Error loading profile image: $e');
    }
  }

  // Get the current location
  Future<Position> _getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  // Upload a new profile image
  Future<void> _uploadProfileImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) {
        debugPrint('No image selected.');
        return;
      }

      setState(() {
        _isUploading = true;
      });

      final uploadTask = storageRef.putFile(File(pickedFile.path));

      uploadTask.snapshotEvents.listen((taskSnapshot) {
        double progress =
            taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
        debugPrint('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
      });

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'profileImageUrl': downloadUrl,
      });

      setState(() {
        _profileImageUrl = downloadUrl;
        _isUploading = false;
      });

      debugPrint('Profile image uploaded successfully!');
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      debugPrint('Error uploading profile image: $e');
    }
  }

 @override
Widget build(BuildContext context) {
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        // Profile Picture Section/navigation to user profile
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(userId: uid),
                  ),
                );
              },

                     // Navigate to ProfilePage
          child: Row(
            children: [
              GestureDetector(
                onTap: _uploadProfileImage,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: _profileImageUrl != null &&
                              _profileImageUrl!.isNotEmpty
                          ? CachedNetworkImageProvider(_profileImageUrl!)
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
                    "My Profile",
                    style: TextStyle(fontSize: 18, 
                    fontWeight: FontWeight.normal,
                    color: Colors.green),
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
        const Divider(indent: 16.0, endIndent: 16.0, color: Colors.grey),

        // Drawer List Items - Section 1
        ListTile(
          leading: const Icon(Icons.group),
          title: const Text('My Groups'),
          onTap: () {
            // Define action for My Groups
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroupsPage(userId: FirebaseAuth.instance.currentUser?.uid),
              ),  
            );
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
        const Divider(indent: 16.0, endIndent: 16.0, color: Colors.grey),

        // Drawer List Items - Section 2
        ListTile(
          leading: const Icon(Icons.favorite),
          title: const Text('Recipe Favourites'),
          onTap: widget.onNavigateToFavorites,
        ),
        ListTile(
            leading: const Icon(Icons.star),
  title: const Text('Donation WatchList'),
  onTap: () async {
    // Get the current user ID
    final userId = FirebaseAuth.instance.currentUser!.uid;

    // Get the current location
    try {
      Position position = await _getCurrentLocation();  // Get dynamic location
      LatLng currentLocation = LatLng(position.latitude, position.longitude);

      // Navigate to WatchedDonationsPage with userId and currentLocation
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WatchedDonationsPage(
            userId: userId,
            currentLocation: currentLocation,
          ),
        ),
      );
    } catch (e) {
      // Handle errors (e.g., if location service is unavailable or permission denied)
      print('Error getting location: $e');
      // Optionally show a message to the user
    }
  },
),
          
        const Divider(indent: 16.0, endIndent: 16.0, color: Colors.grey),

        // Drawer List Items - Section 3
        ListTile(
          leading: const Icon(Icons.message),
          title: const Text('Messages'),
          onTap: () {
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
          title: const Text('Manage Donations'),
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
        const Divider(indent: 16.0, endIndent: 16.0, color: Colors.grey),

        // Drawer List Items - Section 4
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text('Settings'),
          onTap: () {
            // Define action for Settings
          },
        ),
        const Divider(indent: 16.0, endIndent: 16.0, color: Colors.grey),

        // Drawer List Items - Logout Section
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
