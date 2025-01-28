import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shelfaware_app/models/recipe_model.dart';
import 'package:shelfaware_app/pages/recipe_details_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
// Ensure this is imported correctly

class FavoritesPage extends StatefulWidget {
  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _favorites = [];

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
        _favorites = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      });
    }
  }

  Future<void> _removeFavorite(String recipeId) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('favorites')
          .doc(recipeId) // Assume recipeId is the document ID for favorites
          .delete();
      _fetchFavorites(); // Refresh favorites list after removing
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Recipes'),
        centerTitle: true,
      ),
      body: _favorites.isEmpty
          ? const Center(child: Text('No favorites yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16.0),
              separatorBuilder: (context, index) =>
                  const SizedBox(height: 16.0),
              itemCount: _favorites.length,
              itemBuilder: (context, index) {
                final recipe = _favorites[index];
                return GestureDetector(
                  onTap: () {
                    // Navigate to Recipe Detail Page when tapped
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecipeDetailsPage(
                          recipe: Recipe(id: recipe['id'], title: recipe['label'], imageUrl: recipe['image'], ingredients: recipe['ingredients'].join(', '), sourceUrl: recipe ['sourceUrl'], summary: ''),
                          onFavoritesChanged: () {
                            // Refresh the favorites list after changing favorites
                            _fetchFavorites();
                          }, matchedIngredients: [], 
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
                        // Cached Image Container
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(10),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: recipe['image'],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recipe['label'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
