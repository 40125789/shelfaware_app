import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:shelfaware_app/components/drawer_list_item.dart';
import 'package:shelfaware_app/components/photo_upload.dart';

import 'package:shelfaware_app/pages/chat_list_page.dart';
import 'package:shelfaware_app/pages/groups_page.dart';
import 'package:shelfaware_app/pages/history_page.dart';
import 'package:shelfaware_app/pages/my_donations_page.dart';
import 'package:shelfaware_app/pages/my_profile.dart';

import 'package:shelfaware_app/pages/watched_donations_page.dart';
import 'package:shelfaware_app/providers/auth_provider.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shelfaware_app/providers/profile_image_provider.dart';


import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/pages/chat_list_page.dart';
import 'package:shelfaware_app/pages/groups_page.dart';
import 'package:shelfaware_app/pages/history_page.dart';
import 'package:shelfaware_app/pages/my_donations_page.dart';
import 'package:shelfaware_app/pages/my_profile.dart';
import 'package:shelfaware_app/pages/watched_donations_page.dart';
import 'package:shelfaware_app/providers/auth_provider.dart';
import 'package:shelfaware_app/providers/profile_image_provider.dart';
import 'package:shelfaware_app/providers/unread_messages_provider.dart';
import 'package:shelfaware_app/components/photo_upload.dart';

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
    required this.onNavigateToDonationWatchList,
    required Future<Null> Function() onSignOut,
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

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ProfileSection(
              firstName: firstName,
              lastName: lastName,
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
  leading: Stack(
    clipBehavior: Clip.none, // Allows the badge to overflow
    children: [
      const Icon(Icons.message), // Message icon
      Positioned(
        top: -3,
        right: -3,
        child: user != null
            ? ref.watch(unreadMessagesCountProvider).when(
                data: (unreadCount) => unreadCount > 0
                    ? Badge(
                        label: Text('$unreadCount'),
                        backgroundColor: Colors.red,
                      )
                    : const SizedBox(),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              )
            : const SizedBox(),
      ),
    ],
  ),
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
              Navigator.pushNamed(context, '/myDonations');
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
            onTap: () async {
              await ref.read(authProvider.notifier).signOut();  // Trigger sign out
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}