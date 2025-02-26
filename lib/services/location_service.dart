// This file contains the LocationService class which is responsible for getting the current location of the user.
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  // Requests location permission from the user
  Future<PermissionStatus> requestLocationPermission() async {
    PermissionStatus status = await Permission.locationWhenInUse.status;

    // Check if permission is denied or restricted, and request if needed
    if (status != PermissionStatus.granted) {
      status = await Permission.locationWhenInUse.request();
    }

    return status;
  }

  // Checks if location service (GPS) is enabled on the device
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Retrieves the current location of the user
  Future<Position> getCurrentLocation() async {
    final permission = await requestLocationPermission();

    if (permission == PermissionStatus.granted) {
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable them.');
      }
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
    } else if (permission == PermissionStatus.permanentlyDenied) {
      throw Exception('Location permissions are permanently denied. Please enable them in settings.');
    } else {
      throw Exception('Location permissions are denied.');
    }
  }

  // Opens app settings if permissions are denied permanently
  Future<void> openAppSettings() async {
    await openAppSettings();
  }

  static Future<Position> getUserLocation() async {
    LocationPermission permission;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  
}
