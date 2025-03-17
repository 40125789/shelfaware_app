import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shelfaware_app/components/recipe_card.dart';
import 'package:shelfaware_app/models/recipe_model.dart';
import 'package:shelfaware_app/repositories/favourites_repository.dart';
import 'package:shelfaware_app/services/food_service.dart';
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
    userIngredients = await FoodService().fetchUserIngredients();

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
                  userIngredients: userIngredients, favouritesRepository: FavouritesRepository(), 
                ),
              );
            },
          );
            } else {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      child: Lottie.network('https://lottie.host/60243a93-e8c7-43e3-9851-9e0cfd6d6036/lASmWT1IPT.json'),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "No recipes found!",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Add food items to see them here",
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              );
            }
          },
        );
      }
    }




