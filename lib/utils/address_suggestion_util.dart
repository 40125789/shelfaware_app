import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/src/mock_client.dart';

class AddressSuggestionUtil {
 

  static Future<List<dynamic>> fetchAddressSuggestions(String query) async {
    if (query.isEmpty) {
      return [];
    }

    var response = await http.get(
      Uri.parse(
        'https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json?access_token=pk.eyJ1Ijoic215dGg2NjgiLCJhIjoiY200MDdncmZtMjhuZDJsczdoY2V1bnRneiJ9.LDb-l-_uzNOgzmqgFYMDjQ&limit=5',
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