import 'package:flutter/material.dart';
import 'package:shelfaware_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';


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
                      isDarkMode ? Icons.nightlight_round : Icons.sunny,
                      color: isDarkMode ? Colors.yellow : Colors.orange,
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          settingsState.messagesNotifications ? 'ON' : 'OFF',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Switch(
                          value: settingsState.messagesNotifications,
                          onChanged: (value) {
                            ref.read(settingsProvider.notifier).toggleMessageNotifications(value);
                          },
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    title: const Text('Donation Requests'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          settingsState.requestNotifications ? 'ON' : 'OFF',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Switch(
                          value: settingsState.requestNotifications,
                          onChanged: (value) {
                            ref.read(settingsProvider.notifier).toggleRequestNotifications(value);
                          },
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    title: const Text('Expiry Alerts'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          settingsState.expiryNotifications ? 'ON' : 'OFF',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Switch(
                          value: settingsState.expiryNotifications,
                          onChanged: (value) {
                            ref.read(settingsProvider.notifier).toggleExpiryNotifications(value);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Other Section
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('App powered by:'),
                  ),
                  const Divider(),
                  ListTile(
                    title: Row(
                      children: [
                        SizedBox(
                          width: 100,
                          height: 50,
                          child: Image.asset(
                            'assets/open_food_facts_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        Spacer(),
                        TextButton(
                          onPressed: () async {
                            const url = 'https://world.openfoodfacts.org/';
                            launchUrl(Uri.parse(url)).onError((error, stackTrace) {
                              print('Error launching URL: $error');
                              return false;
                            });
                          },
                          child: const Text('Learn More'),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    title: Row(
                      children: [
                        SizedBox(
                          width: 100,
                          height: 50,
                          child: Image.asset(
                            'assets/spoonacular_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        Spacer(),
                        TextButton(
                          onPressed: () async {
                            const url = 'https://spoonacular.com/food-api';
                            launchUrl(Uri.parse(url)).onError((error, stackTrace) {
                              print('Error launching URL: $error');
                              return false;
                            });
                          },
                          child: const Text('Learn More'),
                        ),
                      ],
                    ),
                  ),
                ],
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