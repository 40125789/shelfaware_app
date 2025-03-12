import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shelfaware_app/models/recipe_model.dart';

class FavouritesRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  FavouritesRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : firestore = firestore ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance;

  Future<bool> isFavourite(String recipeId) async {
    final docSnapshot = await firestore.collection('favourites').doc(recipeId).get();
    return docSnapshot.exists;
  }

  Future<void> addFavourite(Map<String, dynamic> recipeData) async {
    final collectionRef = firestore.collection('favourites');
    final docRef = collectionRef.doc(recipeData['id'].toString());
    await docRef.set(recipeData);
  }

  Future<void> removeFavourite(String recipeId) async {
    final collectionRef = firestore.collection('favourites');
    final docRef = collectionRef.doc(recipeId);
    await docRef.delete();
  }

  Future<List<Recipe>> fetchFavorites() async {
    User? user = auth.currentUser;
    if (user != null) {
      final snapshot = await firestore
          .collection('favourites')
          .where('userId', isEqualTo: user.uid)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Recipe(
          id: int.parse(doc.id),
          title: data['title'] ?? 'Unknown Recipe',
          imageUrl: data['imageUrl'] ?? '',
          summary: data['summary'] ?? 'No summary available.',
          sourceUrl: data['sourceUrl'] ?? '',
          ingredients: (data['ingredients'] as List<dynamic>? ?? [])
              .map((ingredient) => Ingredient(
                    name: ingredient['name'] ?? 'Unknown',
                    amount: ingredient['amount'] ?? 0.0,
                    unit: ingredient['unit'] ?? '',
                  ))
              .toList(),
          instructions: data['instructions'] ?? '',
        );
      }).toList();
    }
    return [];
  }

  Future<void> deleteFavorite(int recipeId) async {
    await firestore.collection('favourites').doc(recipeId.toString()).delete();
  }
}
