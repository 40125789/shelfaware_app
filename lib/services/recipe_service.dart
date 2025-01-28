import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shelfaware_app/models/recipe_model.dart';

class RecipeService {
  final Map<String, Recipe> _recipeCache = {}; // Simple in-memory cache

  // Fetch basic recipe details based on ingredients
  Future<List<Recipe>> fetchRecipes(List<String> ingredients) async {
    String apiKey = dotenv.env['SPOONACULAR_API_KEY'] ?? '';

    if (apiKey.isEmpty) {
      throw Exception('API key is missing!');
    }

    String query = ingredients.join(',');
    String cacheKey = 'recipes_$query';  // Use ingredients as a unique cache key

    // Check if the recipes are cached
    if (_recipeCache.containsKey(cacheKey)) {
      print('Fetching from cache...');
      return [_recipeCache[cacheKey]!]; // Return cached data
    }

    String url =
        'https://api.spoonacular.com/recipes/findByIngredients?ingredients=$query&sort=min-missing-ingredients&number=5&ranking=1&ignorePantry=true&fillIngredients=true&addRecipeInformation=true&addRecipeNutrition=true&addRecipeEquipment=true&addRecipeSteps=true&instructionsRequired=true&includeNutrition=true&apiKey=$apiKey';

    print('Request URL: $url'); // Debug: Print URL to check the parameters

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        print('API Response: $data'); // Debug: Print the response data

        // Check if the data contains a list of recipes
        if (data is List && data.isNotEmpty) {
          // Collect recipe IDs for bulk fetching
          List<int> recipeIds = data.map<int>((item) => item['id'] as int).toList();

          // Fetch recipe details in parallel for the collected recipe IDs
          List<Recipe> recipes = await _fetchRecipesInBulk(recipeIds, apiKey);

          // Cache the result to avoid future API calls
          _recipeCache[cacheKey] = recipes[0];  // Cache the first recipe as an example

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

  // Bulk fetch detailed recipe information using recipe IDs
  Future<List<Recipe>> _fetchRecipesInBulk(List<int> recipeIds, String apiKey) async {
    List<Recipe> recipes = [];
    // Fetch multiple recipes in parallel
    try {
      // Create a list of Future objects for all API calls
      List<Future<Recipe>> futureRecipes = recipeIds.map((recipeId) {
        return _fetchRecipeDetails(recipeId, apiKey);
      }).toList();

      // Wait for all the Futures to complete
      recipes = await Future.wait(futureRecipes);
    } catch (e) {
      print('Error fetching bulk recipes: $e');
      rethrow;
    }
    return recipes;
  }

  // Fetch detailed recipe information using recipeId
  Future<Recipe> _fetchRecipeDetails(int recipeId, String apiKey) async {
    String url = 'https://api.spoonacular.com/recipes/$recipeId/information?&apiKey=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        print('Detailed Recipe Response: $data');  // Debug: Print the full response

        // Extract and log the instructions and other details
        if (data != null) {
          String instructions = data['instructions'] ?? 'No instructions available';
          String title = data['title'] ?? 'No title';
          List ingredients = data['extendedIngredients'] ?? [];

          // Convert the ingredients into Ingredient objects
          List<Ingredient> ingredientList = ingredients.map((ingredient) {
            return Ingredient(
              name: ingredient['name'],
              amount: ingredient['amount'] ?? 0.0,
              unit: ingredient['unit'] ?? '',
            );
          }).toList();

          // Return the detailed recipe object with instructions and ingredients
          return Recipe(
            id: data['id'],
            title: title,
            imageUrl: data['image'] ?? '',
            ingredients: ingredientList,
            sourceUrl: data['sourceUrl'] ?? '',
            summary: data['summary'] ?? 'No summary available.',
            instructions: instructions,  // Pass instructions to the Recipe model
          );
        } else {
          print('No detailed recipe data available');
          throw Exception('Failed to fetch detailed recipe');
        }
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load recipe details');
      }
    } catch (e) {
      print('Error fetching recipe details: $e');
      rethrow;
    }
  }
}
