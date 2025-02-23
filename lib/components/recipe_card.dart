import 'package:flutter/material.dart';
import 'package:shelfaware_app/models/recipe_model.dart';
import 'package:shelfaware_app/pages/favourites_page.dart';
import 'package:shelfaware_app/pages/recipe_details_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:shelfaware_app/repositories/favourites_repository.dart';
import 'package:shelfaware_app/components/favourite_button.dart';
import 'package:shelfaware_app/components/matching_ingredients_text.dart';

class RecipeCard extends StatefulWidget {
  final Recipe recipe;
  final List<String> userIngredients;
  final FavouritesRepository favouritesRepository;

  const RecipeCard({
    Key? key,
    required this.recipe,
    required this.userIngredients,
    required this.favouritesRepository,
  }) : super(key: key);

  @override
  _RecipeCardState createState() => _RecipeCardState();
}

class _RecipeCardState extends State<RecipeCard> {
  bool isFavourite = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavourite();
  }

  void _checkIfFavourite() async {
    final isFav = await widget.favouritesRepository
        .isFavourite(widget.recipe.id.toString());
    setState(() {
      isFavourite = isFav;
    });
  }

  void _toggleFavourite() async {
    setState(() {
      isFavourite = !isFavourite;
    });

    try {
      if (isFavourite) {
        await widget.favouritesRepository.addFavourite({
          'id': widget.recipe.id,
          'title': widget.recipe.title,
          'imageUrl': widget.recipe.imageUrl,
          'ingredients': widget.recipe.ingredients
              .map((ingredient) => ingredient.name)
              .toList(),
          'totalIngredients': widget.recipe.ingredients.length,
          'instructions': widget.recipe.instructions,
          'userId':
              widget.favouritesRepository.auth.currentUser?.uid ?? 'Unknown',
          'timestamp': FieldValue.serverTimestamp(),
        });
        _showSnackBar("Recipe added to favourites.");
      } else {
        await widget.favouritesRepository
            .removeFavourite(widget.recipe.id.toString());
        _showSnackBar("Recipe removed from favourites.");
      }
    } catch (e) {
      print("Error updating favourites: $e");
    }
  }

  void _showSnackBar(String message) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(Icons.favorite, color: Colors.red),
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

  List<String> getMatchingIngredients() {
    List<String> matchingIngredients = [];

    var fuzzy = Fuzzy(
        widget.recipe.ingredients.map((ingredient) => ingredient.name).toList(),
        options: FuzzyOptions(threshold: 0.3));

    for (var userIngredient in widget.userIngredients) {
      var result = fuzzy.search(userIngredient);
      if (result.isNotEmpty) {
        matchingIngredients.add(userIngredient);
      }
    }

    return matchingIngredients;
  }

  @override
  Widget build(BuildContext context) {
    final matchingIngredients = getMatchingIngredients();
    final totalIngredients = widget.recipe.ingredients.length;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailsPage(
              recipe: widget.recipe,
              matchedIngredients: matchingIngredients,
              onFavoritesChanged: () {
                setState(() {});
              },
            ),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 6,
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.network(
                widget.recipe.imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              child: Text(
                widget.recipe.title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
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
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
            ),
          ],
        ),
      ),
    );
  }
}
