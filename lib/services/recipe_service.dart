import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RecipeService {
  final String appId = dotenv.env['EDAMAM_APP_ID'] ?? '';
  final String appKey = dotenv.env['EDAMAM_APP_KEY'] ?? '';

  Future<List<Map<String, dynamic>>> fetchRecipes(
      List<String> ingredients) async {
    // Join ingredients with commas for the API query
    String query = ingredients.join(',');

    final url = Uri.parse(
        'https://api.edamam.com/search?q=$query&app_id=$appId&app_key=$appKey');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['hits'] as List).map<Map<String, dynamic>>((hit) {
        final recipe = hit['recipe'];
        return {
          'label': recipe['label'],
          'image': recipe['image'],
          'ingredients': recipe['ingredients']
              .map<String>((ingredient) => ingredient['text'] as String)
              .toList(),
          'source': recipe['source'],
        };
      }).toList();
    } else {
      throw Exception('Failed to load recipes');
    }
  }
}
