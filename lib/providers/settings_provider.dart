import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:permission_handler/permission_handler.dart' as permission_handler;
import 'package:location/location.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;

  bool get isDarkMode => _isDarkMode;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get locationEnabled => _locationEnabled;

  SettingsProvider() {
    _loadSettings();
  }

  // Load saved settings from SharedPreferences
  _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    _locationEnabled = prefs.getBool('locationEnabled') ?? true;
    
    // If location is enabled, request permission, otherwise stop location tracking.
    if (_locationEnabled) {
      await _requestLocationPermission();
    } else {
      _stopLocationTracking();
    }

    notifyListeners();
  }

  // Toggle dark mode
  toggleDarkMode(bool value) async {
    _isDarkMode = value;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', value);
    notifyListeners();
  }

  // Toggle notifications
  toggleNotifications(bool value) async {
    _notificationsEnabled = value;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('notificationsEnabled', value);

    // Handle enabling/disabling notifications
    if (value) {
      _enableNotifications();
    } else {
      _disableNotifications();
    }

    notifyListeners();
  }

  // Toggle location access
  toggleLocation(bool value) async {
    _locationEnabled = value;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('locationEnabled', value);

    // Handle enabling/disabling location access
    if (value) {
      await _requestLocationPermission();
    } else {
      _stopLocationTracking(); // Disable location tracking when turned off
    }

    notifyListeners();
  }

  // Request location permission
  Future<void> _requestLocationPermission() async {
    permission_handler.PermissionStatus status = await permission_handler.Permission.location.request();
    if (status.isGranted) {
      print("Location permission granted.");
      // Start location tracking if necessary
    } else if (status.isDenied) {
      print("Location permission denied.");
    } else if (status.isPermanentlyDenied) {
      permission_handler.openAppSettings();
    }
  }

  // Stop location tracking
  Future<void> _stopLocationTracking() async {
    // Logic to stop location tracking (if using a plugin like geolocator or location)
    print("Location tracking stopped.");
    
    // If you're using geolocator:
    // Geolocator.stopLocationService();

    // If you're using a location service or a real-time location update, you should stop or unsubscribe here.
  }

  // Enable notifications (Example with flutter_local_notifications)
  void _enableNotifications() {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    var androidSettings = AndroidInitializationSettings('app_icon');
    var initializationSettings =
        InitializationSettings(android: androidSettings);

    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    print("Notifications enabled.");
  }

  // Disable notifications
  void _disableNotifications() {
    print("Notifications disabled.");
  }
}
