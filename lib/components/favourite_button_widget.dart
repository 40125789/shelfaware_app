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
    required Future<void> Function() onFavoriteToggle,
  });

  @override
  _FavoriteButtonState createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  late bool isFavorite;

  @override
  void initState() {
    super.initState();
    // Check if the recipe is already in favorites
    isFavorite = widget.favoriteRecipeIds.contains(widget.recipe['label']);
  }

  void _toggleFavorite() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final recipeId = widget.recipe['label'];

      // Add or remove from favorites
      if (isFavorite) {
        // Remove from favorites
        await FirebaseFirestore.instance
            .collection('favorites')
            .where('userId', isEqualTo: user.uid)
            .where('label', isEqualTo: recipeId)
            .get()
            .then((snapshot) async {
          for (var doc in snapshot.docs) {
            await doc.reference.delete();
          }
        });
      } else {
        // Add to favorites
        await FirebaseFirestore.instance.collection('favorites').add({
          'userId': user.uid,
          'label': recipeId,
          'image': widget.recipe['image'],
          'ingredients': widget.recipe['ingredients'],
          'instructions': widget.recipe['instructions'],
          'url': widget.recipe['url'],
        });
      }

      // Update local state
      setState(() {
        isFavorite = !isFavorite;
      });

      // Directly update the parent without calling onFavoriteChanged
      if (isFavorite) {
        widget.favoriteRecipeIds.add(recipeId);
      } else {
        widget.favoriteRecipeIds.remove(recipeId);
      }
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
