import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FavoriteButton extends StatefulWidget {
  final Map<String, dynamic> recipe;
  final List<String> favoriteRecipeIds;
  final Function onFavoriteChanged;

  FavoriteButton({
    required this.recipe,
    required this.favoriteRecipeIds,
    required this.onFavoriteChanged,
  });

  @override
  _FavoriteButtonState createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  late bool isFavorite;

  @override
  void initState() {
    super.initState();
    // Check if the recipe is already a favorite
    isFavorite = widget.favoriteRecipeIds.contains(widget.recipe['id'].toString());
  }

  // Toggle favorite state
  void _toggleFavorite() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final recipeId = widget.recipe['id'].toString();
      final title = widget.recipe['title'];
      final image = widget.recipe['image'];
      final sourceUrl = widget.recipe['sourceUrl'];

      final favoritesCollection = FirebaseFirestore.instance.collection('favourites');

      // Check if the recipe is already a favorite
      final favoriteDocRef = favoritesCollection.doc('${user.uid}_$recipeId');

      if (isFavorite) {
        // Remove recipe from favorites
        await favoriteDocRef.delete();
      } else {
        // Add recipe to Firestore favorites with a unique document ID
        await favoriteDocRef.set({
          'userId': user.uid,
          'recipeId': recipeId,
          'title': title,
          'image': image,
          'sourceUrl': sourceUrl,
          'timestamp': FieldValue.serverTimestamp(), // For sorting later
        });
      }

      // Update local state and notify parent widget
      setState(() {
        isFavorite = !isFavorite;
      });

      // Update the parent with the latest favorite recipe list
      if (isFavorite) {
        widget.favoriteRecipeIds.add(recipeId);
      } else {
        widget.favoriteRecipeIds.remove(recipeId);
      }

      widget.onFavoriteChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: isFavorite ? Colors.red : Colors.grey,
      ),
      onPressed: _toggleFavorite,
    );
  }
}
