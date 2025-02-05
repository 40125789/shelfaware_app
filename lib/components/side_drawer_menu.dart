import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shelfaware_app/pages/chat_list_page.dart';
import 'package:shelfaware_app/pages/groups_page.dart';
import 'package:shelfaware_app/pages/history_page.dart';
import 'package:shelfaware_app/pages/my_donations_page.dart';
import 'package:shelfaware_app/pages/my_profile.dart';
import 'package:shelfaware_app/pages/settings_page.dart';
import 'package:shelfaware_app/pages/watched_donations_page.dart';
import 'package:shelfaware_app/providers/auth_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shelfaware_app/providers/profile_image_provider.dart';

final isUploadingProvider = StateProvider<bool>((ref) => false);

class CustomDrawer extends ConsumerWidget {
  final String firstName;
  final String lastName;
  final VoidCallback onNavigateToFavorites;
  final VoidCallback onNavigateToDonationWatchList;

  const CustomDrawer({
    Key? key,
    required this.firstName,
    required this.lastName,
    required this.onNavigateToFavorites,
    required this.onNavigateToDonationWatchList, required Future<Null> Function() onSignOut,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isAuthenticated = ref.watch(authProvider).isAuthenticated;

      // Get the current location
  Future<Position> _getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

    // Using FutureProvider to fetch profile image
    final profileImageUrl = ref.watch(profileImageProvider(user?.uid ?? ''));
    final isUploading = ref.watch(isUploadingProvider.state).state;

    // Upload profile image
    Future<void> _uploadProfileImage(String uid, dynamic isUploadingProvider) async {
      if (user == null) return; // Ensure user is not null
      
      try {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);

        if (pickedFile == null) {
          debugPrint('No image selected.');
          return;
        }

        ref.read(isUploadingProvider.state).state = true;  // Start upload
        final storageRef = FirebaseStorage.instance.ref().child('user_profile_images/$uid.jpg');
        final uploadTask = storageRef.putFile(File(pickedFile.path));

        uploadTask.snapshotEvents.listen((taskSnapshot) {
          double progress = taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
          debugPrint('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
        });

        final snapshot = await uploadTask.whenComplete(() {});
        final downloadUrl = await snapshot.ref.getDownloadURL();

        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'profileImageUrl': downloadUrl,
        });

        ref.invalidate(profileImageProvider(user.uid));  // Refresh profile image URL
        ref.read(isUploadingProvider.state).state = false;  // End upload
        debugPrint('Profile image uploaded successfully!');
      } catch (e) {
        ref.read(isUploadingProvider.state).state = false;  // End upload on error
        debugPrint('Error uploading profile image: $e');
      }
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GestureDetector(
              onTap: () {
                if (user != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfilePage(userId: user.uid),
                    ),
                  );
                }
              },
              child: Row(
                children: [
                  GestureDetector(
                    onTap: user != null ? () => _uploadProfileImage(user.uid, isUploadingProvider) : null,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: profileImageUrl.when(
                            data: (url) => url != null && url.isNotEmpty
                                ? CachedNetworkImageProvider(url)
                                : const AssetImage('assets/default_avatar.png') as ImageProvider,
                            loading: () => const AssetImage('assets/default_avatar.png'),
                            error: (_, __) => const AssetImage('assets/default_avatar.png'),
                          ),
                          child: profileImageUrl.when(
                            data: (url) => url == null || url.isEmpty
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                            loading: () => const CircularProgressIndicator(),
                            error: (_, __) => const Icon(Icons.error, color: Colors.white),
                          ),
                        ),
                        if (isUploading)
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
                      if (user != null)
                        Text(
                          "${firstName} ${lastName}",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      const Text(
                        "My Profile",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal, color: Colors.green),
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
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupsPage(userId: user.uid),
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('History'),
            onTap: () {
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistoryPage(userId: user.uid),
                  ),
                );
              }
            },
          ),
          const Divider(indent: 16.0, endIndent: 16.0, color: Colors.grey),

          // Drawer List Items - Section 2
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('Recipe Favourites'),
            onTap: onNavigateToFavorites,
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
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyDonationsPage(userId: user.uid),
                  ),
                );
              }
            },
          ),
          const Divider(indent: 16.0, endIndent: 16.0, color: Colors.grey),

          // Drawer List Items - Section 4
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          const Divider(indent: 16.0, endIndent: 16.0, color: Colors.grey),

          // Drawer List Items - Logout Section
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log off'),
            onTap: () {
              ref.read(authProvider.notifier).signOut();  // Trigger sign out
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}
