
import 'package:flutter/material.dart';
import 'package:shelfaware_app/components/recipe_card.dart';
import 'package:shelfaware_app/models/recipe_model.dart';
import 'package:shelfaware_app/services/firebase_service.dart';
import 'package:shelfaware_app/services/recipe_service.dart';


class RecipesPage extends StatefulWidget {
  @override
  _RecipesPageState createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  late Future<List<Recipe>> recipesFuture;
  List<String> userIngredients = [];  // Store user's ingredients

  @override
  void initState() {
    super.initState();
    // Fetch recipes based on ingredients fetched from Firebase
    recipesFuture = _fetchRecipes();
  }

  Future<List<Recipe>> _fetchRecipes() async {
    // Fetch user ingredients using FirebaseService
    userIngredients = await FirebaseService().fetchUserIngredients();

    if (userIngredients.isNotEmpty) {
      // If ingredients are available, fetch recipes based on those ingredients
      return await RecipeService().fetchRecipes(userIngredients);
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Recipe>>(
      future: recipesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          List<Recipe> recipes = snapshot.data!;

          return ListView.builder(
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                child: RecipeCard(
                  recipe: recipes[index],
                  userIngredients: userIngredients, 
                ),
              );
            },
          );
        } else {
          return Center(child: Text("No recipes found."));
        }
      },
    );
  }
}


