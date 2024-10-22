import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  final String firstName;
  final String lastName;
  final VoidCallback onSignOut;

  const CustomDrawer({
    Key? key,
    required this.firstName,
    required this.lastName,
    required this.onSignOut,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // Profile Picture Section without green header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30, // Profile picture size
                  backgroundImage: NetworkImage(
                    'https://via.placeholder.com/150', // Replace with actual profile picture URL
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$firstName $lastName",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      "View Profile",
                      style: TextStyle(fontSize: 14, color: Colors.blue),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(
            indent: 16, // Indentation for shorter divider
            endIndent: 16,
            color: Colors.grey,
          ),

          // List Items
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
            onTap: () {
              // Define action for Recipe Favourites
            },
          ),
          const Divider(
            indent: 16, // Indentation for shorter divider
            endIndent: 16,
            color: Colors.grey,
          ),
          ListTile(
            leading: const Icon(Icons.message),
            title: const Text('Messages'),
            onTap: () {
              // Define action for Messages
            },
          ),
          ListTile(
            leading: const Icon(Icons.food_bank),
            title: const Text('My Donation Listings'),
            onTap: () {
              // Define action for My Donation Listings
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              // Define action for Settings
            },
          ),
          const Divider(
            indent: 16, // Indentation for shorter divider
            endIndent: 16,
            color: Colors.grey,
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log off'),
            onTap: onSignOut,
          ),
        ],
      ),
    );
  }
}
