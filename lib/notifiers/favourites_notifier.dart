import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/models/recipe_model.dart';
import 'package:shelfaware_app/repositories/favourites_repository.dart';


class FavouritesNotifier extends StateNotifier<List<Recipe>> {
  final FavouritesRepository _repository;

  FavouritesNotifier(this._repository) : super([]) {
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    try {
      final recipes = await _repository.fetchFavorites();
      state = recipes;
    } catch (e) {
      print('Error loading favorites: $e');
      state = [];
    }
  }

  Future<void> addFavorite(Recipe recipe) async {
    if (!state.any((r) => r.id == recipe.id)) {
      state = [...state, recipe]; // Update state immediately
      await _repository.addFavourite(recipe.toMap()); // Persist
    }
  }

  Future<void> removeFavorite(Recipe recipe) async {
    state = state.where((r) => r.id != recipe.id).toList(); // Update state immediately
    await _repository.removeFavourite(recipe.id.toString()); // Persist
  }
}
