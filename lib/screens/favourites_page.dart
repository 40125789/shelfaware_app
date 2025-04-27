import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shelfaware_app/components/recipe_card.dart';
import 'package:shelfaware_app/models/recipe_model.dart'; // Ensure this is the correct path to RecipeModel
import 'package:shelfaware_app/notifiers/favourites_notifier.dart';
import 'package:shelfaware_app/screens/recipe_details_page.dart';
import 'package:shelfaware_app/repositories/favourites_repository.dart';
import 'package:shelfaware_app/services/food_service.dart';
import 'package:shelfaware_app/services/recipe_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final favouritesProvider =
    StateNotifierProvider<FavouritesNotifier, List<Recipe>>(
  (ref) => FavouritesNotifier(FavouritesRepository()),
);

class FavouritesPage extends ConsumerStatefulWidget {
  const FavouritesPage({Key? key}) : super(key: key);

  @override
  FavouritesPageState createState() => FavouritesPageState();
}

class FavouritesPageState extends ConsumerState<FavouritesPage>
    with SingleTickerProviderStateMixin {
  List<String> userIngredients = []; // Store user's ingredients
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Set up animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Load user ingredients and favorites on page creation
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadUserIngredients();
      ref.read(favouritesProvider.notifier).loadFavorites();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserIngredients() async {
    try {
      final ingredients = await FoodService().fetchUserIngredients();
      setState(() {
        userIngredients = ingredients;
      });
    } catch (e) {
      print('Error loading user ingredients: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favouritesProvider);
    final notifier = ref.read(favouritesProvider.notifier);

    final brightness = Theme.of(context).brightness;
    final textColor =
        brightness == Brightness.dark ? Colors.white : Colors.black87;
    final subtitleColor =
        brightness == Brightness.dark ? Colors.white70 : Colors.grey[700];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Favourites',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Theme.of(context).appBarTheme.titleTextStyle?.color ??
                Colors.white,
          ),
        ),
        elevation: 2,
      ),
      body: favorites.isEmpty
          ? Center(
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
            )
          : RefreshIndicator(
              onRefresh: () async => await notifier.loadFavorites(),
              child: FadeTransition(
                opacity: _animation,
                child: ListView.builder(
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final recipe = favorites[index];

                    return AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(1, 0), // Start off to the right
                            end: Offset.zero, // End at the current position
                          ).animate(CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(
                              index / favorites.length * 0.6,
                              (index + 1) / favorites.length * 0.6 + 0.4,
                              curve: Curves.easeOutQuad,
                            ),
                          )),
                          child: child,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        child: InkWell(
                          onTap: () async {
                            // Wait for navigation to complete and then refresh favorites
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RecipeDetailsPage(
                                  recipe: recipe,
                                  onFavoritesChanged: () async {
                                    // Reload favorites after navigating back
                                    await notifier.loadFavorites();
                                  },
                                  matchedIngredients: [],
                                  isFavorite: true,
                                  favouritesRepository: FavouritesRepository(),
                                ),
                              ),
                            );
                            // Refresh favorites list when returning from details page
                            notifier.loadFavorites();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: RecipeCard(
                            key: ValueKey(recipe.id),
                            favouritesRepository: FavouritesRepository(),
                            recipe: recipe,
                            userIngredients: userIngredients,
                            isFavorite: favorites.contains(recipe),
                            heroNamespace: 'favouritesPage',
                            onFavoriteChanged: (isFavorite) {
                              if (!isFavorite) {
                                notifier.removeFavorite(recipe);
                              } else {
                                notifier.addFavorite(recipe);
                              }
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }
}
