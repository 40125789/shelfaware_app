import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shelfaware_app/models/place_model.dart';
import 'package:shelfaware_app/models/place_details.dart';

class PlacesService {
  final String apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  PlacesService();

  Future<List<Place>> getNearbyFoodBanks(LatLng location) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=${location.latitude},${location.longitude}'
      '&radius=10000'
      '&keyword=food%20bank'
      '&key=$apiKey',
    );

    final response = await http.get(url);
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['results'] != null) {
        List<Place> places = (data['results'] as List).map((result) {
          final geometry = result['geometry']['location'];
          return Place(
            name: result['name'],
            address: result['vicinity'] ?? '',
            placeId: result['place_id'] ?? '',
            location: LatLng(geometry['lat'], geometry['lng']),
          );
        }).toList();

        // Fetch additional details for each place
        for (var place in places) {
          try {
            final details = await getPlaceDetails(place.placeId);
            if (details != null) {
              place.openingHours = details.openingHours?.map((hour) {
                return hour.replaceAll(RegExp(r'^\d{1,2}:\d{2} '), '');
              }).toList();
            }
          } catch (e) {
            print('Error fetching details for ${place.name}: $e');
          }
        }
        return places;
      } else {
        throw Exception('No results found');
      }
    } else {
      throw Exception(
          'Failed to load food banks. Status code: ${response.statusCode}');
    }
  }

  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=$placeId'
      '&fields=formatted_address,formatted_phone_number,website,opening_hours,rating,user_ratings_total,photos'
      '&key=$apiKey',
    );

    final response = await http.get(url);
    print('Place Details Response status: ${response.statusCode}');
    print('Place Details Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        return PlaceDetails.fromJson(data['result']);
      } else {
        throw Exception('No details found');
      }
    } else {
      throw Exception(
          'Failed to load place details. Status code: ${response.statusCode}');
    }
  }
}