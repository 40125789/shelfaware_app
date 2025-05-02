import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/utils/system_theme_observer_util.dart';

class SettingsState {
  final bool isDarkMode;
  final bool messagesNotifications;
  final bool requestNotifications;
  final bool expiryNotifications;
  final bool isSettingsLoaded;
  final bool isSystemMode;

  SettingsState({
    required this.isDarkMode,
    required this.messagesNotifications,
    required this.requestNotifications,
    required this.expiryNotifications,
    required this.isSettingsLoaded,
    required this.isSystemMode,
  });

  SettingsState copyWith({
    bool? isDarkMode,
    bool? messagesNotifications,
    bool? requestNotifications,
    bool? expiryNotifications,
    bool? isSettingsLoaded,
    bool? isSystemMode,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      messagesNotifications:
          messagesNotifications ?? this.messagesNotifications,
      requestNotifications: requestNotifications ?? this.requestNotifications,
      expiryNotifications: expiryNotifications ?? this.expiryNotifications,
      isSettingsLoaded: isSettingsLoaded ?? this.isSettingsLoaded,
      isSystemMode: isSystemMode ?? this.isSystemMode,
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
          isSystemMode: true, // Default to system theme
        )) {
    _loadSettings();
    _listenForSystemThemeChanges(); // Listen for system theme changes
  }

  // Load saved settings and detect the system theme
  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Load the previously saved theme setting (if available)
    bool isDarkMode = prefs.getBool('isDarkMode') ?? false;

    // Fetch system mode preference
    bool isSystemMode = prefs.getBool('isSystemMode') ?? true; // Default to system mode if not set

    // If no theme preference is saved, default to system theme
    if (prefs.getBool('isDarkMode') == null) {
      isDarkMode = _isSystemDarkMode();
      await prefs.setBool('isDarkMode', isDarkMode);
    }

    // Update state with the theme setting and system mode status
    state = state.copyWith(
      isDarkMode: isDarkMode,
      isSystemMode: isSystemMode,
      isSettingsLoaded: true,
    );
  }

  // Check if the system theme is dark mode
  bool _isSystemDarkMode() {
    return WidgetsBinding.instance!.window.platformBrightness == Brightness.dark;
  }

  // Listen for system theme changes and update the app theme accordingly
  void _listenForSystemThemeChanges() {
    WidgetsBinding.instance!.addObserver(SystemThemeObserver(
      onSystemThemeChanged: () {
        // If system mode is enabled, update the theme based on system's brightness
        if (state.isSystemMode ?? false) {
          bool systemDarkMode = _isSystemDarkMode();
          state = state.copyWith(isDarkMode: systemDarkMode);
        }
      },
    ));
  }

  // Toggle Dark Mode manually
  Future<void> toggleDarkMode(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);

    // Update the state with the new dark mode setting
    state = state.copyWith(isDarkMode: value, isSystemMode: false); // Disable system mode when dark mode is manually toggled
  }

  // Toggle the Use System Theme mode
  Future<void> toggleSystemMode(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSystemMode', value);

    // When system mode is turned on, reset dark mode to system setting
    if (value) {
      bool systemDarkMode = _isSystemDarkMode();
      await prefs.setBool('isDarkMode', systemDarkMode); // Sync with system theme
      state = state.copyWith(isDarkMode: systemDarkMode); // Update state to system theme
    }

    // Update the state with the new system mode setting
    state = state.copyWith(isSystemMode: value);
  }

  // Check and update the theme when system theme changes
  void checkSystemTheme() {
    if (state.isSystemMode ?? false) {
      bool systemDarkMode = _isSystemDarkMode();
      state = state.copyWith(isDarkMode: systemDarkMode);
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
