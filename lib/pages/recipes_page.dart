import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  Future<void> _fetchFavorites() async {
    User? user = _auth.currentUser;
    if (user != null) {
      QuerySnapshot snapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: user.uid)
          .get();

      setState(() {
        favoriteRecipeIds =
            snapshot.docs.map((doc) => doc['recipeId'] as String).toList();
      });
    }
  }

  Future<void> _toggleFavorite(Map<String, dynamic> recipe) async {
    User? user = _auth.currentUser;
    if (user != null) {
      String? recipeId = recipe['id'];

      // Check if recipeId is null
      if (recipeId == null) {
        print("Error: Recipe ID is null for recipe: ${recipe['label']}");
        return; // Exit the method if the ID is null
      }

      if (!favoriteRecipeIds.contains(recipeId)) {
        // Add to favorites
        await _firestore.collection('favorites').add({
          'userId': user.uid,
          'recipeId': recipeId,
          'label': recipe['label'],
          'image': recipe['image'],
          'ingredients': recipe['ingredients'],
        });
        setState(() {
          favoriteRecipeIds.add(recipeId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added to favorites!')),
        );
      } else {
        // Remove from favorites
        QuerySnapshot snapshot = await _firestore
            .collection('favorites')
            .where('userId', isEqualTo: user.uid)
            .where('recipeId', isEqualTo: recipeId)
            .get();

        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }

        setState(() {
          favoriteRecipeIds.remove(recipeId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed from favorites!')),
        );
      }
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
                padding: const EdgeInsets.all(16.0),
                shrinkWrap:
                    true, // Allows ListView to take only necessary space
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  var recipe = recipes[index];
                  List<String> recipeIngredients =
                      List<String>.from(recipe['ingredients']);

                  int matchingIngredients = recipeIngredients
                      .where((ingredient) => userFoodItems.any((foodItem) =>
                          ingredient
                              .toLowerCase()
                              .contains(foodItem.toLowerCase())))
                      .length;

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
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(10)),
                            child: Image.network(
                              recipe['image'],
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        'Ingredients you have: $matchingIngredients out of ${recipeIngredients.length}',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    favoriteRecipeIds.contains(recipe['id'])
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                  ),
                                  color: Colors.red,
                                  onPressed: () {
                                    _toggleFavorite(recipe);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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
