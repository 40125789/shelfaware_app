import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shelfaware_app/components/favourite_button_widget.dart';
import 'package:shelfaware_app/services/recipe_service.dart';
import 'package:shelfaware_app/pages/recipe_details_page.dart';

class RecipesPage extends StatefulWidget {
  @override
  _RecipesPageState createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  final RecipeService recipeService = RecipeService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<String> favoriteRecipeIds = [];

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  // Fetch user's favorite recipes from Firestore
  Future<void> _fetchFavorites() async {
    User? user = _auth.currentUser;
    if (user != null) {
      QuerySnapshot snapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: user.uid)
          .get();

      setState(() {
        favoriteRecipeIds = snapshot.docs.map((doc) => doc['label'] as String).toList();
      });
    }
  }

 // Add this method to update the favorite status for a single recipe
Future<void> _toggleFavorite(String recipeLabel) async {
  User? user = _auth.currentUser;
  if (user != null) {
    if (favoriteRecipeIds.contains(recipeLabel)) {
      // Remove from favorites
      await _firestore.collection('favorites').doc(recipeLabel).delete();
    } else {
      // Add to favorites
      await _firestore.collection('favorites').add({
        'userId': user.uid,
        'label': recipeLabel,
      });
    }

    // Update the local favorite list
    setState(() {
      if (favoriteRecipeIds.contains(recipeLabel)) {
        favoriteRecipeIds.remove(recipeLabel);
      } else {
        favoriteRecipeIds.add(recipeLabel);
      }
    });
  }
}


  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                shrinkWrap: true,
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  var recipe = recipes[index];
                  List<String> recipeIngredients = List<String>.from(recipe['ingredients']);

                  // Filter user inventory to only include items that match recipe ingredients
                  List<String> matchingUserItems = userFoodItems.where((userItem) {
                    return recipeIngredients.any((ingredient) => 
                      ingredient.toLowerCase().contains(userItem.toLowerCase()));
                  }).toList();

                  // Calculate the number of matching ingredients
                  int matchingIngredients = matchingUserItems.length;
                  double matchPercentage = (matchingIngredients / recipeIngredients.length) * 100;

                  // Set a threshold for displaying the recipe (e.g., 10% match)
                  if (matchPercentage >= 10) {
                    // Check if recipe is in favorites
                    bool isFavorite = favoriteRecipeIds.contains(recipe['label']);

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecipeDetailPage(
                              recipe: recipe,
                              onFavoritesChanged: _fetchFavorites,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16.0), // Add spacing between cards
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                                child: CachedNetworkImage(
                                  imageUrl: recipe['image'],
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  errorWidget: (context, url, error) => Icon(Icons.error),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            recipe['label'],
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'Ingredients you have: $matchingIngredients of ${recipeIngredients.length} (${matchPercentage.toStringAsFixed(0)}%)',
                                            style: TextStyle(color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                   FavoriteButton(
  recipe: recipe,  // Pass the full recipe object
  favoriteRecipeIds: favoriteRecipeIds,  // Pass the list of favorite recipe IDs  // Check if the recipe is in the favorites list  // Trigger a re-fetch of favorites when state changes
  onFavoriteToggle: () => _toggleFavorite(recipe['label']),  // Call the function to toggle the favorite state
  onFavoriteChanged: _fetchFavorites,  // Add the required onFavoriteChanged argument
)
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                    
                  } else {
                    return SizedBox.shrink();
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
