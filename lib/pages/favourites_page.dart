import 'package:flutter/material.dart';
import 'package:shelfaware_app/models/recipe_model.dart'; // Ensure this is the correct path to RecipeModel
import 'package:shelfaware_app/pages/recipe_details_page.dart';
import 'package:shelfaware_app/repositories/favourites_repository.dart';

class FavouritesPage extends StatefulWidget {
  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavouritesPage> {
  late Future<List<Recipe>> favoritesFuture;
  final FavouritesRepository _favouritesRepository = FavouritesRepository();

  @override
  void initState() {
    super.initState();
    favoritesFuture = _fetchFavorites();
  }

  Future<List<Recipe>> _fetchFavorites() async {
    return await _favouritesRepository.fetchFavorites();
  }

  void _refreshFavorites() {
    setState(() {
      favoritesFuture = _fetchFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Favourites"),
        elevation: 1,
      ),
      body: FutureBuilder<List<Recipe>>(
        future: favoritesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            List<Recipe> favorites = snapshot.data!;

            return ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                Recipe recipe = favorites[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecipeDetailsPage(
                            recipe: recipe,
                            onFavoritesChanged: _refreshFavorites,
                            matchedIngredients: [],
                          ),
                        ),
                      );
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                            child: Image.network(
                              recipe.imageUrl,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(height: 150, color: Colors.grey[300]),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recipe.title,
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 5),
                                Text(
                                  recipe.summary,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        if (recipe.sourceUrl.isNotEmpty) {
                                          // Open the recipe source URL in a browser
                                        }
                                      },
                                      child: Text("View Recipe"),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.favorite, color: Colors.red),
                                      onPressed: () async {
                                        await _favouritesRepository.deleteFavorite(recipe.id);
                                        _refreshFavorites();
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          } else {
            return Center(child: Text("No favourite recipes found"));
          }
        },
      ),
    );
  }
}
