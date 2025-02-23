import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
}