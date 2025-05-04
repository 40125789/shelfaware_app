import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/src/mock_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// This application utilizes the Mapbox Geocoding API for address search functionality.
/// Mapbox Geocoding API: https://docs.mapbox.com/api/search/geocoding/
/// © Mapbox, Inc. Used in accordance with Mapbox Terms of Service.
/// Terms: https://www.mapbox.com/legal/tos
/// Attribution is required according to Mapbox's terms of service.
///

class AddressSuggestionUtil {
  static Future<List<dynamic>> fetchAddressSuggestions(String query) async {
    if (query.isEmpty) {
      return [];
    }

    // Load the API key from .env
    String apiKey = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';

    if (apiKey.isEmpty) {
      throw Exception('Mapbox API key is missing');
    }

    var response = await http.get(
      Uri.parse(
        'https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json?access_token=$apiKey&limit=5',
      ),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return data['features'];
    } else {
      throw Exception('Error fetching address suggestions');
    }
  }
}
