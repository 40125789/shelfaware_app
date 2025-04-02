import 'package:badges/badges.dart' as custom_badge;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shelfaware_app/components/profile_section.dart';
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Get the current location
    Future<Position> _getCurrentLocation() async {
      return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    }

    return Drawer(
      elevation: 16.0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [theme.colorScheme.surface, theme.scaffoldBackgroundColor]
                : [Colors.green.shade50, Colors.white],
          ),
        ),
        child: Column(
          children: <Widget>[
            // Header with profile section
            Container(
              padding: const EdgeInsets.only(top: 30.0, bottom: 20.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF388E3C), Color(0xFF4CAF50)], // Keep green in both modes
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6.0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ProfileSection(),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildMenuTile(
                      context: context,
                      icon: Icons.shopping_cart,
                      title: 'Shopping List',
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
                    
                    _buildMenuTile(
                      context: context,
                      icon: Icons.history,
                      title: 'History',
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

                    Divider(indent: 16.0, endIndent: 16.0, color: theme.dividerColor),

                    _buildMenuTile(
                      context: context,
                      icon: Icons.favorite,
                      title: 'Recipe Favourites',
                      onTap: onNavigateToFavorites,
                    ),
                    
                    _buildMenuTile(
                      context: context,
                      icon: Icons.star,
                      title: 'Donation WatchList',
                      onTap: () async {
                        final userId = FirebaseAuth.instance.currentUser!.uid;
                        try {
                          Position position = await _getCurrentLocation();
                          LatLng currentLocation = LatLng(position.latitude, position.longitude);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WatchedDonationsPage(
                                currentLocation: currentLocation,
                              ),
                            ),
                          );
                        } catch (e) {
                          print('Error getting location: $e');
                        }
                      },
                    ),

                    Divider(indent: 16.0, endIndent: 16.0, color: theme.dividerColor),

                    Consumer(
                      builder: (context, ref, child) {
                        final unreadMessagesCount = ref.watch(unreadMessagesCountProvider);
                        return _buildMenuTile(
                          context: context,
                          icon: Icons.message,
                          title: 'Messages',
                          badge: unreadMessagesCount.when(
                            data: (count) => count > 0 ? count : null,
                            loading: () => null,
                            error: (_, __) => null,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatListPage(),
                              ),
                            ).then((_) {
                              ref.invalidate(unreadMessagesCountProvider);
                            });
                          },
                        );
                      },
                    ),

                    _buildMenuTile(
                      context: context,
                      icon: Icons.food_bank,
                      title: 'Manage Donations',
                      onTap: () {
                        Navigator.pushNamed(context, '/myDonations');
                      },
                    ),

                    Divider(indent: 16.0, endIndent: 16.0, color: theme.dividerColor),

                    _buildMenuTile(
                      context: context,
                      icon: Icons.settings,
                      title: 'Settings',
                      onTap: () {
                        Navigator.pushNamed(context, '/settings');
                      },
                    ),

                    Divider(indent: 16.0, endIndent: 16.0, color: theme.dividerColor),

                    _buildMenuTile(
                      context: context,
                      icon: Icons.logout,
                      title: 'Log off',
                      textColor: theme.colorScheme.error,
                      onTap: () async {
                        await ref.read(authProvider.notifier).signOut();
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Improved Feedback Survey Button
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.green.shade600, Colors.green.shade800], // Keep green in both modes
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    const url = 'https://forms.gle/TSAYJ6F6TVtGRSZx5';
                    launchUrl(Uri.parse(url)).onError((error, stackTrace) {
                      print('Error launching URL: $error');
                      return false;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.rate_review,
                          color: Colors.white,
                          size: 22,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Help us improve!',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    int? badge,
    Color? textColor,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      child: ListTile(
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: Colors.green), // Keep icons green in both modes
            if (badge != null)
              Positioned(
                top: -5,
                right: -5,
                child: custom_badge.Badge(
                  badgeContent: Text(
                    '$badge',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  badgeColor: theme.colorScheme.error,
                ),
              ),
          ],
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: textColor ?? theme.textTheme.bodyLarge?.color,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        tileColor: Colors.transparent,
        hoverColor: isDarkMode 
            ? Colors.green.withOpacity(0.2) // Keep green hover in dark mode
            : Colors.green.shade100,
        dense: true,
      ),
    );
  }
}
