import 'package:flutter/material.dart';
import 'package:shelfaware_app/models/recipe_model.dart';
import 'package:shelfaware_app/pages/recipe_details_page.dart';
import 'package:shelfaware_app/services/recipe_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fuzzy/fuzzy.dart';

class RecipeCard extends StatefulWidget {
  final Recipe recipe;
  final List<String> userIngredients;

  const RecipeCard({
    Key? key,
    required this.recipe,
    required this.userIngredients,
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

  // Check if the recipe is already in favourites
  void _checkIfFavourite() async {
    final docSnapshot = await FirebaseFirestore.instance
        .collection('favourites')
        .doc(widget.recipe.id.toString())
        .get();

    if (docSnapshot.exists) {
      setState(() {
        isFavourite = true;
      });
    }
  }

  // Toggle favourite status in Firestore
  void _toggleFavourite() async {
    setState(() {
      isFavourite = !isFavourite;
    });

    if (isFavourite) {
      // Add recipe to Firestore (creates collection if it doesn't exist)
      await FirebaseFirestore.instance.collection('favourites').doc(widget.recipe.id as String?).set({
        'id': widget.recipe.id,
        'title': widget.recipe.title,
        'imageUrl': widget.recipe.imageUrl,
        'ingredients': widget.recipe.ingredients,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      // Remove recipe from favourites
      await FirebaseFirestore.instance.collection('favourites').doc(widget.recipe.id as String?).delete();
    }
  }

List<String> getMatchingIngredients() {
  List<String> matchingIngredients = [];

  // Create Fuzzy instance for matching ingredient names with the user input
  var fuzzy = Fuzzy(widget.recipe.ingredients.map((ingredient) => ingredient.name).toList(), options: FuzzyOptions(threshold: 0.3));

  for (var userIngredient in widget.userIngredients) {
    var result = fuzzy.search(userIngredient);

    // If a match is found (result is not empty), increment the matching count
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
        // Navigate to RecipeDetailsPage on tap
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
        elevation: 6, // Slightly higher elevation for better visual separation
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Image
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.network(
                widget.recipe.imageUrl,
                height: 180, // Adjust image height for better layout balance
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            // Recipe Title with wrapping and ellipsis handling
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              child: Text(
                widget.recipe.title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2, // Allow the title to wrap
                overflow: TextOverflow.ellipsis, // Show ellipsis if it overflows
              ),
            ),

            // Ingredients Info (matching ingredients) and Favourite Button in the same row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'You have ${matchingIngredients.length} out of $totalIngredients ingredients',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  IconButton(
                    icon: Icon(
                      isFavourite ? Icons.favorite : Icons.favorite_border,
                      color: isFavourite ? Colors.red : Colors.red,
                    ),
                    onPressed: _toggleFavourite,
                  ),
                ],
              ),
            ),

            // Reduced bottom padding for a more compact layout
            Padding(
              padding: const EdgeInsets.only(bottom: 5), // Reduced bottom padding
            ),
          ],
        ),
      ),
    );
  }
}

