import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shelfaware_app/providers/settings_provider.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final settingsProvider = Provider.of<SettingsProvider>(context);
        bool isDarkMode = settingsProvider.isDarkMode;

        // Set the color based on the current theme mode
        Color appBarColor = isDarkMode ? Colors.black : Colors.green;
        Color buttonColor = isDarkMode ? Colors.grey[800]! : Colors.green;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
            backgroundColor: appBarColor, // Green for light mode, black for dark mode
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                // Theme Section (in the same card as Dark Mode)
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      // Theme Header
                      ListTile(
                        leading: const Icon(Icons.palette),
                        title: const Text(
                          'Theme',
                          style: TextStyle(
                         
                         
                          ),
                        ),
                      ),
                      const Divider(), // Adds a visual separator
                      
                      // Dark Mode Toggle
                      ListTile(
                        leading: Icon(
                          settingsProvider.isDarkMode
                              ? Icons.nightlight_round
                              : Icons.sunny,
                          color: settingsProvider.isDarkMode
                              ? Colors.yellow
                              : Colors.orange,
                        ),
                        title: Text(
                          settingsProvider.isDarkMode ? 'Dark Mode' : 'Light Mode',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        trailing: Switch(
                          value: settingsProvider.isDarkMode,
                          onChanged: (value) {
                            settingsProvider.toggleDarkMode(value);
                          },
                       
                        ),
                      ),
                    ],
                  ),
                ),

                // Notifications Section
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.notifications),
                        title: const Text('Notification Preferences'),
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('Messages'),
                        trailing: Switch(
                          value: settingsProvider.messagesNotifications,
                          onChanged: (value) {
                            settingsProvider.toggleMessageNotifications(value);
                          },
                        ),
                      ),
                      ListTile(
                        title: const Text('Donation Requests'),
                        trailing: Switch(
                          value: settingsProvider.requestNotifications,
                          onChanged: (value) {
                            settingsProvider.toggleRequestNotifications(value);
                          },
                        ),
                      ),
                      ListTile(
                        title: const Text('Expiry Alerts'),
                        trailing: Switch(
                          value: settingsProvider.expiryNotifications,
                          onChanged: (value) {
                            settingsProvider.toggleExpiryNotifications(value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Location Section
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(
                      settingsProvider.locationEnabled
                          ? 'Location ON'
                          : 'Location OFF',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    trailing: Switch(
                      value: settingsProvider.locationEnabled,
                      onChanged: (value) {
                        settingsProvider.toggleLocation(value);
                      },
                    ),
                  ),
                ),

                // Optional: Show a message when location is off
                if (!settingsProvider.locationEnabled)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Location is disabled. You will not have access to location-based features.",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Save Settings Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50), // Full-width button
                    backgroundColor: buttonColor, // Green for light mode
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Settings saved")),
                    );
                  },
                  child: const Text(
                    "Save Settings",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


