import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shelfaware_app/components/favourite_button.dart';
import 'package:shelfaware_app/models/recipe_model.dart';
import 'package:flutter_html/flutter_html.dart'; // Import flutter_html package
import 'package:fuzzy/fuzzy.dart';
import 'package:shelfaware_app/repositories/favourites_repository.dart'; // Import the fuzzy package

class RecipeDetailsPage extends StatefulWidget {
  final Recipe recipe;
  final List<String> matchedIngredients;
  final Function() onFavoritesChanged;
  final bool isFavorite;
  final Function(Recipe)? onRemoveFromFavorites;
  final FavouritesRepository favouritesRepository;

  const RecipeDetailsPage({
    Key? key,
    required this.recipe,
    required this.matchedIngredients,
    required this.onFavoritesChanged,
    required this.isFavorite,
    required this.favouritesRepository,
    this.onRemoveFromFavorites,
  }) : super(key: key);

  @override
  _RecipeDetailsPageState createState() => _RecipeDetailsPageState();
}

class _RecipeDetailsPageState extends State<RecipeDetailsPage>
    with SingleTickerProviderStateMixin {
  late Fuzzy fuzzyMatcher;
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isCurrentlyFavorite = false;

  @override
  void initState() {
    super.initState();
    _isCurrentlyFavorite = widget.isFavorite;
    fuzzyMatcher = Fuzzy(widget.matchedIngredients);

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
  }
  @override
  void dispose() {
    // Update favorites status before disposing
    widget.onFavoritesChanged();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleFavoritePressed() async {
    if (widget.recipe.id == null) {
      return;
    }

    final previousState = _isCurrentlyFavorite;
    final currentContext = context;
    
    setState(() {
      _isCurrentlyFavorite = !_isCurrentlyFavorite;
    });
    
    try {
      final isFavourite = _isCurrentlyFavorite;
      final currentUser = widget.favouritesRepository.auth.currentUser;
      
      if (currentUser != null) {
        if (isFavourite) {
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
            'userId':
                widget.favouritesRepository.auth.currentUser?.uid ?? 'Unknown',
            'timestamp': FieldValue.serverTimestamp(),
          });
          _showSnackBar("Recipe added to favourites.", Icons.favorite);
        } else {
          await widget.favouritesRepository
              .removeFavourite(widget.recipe.id.toString());
          _showSnackBar("Recipe removed from favourites.", Icons.favorite_border);
        }
      } else {
        await FavouritesRepository().deleteFavorite(widget.recipe.id);
        
        if (widget.onRemoveFromFavorites != null) {
          widget.onRemoveFromFavorites!(widget.recipe);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            const SnackBar(content: Text("Recipe removed from favorites"))
          );
        }
      }
      
      widget.onFavoritesChanged();
    } catch (e) {
      debugPrint("Error updating favorites: $e");
      
      if (mounted) {
        setState(() {
          _isCurrentlyFavorite = previousState;
        });
        
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text("Failed to update favorites"))
        );
      }
    }
  }

  void _showSnackBar(String message, IconData icon) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
           
              SizedBox(width: 8),
              Text(message),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          "Recipe Details",
          style: TextStyle(color: Colors.white, shadows: [
            Shadow(
              blurRadius: 5,
              color: Colors.black,
              offset: Offset(0, 2),
            ),
          ]),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            child: FavouriteButton(
              isFavourite: _isCurrentlyFavorite, 
              onPressed: _handleFavoritePressed
            ),
          )
        ],
      ),
      body: FadeTransition(
        opacity: _fadeInAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Hero(
                  tag: 'recipe-${widget.recipe.id}',
                  child: Stack(
                    children: [
                      Container(
                        height: 300,
                        width: double.infinity,
                        child: Image.network(
                          widget.recipe.imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Text(
                          widget.recipe.title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 5,
                                color: Colors.black,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Ingredients Section
                    Row(
                      children: [
                        Icon(Icons.restaurant, color: Colors.green[800]),
                        SizedBox(width: 8),
                        Text(
                          'Ingredients',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800]),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    ...widget.recipe.ingredients.asMap().entries.map((entry) {
                      final index = entry.key;
                      final ingredient = entry.value;
                      final isMatched =
                          fuzzyMatcher.search(ingredient.name).isNotEmpty;

                      return TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 400 + (index * 100)),
                        tween: Tween<double>(begin: 0, end: 1),
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(20 * (1 - value), 0),
                            child: Opacity(
                              opacity: value,
                              child: Card(
                                margin: EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 3,
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  title: Text(
                                    '${ingredient.amount} ${ingredient.unit} ${ingredient.name}',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  trailing: AnimatedContainer(
                                    duration: Duration(milliseconds: 300),
                                    child: Icon(
                                      isMatched
                                          ? Icons.check_circle
                                          : Icons.circle_outlined,
                                      color: isMatched
                                          ? Colors.green
                                          : Colors.grey,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),

                    SizedBox(height: 24),

                    // Instructions Section
                    Row(
                      children: [
                        Icon(Icons.menu_book, color: Colors.green[800]),
                        SizedBox(width: 8),
                        Text(
                          'Instructions',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800]),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey[900] 
                        : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                        ),
                      ],
                      ),
                      child: Html(
                      data: widget.recipe.instructions,
                      style: {
                        "body": Style(
                        fontSize: FontSize(16),
                        lineHeight: LineHeight(1.6),
                        color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                        ),
                        "li": Style(),
                      },
                      ),
                    ),
                    SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
