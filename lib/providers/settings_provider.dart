import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _locationEnabled = true;
  bool _messagesNotifications = true;
  bool _requestNotifications = true;
  bool _expiryNotifications = true;
  bool _isSettingsLoaded = false;

  bool get isDarkMode => _isDarkMode;
  bool get locationEnabled => _locationEnabled;
  bool get messagesNotifications => _messagesNotifications;
  bool get requestNotifications => _requestNotifications;
  bool get expiryNotifications => _expiryNotifications;
  bool get isSettingsLoaded => _isSettingsLoaded;

  // Constructor
  SettingsProvider() {
    _loadSettings();
  }

  // Load saved settings from SharedPreferences and Firestore
  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _locationEnabled = prefs.getBool('locationEnabled') ?? true;
    _messagesNotifications = prefs.getBool('messagesNotifications') ?? true;
    _requestNotifications = prefs.getBool('requestNotifications') ?? true;
    _expiryNotifications = prefs.getBool('expiryNotifications') ?? true;

    // Fetch user's notification preferences from Firestore
    await _fetchUserNotificationPreferences();

    _isSettingsLoaded = true;

    // Handle location permission
    if (_locationEnabled) {
      await _requestLocationPermission();
    } else {
      _stopLocationTracking();
    }

    notifyListeners();
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
          _messagesNotifications = preferences['messages'] ?? true;
          _requestNotifications = preferences['requests'] ?? true;
          _expiryNotifications = preferences['expiry'] ?? true;

          await _saveSetting('messagesNotifications', _messagesNotifications);
          await _saveSetting('requestNotifications', _requestNotifications);
          await _saveSetting('expiryNotifications', _expiryNotifications);
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
  void toggleDarkMode(bool value) async {
    _isDarkMode = value;
    await _saveSetting('isDarkMode', value);
    notifyListeners();
  }

  // Toggle Location
  void toggleLocation(bool value) async {
    _locationEnabled = value;
    await _saveSetting('locationEnabled', value);

    if (value) {
      await _requestLocationPermission();
    } else {
      _stopLocationTracking();
    }

    notifyListeners();
  }

  // Request location permission
  Future<void> _requestLocationPermission() async {
    // Implement permission handling logic
  }

  // Stop location tracking
  void _stopLocationTracking() {
    // Implement location stop logic
  }

  // Toggle Messages Notifications
  void toggleMessageNotifications(bool value) async {
    _messagesNotifications = value;
    await _saveSetting('messagesNotifications', value);
    await _updateUserNotificationPreferences();
    notifyListeners();
  }

  // Toggle Request Notifications
  void toggleRequestNotifications(bool value) async {
    _requestNotifications = value;
    await _saveSetting('requestNotifications', value);
    await _updateUserNotificationPreferences();
    notifyListeners();
  }

  // Toggle Expiry Notifications
  void toggleExpiryNotifications(bool value) async {
    _expiryNotifications = value;
    await _saveSetting('expiryNotifications', value);
    await _updateUserNotificationPreferences();
    notifyListeners();
  }

  // Update user notification preferences in Firestore
  Future<void> _updateUserNotificationPreferences() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (userId.isNotEmpty) {
      DocumentReference userRef =
          FirebaseFirestore.instance.collection('users').doc(userId);

      await userRef.update({
        'notificationPreferences': {
          'messages': _messagesNotifications,
          'requests': _requestNotifications,
          'expiry': _expiryNotifications,
        }
      }).catchError((e) {
        print('Error updating notification preferences: $e');
      });
    }
  }
}
