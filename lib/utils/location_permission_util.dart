import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationPermissionUtil {
  static Future<bool> requestLocationPermission(BuildContext context) async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
    }
    if (!status.isGranted) {
      _showPermissionAlert(context);
      return false;
    }
    return true;
  }

  static void _showPermissionAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Location Permission Required"),
        content: Text("This app needs location access to show nearby donation points. Please enable location permissions in settings."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: Text("Go to Settings"),
          ),
        ],
      ),
    );
  }
}