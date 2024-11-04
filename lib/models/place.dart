import 'package:google_maps_flutter/google_maps_flutter.dart';

class Place {
  final String name;
  final String address;
  final String placeId; // Add placeId property
  final LatLng location;
  List<String>? openingHours; // Add openingHours as a mutable property

  Place({
    required this.name,
    required this.address,
    required this.placeId, // Include placeId in constructor
    required this.location,
    this.openingHours,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      name: json['name'],
      address: json['vicinity'] ?? '', // Use 'vicinity' for address
      placeId: json['place_id'] ?? '', // Ensure placeId is included
      location: LatLng(json['geometry']['location']['lat'], json['geometry']['location']['lng']),
    );
  }
}
