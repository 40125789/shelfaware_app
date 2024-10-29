// This file contains the LocationService class which is responsible for getting the current location of the user.
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<PermissionStatus> requestLocationPermission() async {
    return await Permission.locationWhenInUse.request();
  }

  Future<Position> getCurrentLocation() async {
    final permission = await requestLocationPermission();
    if (permission == PermissionStatus.granted) {
      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } else {
      throw Exception('Location permissions are denied');
    }
  }
}