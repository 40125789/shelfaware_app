import 'package:badges/badges.dart' as custom_badge;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shelfaware_app/components/photo_upload.dart';
import 'package:shelfaware_app/pages/chat_list_page.dart';
import 'package:shelfaware_app/pages/history_page.dart';
import 'package:shelfaware_app/pages/shopping_list.dart';
import 'package:shelfaware_app/pages/watched_donations_page.dart';
import 'package:shelfaware_app/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/providers/unread_messages_provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
          // Add a green background to the profile section
          Container(
            color: const Color(0xFF4CAF50), // Green background color
            padding: const EdgeInsets.all(16.0),
            child: ProfileSection(
              firstName: firstName,
              lastName: lastName,
            ),
          ),
   

          // Drawer List Items - Section 1
    
  ListTile(
  leading: const Icon(Icons.shopping_cart),
  title: const Text('Shopping List'),
  onTap: () {
    if (user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ShoppingListScreen(),
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
                Position position =
                    await _getCurrentLocation(); // Get dynamic location
                LatLng currentLocation =
                    LatLng(position.latitude, position.longitude);

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
          Consumer(
            builder: (context, ref, child) {
              final unreadMessagesCount =
                  ref.watch(unreadMessagesCountProvider);

              return ListTile(
                leading: Stack(
                  clipBehavior: Clip.none, // Allows the badge to overflow
                  children: [
                    const Icon(Icons.message), // Message icon
                    Positioned(
                      top: -3,
                      right: -3,
                      child: unreadMessagesCount.when(
                        data: (count) => count > 0
                            ? custom_badge.Badge(
                                badgeContent: Text('$count'),
                                badgeColor: Colors.red,
                              )
                            : const SizedBox(),
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                      ),
                    ),
                  ],
                ),
                title: const Text('Messages'),
                onTap: () {
                  // Navigate to the chat list page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatListPage(),
                    ),
                  ).then((_) {
                    // When returning to the drawer, refresh the unread count again
                    ref.invalidate(unreadMessagesCountProvider);
                  });
                },
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
              await ref
                  .read(authProvider.notifier)
                  .signOut(); // Trigger sign out
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
       
          // Feedback Survey Link
          ListTile(
            title: ElevatedButton.icon(
              onPressed: () {
                // Navigate to the feedback survey link
                const url = 'https://forms.gle/TSAYJ6F6TVtGRSZx5';
                launchUrl(Uri.parse(url)).onError((error, stackTrace) {
                  print('Error launching URL: $error');
                  return false;
                });
              },
              icon: const Icon(Icons.feedback, color: Colors.white),
              label: const Text(
                'Feedback Survey',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Background color
              ),
            ),
          ),
        ],
      ),
    );
  }
}
