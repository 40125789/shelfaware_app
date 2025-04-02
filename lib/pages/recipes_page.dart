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

class _RecipesPageState extends State<RecipesPage> with SingleTickerProviderStateMixin {
  late Future<List<Recipe>> recipesFuture;
  List<String> userIngredients = [];  // Store user's ingredients
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Set up animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    // Fetch recipes based on ingredients fetched from Firebase
    recipesFuture = _fetchRecipes();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<List<Recipe>> _fetchRecipes() async {
    // Fetch user ingredients using FirebaseService
    userIngredients = await FoodService().fetchUserIngredients();

    if (userIngredients.isNotEmpty) {
      // If ingredients are available, fetch recipes based on those ingredients
      final recipes = await RecipeService().fetchRecipes(userIngredients);
      _animationController.forward();
      return recipes;
    } else {
      _animationController.forward();
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

          return FadeTransition(
            opacity: _animation,
            child: ListView.builder(
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                return AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(1, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _animationController,
                        curve: Interval(
                          index / recipes.length * 0.6,
                          (index + 1) / recipes.length * 0.6 + 0.4,
                          curve: Curves.easeOutQuad,
                        ),
                      )),
                      child: child,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    child: RecipeCard(
                      recipe: recipes[index],
                      userIngredients: userIngredients, favouritesRepository: FavouritesRepository(), 
                    ),
                  ),
                );
              },
            ),
          );
        } else {
          return FadeTransition(
            opacity: _animation,
            child: Center(
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
            ),
          );
        }
      },
    );
  }
}




