import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class RecipeDetailPage extends StatefulWidget {
  final Map<String, dynamic> recipe;
  final Function() onFavoritesChanged;

  RecipeDetailPage({required this.recipe, required this.onFavoritesChanged});

  @override
  _RecipeDetailPageState createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    User? user = _auth.currentUser;
    if (user != null) {
      QuerySnapshot snapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: user.uid)
          .where('label', isEqualTo: widget.recipe['label'])
          .get();

      setState(() {
        isFavorite = snapshot.docs.isNotEmpty;
      });
    }
  }

  Future<void> addToFavorites() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('favorites').add({
        'userId': user.uid,
        'label': widget.recipe['label'],
        'image': widget.recipe['image'],
        'ingredients': widget.recipe['ingredients'],
        'instructions': widget.recipe['instructions'],
        'url': widget.recipe['url'],
      });
      setState(() {
        isFavorite = true;
      });
      widget.onFavoritesChanged();
    }
  }

  Future<void> removeFromFavorites() async {
    User? user = _auth.currentUser;
    if (user != null) {
      QuerySnapshot snapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: user.uid)
          .where('label', isEqualTo: widget.recipe['label'])
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      setState(() {
        isFavorite = false;
      });
      widget.onFavoritesChanged();
    }
  }

  Future<void> _launchURL(String url) async {
    if (url.isEmpty ||
        (!url.startsWith('http://') && !url.startsWith('https://'))) {
      print('Invalid URL: $url');
      throw 'Could not launch URL: $url';
    }

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Could not launch URL: $url');
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> ingredients = List<String>.from(widget.recipe['ingredients']);
    List<String> instructions =
        List<String>.from(widget.recipe['instructions'] ?? []);
    String instructionsUrl = widget.recipe['url'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Details'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Stack(
      children: [
        Container(
          width: double.infinity,
          height: 250,
          child: CachedNetworkImage(
            imageUrl: widget.recipe['image'],
            fit: BoxFit.cover,
            placeholder: (context, url) => Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) => Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
          ),
        ),
        Positioned(
          bottom: 16.0,
          left: 16.0,
          right: 16.0,
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.recipe['label'],
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 4.0,
                          color: Colors.black,
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
              ),
            ),
          ),
        ),
      ],
    ),

            const SizedBox(height: 16.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                 ElevatedButton.icon(
  onPressed: () async {
    if (isFavorite) {
      await removeFromFavorites();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from favorites!')),
      );
    } else {
      await addToFavorites();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to favorites!')),
      );
    }
  },
  icon: Icon(
    isFavorite ? Icons.favorite : Icons.favorite_border,
    color: Colors.white, // Ensures the icon is visible
  ),
  label: Text(
    isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
    style: const TextStyle(color: Colors.white), // Text color explicitly set
  ),
  style: ElevatedButton.styleFrom(
    backgroundColor: Theme.of(context).colorScheme.secondary,
    foregroundColor: Colors.white, // Ensures text and icon visibility
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
  ),
),

                  const SizedBox(height: 16.0),
                  Text(
                    'Ingredients',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  ...ingredients.map((ingredient) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(ingredient, style: const TextStyle(fontSize: 16)),
                      )),
                  const SizedBox(height: 16.0),
                  Text(
                    'Instructions',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  ...instructions.map((instruction) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(instruction, style: const TextStyle(fontSize: 16)),
                      )),
                  if (instructionsUrl.isNotEmpty)
                    ElevatedButton(
                      onPressed: () {
                        _launchURL(instructionsUrl).catchError((e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Could not open URL: $instructionsUrl')),
                          );
                        });
                      },
                      child: const Text('View Full Instructions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
