import 'package:flutter/material.dart';
import 'package:shelfaware_app/models/recipe_model.dart'; // Ensure this is the correct path to RecipeModel
import 'package:shelfaware_app/pages/recipe_details_page.dart';
import 'package:shelfaware_app/repositories/favourites_repository.dart';

class FavouritesPage extends StatefulWidget {
  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavouritesPage> with SingleTickerProviderStateMixin {
  late Future<List<Recipe>> favoritesFuture;
  final FavouritesRepository _favouritesRepository = FavouritesRepository();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    favoritesFuture = _fetchFavorites();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
    final brightness = Theme.of(context).brightness;
    final textColor = brightness == Brightness.dark ? Colors.white : Colors.black87;
    final subtitleColor = brightness == Brightness.dark ? Colors.white70 : Colors.grey[700];

    return Scaffold(
      appBar: AppBar(
      title: Text(
        'Favourites',
        style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: Theme.of(context).appBarTheme.titleTextStyle?.color ?? Colors.white,
        ),
      ),
      elevation: 2,
      ),
      body: FutureBuilder<List<Recipe>>(
        future: favoritesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: textColor)));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            List<Recipe> favorites = snapshot.data!;

            return AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return ListView.builder(
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    Recipe recipe = favorites[index];
                    final itemAnimation = Tween<Offset>(
                      begin: Offset(1, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(
                        index / favorites.length,
                        (index + 1) / favorites.length,
                        curve: Curves.easeInOut,
                      ),
                    ));

                    return SlideTransition(
                      position: itemAnimation,
                      child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: InkWell(
                        onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                          builder: (context) => RecipeDetailsPage(
                            recipe: recipe,
                            onFavoritesChanged: _refreshFavorites,
                            matchedIngredients: [],
                            isFavorite: true,
                            favouritesRepository: _favouritesRepository, // Added this line since it's coming from favorites
                          ),
                          ),
                        );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                            elevation: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                      child: Image.network(
                                        recipe.imageUrl,
                                        height: 180,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Container(height: 180, color: Colors.grey[300]),
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () async {
                                            await _favouritesRepository.deleteFavorite(recipe.id);
                                            _refreshFavorites();
                                          },
                                          customBorder: CircleBorder(),
                                          child: Container(
                                            padding: EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.8),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(Icons.favorite, color: Colors.red),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        recipe.title,
                                        style: TextStyle(
                                          fontSize: 20, 
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (recipe.summary.isNotEmpty) ...[
                                        SizedBox(height: 8),
                                        Text(
                                          recipe.summary,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: subtitleColor,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: subtitleColor),
                  SizedBox(height: 16),
                  Text(
                    "No favourite recipes yet",
                    style: TextStyle(fontSize: 18, color: textColor),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
