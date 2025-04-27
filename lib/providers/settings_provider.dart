import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsState {
  final bool isDarkMode;
  final bool messagesNotifications;
  final bool requestNotifications;
  final bool expiryNotifications;
  final bool isSettingsLoaded;

  SettingsState({
    required this.isDarkMode,
    required this.messagesNotifications,
    required this.requestNotifications,
    required this.expiryNotifications,
    required this.isSettingsLoaded,
  });

  SettingsState copyWith({
    bool? isDarkMode,

    bool? messagesNotifications,
    bool? requestNotifications,
    bool? expiryNotifications,
    bool? isSettingsLoaded,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
   
      messagesNotifications:
          messagesNotifications ?? this.messagesNotifications,
      requestNotifications: requestNotifications ?? this.requestNotifications,
      expiryNotifications: expiryNotifications ?? this.expiryNotifications,
      isSettingsLoaded: isSettingsLoaded ?? this.isSettingsLoaded,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier()
      : super(SettingsState(
          isDarkMode: false,
          messagesNotifications: true,
          requestNotifications: true,
          expiryNotifications: true,
          isSettingsLoaded: false,
        )) {
    _loadSettings();
  }

  // Load saved settings from SharedPreferences and Firestore
  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isDarkMode = prefs.getBool('isDarkMode') ?? false;
    bool messagesNotifications = prefs.getBool('messagesNotifications') ?? true;
    bool requestNotifications = prefs.getBool('requestNotifications') ?? true;
    bool expiryNotifications = prefs.getBool('expiryNotifications') ?? true;

    // Fetch user's notification preferences from Firestore
    await _fetchUserNotificationPreferences();

    // Update state
    state = state.copyWith(
      isDarkMode: isDarkMode,
      messagesNotifications: messagesNotifications,
      requestNotifications: requestNotifications,
      expiryNotifications: expiryNotifications,
      isSettingsLoaded: true,
    );

    // Toggle dark mode setting and save to SharedPreferences
    Future<void> toggleDarkMode(bool value) async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', value);

      // Update the state with the new dark mode setting
      state = state.copyWith(isDarkMode: value);
    }
  }

  // Fetch user notification preferences from Firestore
  Future<void> _fetchUserNotificationPreferences() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (userId.isNotEmpty) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        var preferences = (userDoc.data()
            as Map<String, dynamic>?)?['notificationPreferences'];

        if (preferences == null) {
          await _createNotificationPreferences(userId);
        } else {
          state = state.copyWith(
            messagesNotifications: preferences['messages'] ?? true,
            requestNotifications: preferences['requests'] ?? true,
            expiryNotifications: preferences['expiry'] ?? true,
          );
          await _saveSetting(
              'messagesNotifications', state.messagesNotifications);
          await _saveSetting(
              'requestNotifications', state.requestNotifications);
          await _saveSetting('expiryNotifications', state.expiryNotifications);
        }
      }
    }
  }

  Future<void> _createNotificationPreferences(String userId) async {
    DocumentReference userRef =
        FirebaseFirestore.instance.collection('users').doc(userId);

    await userRef.update({
      'notificationPreferences': {
        'messages': true,
        'requests': true,
        'expiry': true,
      }
    }).catchError((e) {
      print('Error creating notification preferences: $e');
    });

    await _saveSetting('messagesNotifications', true);
    await _saveSetting('requestNotifications', true);
    await _saveSetting('expiryNotifications', true);
  }

  Future<void> _saveSetting(String key, bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  // Toggle Dark Mode
  void toggleDarkMode(bool isDarkMode) async {
    state = state.copyWith(isDarkMode: isDarkMode);
    await _saveSetting('isDarkMode', isDarkMode);
  }

  // Toggle Messages Notifications
  void toggleMessageNotifications(bool value) async {
    state = state.copyWith(messagesNotifications: value);
    await _saveSetting('messagesNotifications', value);
    await _updateUserNotificationPreferences();
  }

  // Toggle Request Notifications
  void toggleRequestNotifications(bool value) async {
    state = state.copyWith(requestNotifications: value);
    await _saveSetting('requestNotifications', value);
    await _updateUserNotificationPreferences();
  }

  // Toggle Expiry Notifications
  void toggleExpiryNotifications(bool value) async {
    state = state.copyWith(expiryNotifications: value);
    await _saveSetting('expiryNotifications', value);
    await _updateUserNotificationPreferences();
  }

  // Update user notification preferences in Firestore
  Future<void> _updateUserNotificationPreferences() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (userId.isNotEmpty) {
      DocumentReference userRef =
          FirebaseFirestore.instance.collection('users').doc(userId);

      await userRef.update({
        'notificationPreferences': {
          'messages': state.messagesNotifications,
          'requests': state.requestNotifications,
          'expiry': state.expiryNotifications,
        }
      }).catchError((e) {
        print('Error updating notification preferences: $e');
      });
    }
  }
}
