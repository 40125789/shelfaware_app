import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shelfaware_app/models/recipe_model.dart';

class RecipeService {
  final Map<String, List<Recipe>> _recipeCache = {}; // Cache for recipes

  Future<List<Recipe>> fetchRecipes(List<String> ingredients) async {
    String apiKey = dotenv.env['SPOONACULAR_API_KEY'] ?? '';

    if (apiKey.isEmpty) {
      throw Exception('API key is missing!');
    }

    String query = ingredients.join(',');
    String cacheKey = 'recipes_$query';

    if (_recipeCache.containsKey(cacheKey)) {
      print('Fetching from cache...');
      return _recipeCache[cacheKey]!;
    }

    String url =
        'https://api.spoonacular.com/recipes/findByIngredients?ingredients=$query'
        '&sort=min-missing-ingredients&number=4&ranking=1&ignorePantry=true'
        '&apiKey=$apiKey';

    print('Fetching recipes from: $url');

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        if (data is List && data.isNotEmpty) {
          List<int> recipeIds =
              data.map<int>((item) => item['id'] as int).toList();

          List<Recipe> recipes = await _fetchRecipesInBulk(recipeIds, apiKey);

          _recipeCache[cacheKey] = recipes;
          return recipes;
        } else {
          print('No recipes found for these ingredients.');
          return [];
        }
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load recipes');
      }
    } catch (e) {
      print('Error fetching recipes: $e');
      return [];
    }
  }

  Future<List<Recipe>> _fetchRecipesInBulk(
      List<int> recipeIds, String apiKey) async {
    String idsQuery = recipeIds.join(',');
    String url =
        'https://api.spoonacular.com/recipes/informationBulk?ids=$idsQuery&apiKey=$apiKey';

    print('Fetching bulk recipe details from: $url');

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        return data.map<Recipe>((recipe) {
          List<Ingredient> ingredients =
              (recipe['extendedIngredients'] as List<dynamic>?)
                      ?.map((ing) => Ingredient(
                            name: ing['name'] ?? 'Unknown',
                            amount: ing['amount'] ?? 0.0,
                            unit: ing['unit'] ?? '',
                          ))
                      .toList() ??
                  [];

          return Recipe(
            id: recipe['id'],
            title: recipe['title'] ?? 'No title',
            imageUrl: recipe['image'] ?? '',
            ingredients: ingredients, // Ensure ingredients are set here
            sourceUrl: recipe['sourceUrl'] ?? '',
            summary: recipe['summary'] ?? 'No summary available.',
            instructions: recipe['instructions'] ?? 'No instructions available',
          );
        }).toList();
      } else {
        throw Exception('Failed to fetch bulk recipes: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching bulk recipes: $e');
      return [];
    }
  }
}
