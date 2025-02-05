import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shelfaware_app/main.dart';
import 'package:shelfaware_app/providers/settings_provider.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shelfaware_app/providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';



class SettingsPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    bool isDarkMode = settingsState.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
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
                  ListTile(
                    leading: const Icon(Icons.palette),
                    title: const Text('Theme'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      isDarkMode
                          ? Icons.nightlight_round
                          : Icons.sunny,
                      color: isDarkMode
                          ? Colors.yellow
                          : Colors.orange,
                    ),
                    title: Text(
                      isDarkMode ? 'Dark Mode' : 'Light Mode',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    trailing: Switch(
                      value: isDarkMode,
                      onChanged: (bool value) {
                        ref.read(settingsProvider.notifier).toggleDarkMode(value);
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
                      value: settingsState.messagesNotifications,
                      onChanged: (value) {
                        ref.read(settingsProvider.notifier).toggleMessageNotifications(value);
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text('Donation Requests'),
                    trailing: Switch(
                      value: settingsState.requestNotifications,
                      onChanged: (value) {
                        ref.read(settingsProvider.notifier).toggleRequestNotifications(value);
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text('Expiry Alerts'),
                    trailing: Switch(
                      value: settingsState.expiryNotifications,
                      onChanged: (value) {
                        ref.read(settingsProvider.notifier).toggleExpiryNotifications(value);
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
                  settingsState.locationEnabled ? 'Location ON' : 'Location OFF',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                trailing: Switch(
                  value: settingsState.locationEnabled,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).toggleLocation(value);
                  },
                ),
              ),
            ),
            if (!settingsState.locationEnabled)
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
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
  }
}
