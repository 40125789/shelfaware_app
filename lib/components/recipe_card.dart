import 'package:flutter/material.dart';
import 'package:shelfaware_app/models/recipe_model.dart';
import 'package:shelfaware_app/screens/favourites_page.dart';
import 'package:shelfaware_app/screens/recipe_details_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:shelfaware_app/repositories/favourites_repository.dart';
import 'package:shelfaware_app/components/favourite_button.dart';
import 'package:shelfaware_app/components/matching_ingredients_text.dart';

class RecipeCard extends StatefulWidget {
  final Recipe recipe;
  final List<String> userIngredients;
  final FavouritesRepository favouritesRepository;
  final void Function(bool isFavorite) onFavoriteChanged; // Callback to notify when favourite status changes
  final bool isFavorite; // Initial favourite status
  final String heroNamespace; // Added heroNamespace for Hero animations

  const RecipeCard({
    Key? key,
    required this.recipe,
    required this.userIngredients,
    required this.favouritesRepository,
    required this.onFavoriteChanged,
    required this.isFavorite,
    this.heroNamespace = 'recipe', // Default value
  }) : super(key: key);

  @override
  _RecipeCardState createState() => _RecipeCardState();
}

class _RecipeCardState extends State<RecipeCard> {
  late bool isFavourite;

  @override
  void initState() {
    super.initState();
    isFavourite = widget.isFavorite; // Set initial state to passed-in favourite status
    _checkIfFavourite();
  }

  Future<void> _checkIfFavourite() async {
    try {
      final isFav = await widget.favouritesRepository
          .isFavourite(widget.recipe.id.toString());
      if (mounted) {
        setState(() {
          isFavourite = isFav;
        });
      }
    } catch (e) {
      print('Error checking favourite status: $e');
    }
  }

  void _toggleFavourite() async {
    final newValue = !isFavourite;

    setState(() {
      isFavourite = newValue;
    });

    try {
      if (newValue) {
        await widget.favouritesRepository.addFavourite({
          'id': widget.recipe.id,
          'title': widget.recipe.title,
          'imageUrl': widget.recipe.imageUrl,
          'ingredients': widget.recipe.ingredients
              .map((ingredient) => {
                    'name': ingredient.name,
                    'unit': ingredient.unit,
                    'amount': ingredient.amount
                  })
              .toList(),
          'totalIngredients': widget.recipe.ingredients.length,
          'instructions': widget.recipe.instructions,
          'userId': widget.favouritesRepository.auth.currentUser?.uid ?? 'Unknown',
          'timestamp': FieldValue.serverTimestamp(),
        });
        _showSnackBar("Recipe added to favourites.", Icons.favorite);
      } else {
        await widget.favouritesRepository
            .removeFavourite(widget.recipe.id.toString());
        _showSnackBar("Recipe removed from favourites.", Icons.favorite_border);
      }

      widget.onFavoriteChanged(isFavourite); // Notify parent (FavouritesPage) of the change

    } catch (e) {
      print("Error updating favourites: $e");
    }
  }

  void _showSnackBar(String message, IconData icon) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.red),
          SizedBox(width: 10),
          Expanded(child: Text(message)),
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FavouritesPage(),
                ),
              );
            },
          ),
        ],
      ),
      duration: Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> refreshFavorites() async {
    await _checkIfFavourite();
  }

  List<String> getMatchingIngredients() {
    Set<String> matchingIngredients = {};

    var fuzzy = Fuzzy(
        widget.recipe.ingredients.map((ingredient) => ingredient.name).toList(),
        options: FuzzyOptions(threshold: 0.3));

    for (var userIngredient in widget.userIngredients) {
      var result = fuzzy.search(userIngredient);
      if (result.isNotEmpty) {
        matchingIngredients.add(userIngredient);
      }
    }

    return matchingIngredients.toList();
  }

  @override
  Widget build(BuildContext context) {
    final matchingIngredients = getMatchingIngredients();
    final totalIngredients = widget.recipe.ingredients.length;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailsPage(
              recipe: widget.recipe,
              matchedIngredients: matchingIngredients.toSet().toList(),
              onFavoritesChanged: refreshFavorites,
              isFavorite: isFavourite,
              favouritesRepository: widget.favouritesRepository,
            ),
          ),
        );

        // Refresh favorite status when returning
        if (mounted) {
          _checkIfFavourite();
          setState(() {}); // Force rebuild to reflect changes
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 8,
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image with gradient overlay
                Stack(
                  children: [
                    Hero(
                      tag: '${widget.heroNamespace}-recipe-image-${widget.recipe.id}',

                      child: Image.network(
                        widget.recipe.imageUrl,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 180,
                          color: Colors.grey[300],
                          child: Icon(Icons.image_not_supported, size: 50),
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 180,
                            color: Colors.grey[200],
                            child: Center(child: CircularProgressIndicator()),
                          );
                        },
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Text(
                    widget.recipe.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MatchingIngredientsText(
                        matchingCount: matchingIngredients.length,
                        totalCount: totalIngredients,
                      ),
                      FavouriteButton(
                        isFavourite: isFavourite,
                        onPressed: _toggleFavourite,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Top-right indicator for high match rate (optional)
            if (matchingIngredients.length > totalIngredients * 0.7)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Great match!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
