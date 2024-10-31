import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shelfaware_app/services/recipe_service.dart';

class RecipesPage extends StatelessWidget {
  final RecipeService recipeService = RecipeService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    // Get the current user
    User? user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Recipes')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('foodItems')
            .where('userId', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching food items'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No food items found'));
          }

          // Extract user food items from Firestore
          List<String> userFoodItems = snapshot.data!.docs
              .map((doc) => doc['productName'] as String)
              .toList();

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: recipeService.fetchRecipes(userFoodItems),
            builder: (context, recipeSnapshot) {
              if (recipeSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (recipeSnapshot.hasError) {
                return Center(child: Text('Error: ${recipeSnapshot.error}'));
              }
              if (!recipeSnapshot.hasData || recipeSnapshot.data!.isEmpty) {
                return const Center(child: Text('No recipes found'));
              }

              List<Map<String, dynamic>> recipes = recipeSnapshot.data!;

              return ListView.builder(
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  var recipe = recipes[index];
                  List<String> recipeIngredients =
                      List<String>.from(recipe['ingredients']);

                  // Count matching ingredients
                  int matchingIngredients = recipeIngredients
                      .where((ingredient) => userFoodItems.any((foodItem) =>
                          ingredient
                              .toLowerCase()
                              .contains(foodItem.toLowerCase())))
                      .length;

                  return ListTile(
                    leading: Image.network(recipe['image']),
                    title: Text(recipe['label']),
                    subtitle: Text(
                        'Ingredients you have: $matchingIngredients out of ${recipeIngredients.length}'),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
