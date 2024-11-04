import 'package:google_maps_flutter/google_maps_flutter.dart';

class PlaceDetails {
  final String formattedAddress;
  final String? phoneNumber;
  final String? website;
  final List<String>? openingHours;
  final double rating; // Average rating of the place
  final int userRatingsTotal; // Total number of ratings
  final List<String>? photos; // List of photo references, if available

  PlaceDetails({
    required this.formattedAddress,
    this.phoneNumber,
    this.website,
    this.openingHours,
    required this.rating,
    required this.userRatingsTotal,
    this.photos,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    return PlaceDetails(
      formattedAddress: json['formatted_address'] ?? 'No address available',
      phoneNumber: json['formatted_phone_number'],
      website: json['website'],
      openingHours: (json['opening_hours']?['weekday_text'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      userRatingsTotal: json['user_ratings_total'] ?? 0,
      photos: (json['photos'] as List<dynamic>?)
          ?.map((photo) => photo['photo_reference']?.toString())
          .whereType<String>()
          .toList(),
    );
  }

  @override
  String toString() {
    return 'PlaceDetails(formattedAddress: $formattedAddress, phoneNumber: $phoneNumber, website: $website, openingHours: $openingHours, rating: $rating, userRatingsTotal: $userRatingsTotal, photos: $photos)';
  }
}
