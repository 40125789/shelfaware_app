import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shelfaware_app/components/favourite_button_widget.dart';
import 'package:shelfaware_app/components/recipe_card.dart';
import 'package:shelfaware_app/models/recipe_model.dart';
import 'package:shelfaware_app/services/firebase_service.dart';
import 'package:shelfaware_app/services/recipe_service.dart';
import 'package:shelfaware_app/pages/recipe_details_page.dart';

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
    // Fetch expiring ingredients and then fetch recipes
    recipesFuture = _fetchRecipes();
  }

  Future<List<Recipe>> _fetchRecipes() async {
    // Fetch user ingredients that are close to expiry (replace with your actual method to fetch ingredients)
    userIngredients = await fetchUserIngredients(); // Replace this with actual method

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


