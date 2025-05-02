import 'package:flutter/material.dart';
import 'package:shelfaware_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final isDarkMode = settingsState.isDarkMode;
    final isSystemMode = settingsState.isSystemMode ?? true; // Default to system theme if null

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Theme.of(context).appBarTheme.titleTextStyle?.color ?? Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: ListView(
          children: [
            // Theme Section
            _buildSectionHeader(context, 'Appearance'),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  // System Theme Toggle
                  _buildToggleRow(
                    title: 'Use System Theme',
                    value: isSystemMode,
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).toggleSystemMode(value);
                    },
                    icon: Icons.settings_system_daydream,
                    switchKey: 'system-theme-switch',
                  ),
                  const Divider(height: 1),
                  // Dark Mode Toggle
                  _buildToggleRow(
                    title: isDarkMode ? 'Dark Mode' : 'Light Mode',
                    value: isDarkMode,
                    onChanged: isSystemMode
                        ? null
                        : (value) {
                            ref.read(settingsProvider.notifier).toggleDarkMode(value);
                          },
                    icon: isDarkMode ? Icons.nightlight_round : Icons.sunny,
                    iconColor: isDarkMode ? Colors.yellow : Colors.orange,
                    opacity: isSystemMode ? 0.5 : 1.0,
                    switchKey: 'theme-switch',
                  ),
                ],
              ),
            ),

            // Notifications Section
            _buildSectionHeader(context, 'Notifications'),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  _buildToggleRow(
                    title: 'Messages',
                    value: settingsState.messagesNotifications,
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).toggleMessageNotifications(value);
                    },
                    switchKey: 'messages-switch',
                    statusKey: 'messages-status',
                  ),
                  const Divider(height: 1),
                  _buildToggleRow(
                    title: 'Donation Requests',
                    value: settingsState.requestNotifications,
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).toggleRequestNotifications(value);
                    },
                    switchKey: 'request-switch',
                    statusKey: 'request-status',
                  ),
                  const Divider(height: 1),
                  _buildToggleRow(
                    title: 'Expiry Alerts',
                    value: settingsState.expiryNotifications,
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).toggleExpiryNotifications(value);
                    },
                    switchKey: 'expiry-switch',
                    statusKey: 'expiry-status',
                  ),
                ],
              ),
            ),

            // Legal Section
            _buildSectionHeader(context, 'Legal'),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(bottom: 16),
              child: _buildActionRow(
                title: 'Privacy Policy',
                icon: Icons.privacy_tip,
                buttonText: 'View',
                onPressed: () async {
                  const url = 'https://sites.google.com/view/shelfawareprivacypolicy/home';
                  launchUrl(Uri.parse(url)).onError((error, stackTrace) {
                    print('Error launching URL: $error');
                    return false;
                  });
                },
              ),
            ),

            // Account Section
            _buildSectionHeader(context, 'Account'),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(bottom: 16),
              child: _buildActionRow(
                title: 'Delete Account',
                icon: Icons.delete_forever,
                buttonText: 'Delete',
                buttonColor: Colors.red,
                onPressed: () async {
                  const url = 'https://forms.gle/nvpqjxhzsYJTNpUC7';
                  launchUrl(Uri.parse(url)).onError((error, stackTrace) {
                    print('Error launching URL: $error');
                    return false;
                  });
                },
              ),
            ),

            // Credits Section
            _buildSectionHeader(context, 'Powered By'),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  _buildPartnerRow(
                    logoAsset: 'assets/open_food_facts_logo.png',
                    onPressed: () async {
                      const url = 'https://world.openfoodfacts.org/';
                      launchUrl(Uri.parse(url)).onError((error, stackTrace) {
                        print('Error launching URL: $error');
                        return false;
                      });
                    },
                  ),
                  const Divider(height: 1),
                  _buildPartnerRow(
                    logoAsset: 'assets/spoonacular_logo.png',
                    onPressed: () async {
                      const url = 'https://spoonacular.com/food-api';
                      launchUrl(Uri.parse(url)).onError((error, stackTrace) {
                        print('Error launching URL: $error');
                        return false;
                      });
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8, top: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required bool value,
    required Function(bool)? onChanged,
    IconData? icon,
    Color? iconColor,
    double opacity = 1.0,
    required String switchKey,
    String? statusKey,
  }) {
    return Opacity(
      opacity: opacity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            if (icon != null) 
              Icon(icon, color: iconColor, size: 24),
            if (icon != null)
              const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
            if (statusKey != null)
              Text(
                value ? 'ON' : 'OFF',
                key: Key(statusKey),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: value ? Colors.green : Colors.red,
                ),
              ),
            const SizedBox(width: 8),
            Switch(
              key: Key(switchKey),
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow({
    required String title,
    required IconData icon,
    required String buttonText,
    required VoidCallback onPressed,
    Color? buttonColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ),
          TextButton(
            onPressed: onPressed,
            child: Text(
              buttonText,
              style: TextStyle(
                color: buttonColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerRow({
    required String logoAsset,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 50,
            child: Image.asset(
              logoAsset,
              fit: BoxFit.contain,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onPressed,
            child: const Text(
              'Learn More',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
// }

