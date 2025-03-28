import 'package:flutter/material.dart';
import 'package:shelfaware_app/models/recipe_model.dart';
import 'package:flutter_html/flutter_html.dart';  // Import flutter_html package
import 'package:fuzzy/fuzzy.dart'; // Import the fuzzy package

class RecipeDetailsPage extends StatefulWidget {
  final Recipe recipe;
  final VoidCallback onFavoritesChanged;
  final List<String> matchedIngredients; // List of ingredients the user has

  const RecipeDetailsPage({
    Key? key,
    required this.recipe,
    required this.onFavoritesChanged,
    required this.matchedIngredients,
  }) : super(key: key);

  @override
  _RecipeDetailsPageState createState() => _RecipeDetailsPageState();
}

class _RecipeDetailsPageState extends State<RecipeDetailsPage> {
  bool _isFavorite = false;
  late Fuzzy fuzzyMatcher; // Instance of Fuzzy class

  @override
  void initState() {
    super.initState();

    fuzzyMatcher = Fuzzy(widget.matchedIngredients); // Initialize Fuzzy matcher with matched ingredients
  }

  bool _checkIfFavorite(Recipe recipe) {
    return false; // Placeholder return
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    widget.onFavoritesChanged(); // Notify parent to update favorite state globally
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recipe Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      widget.recipe.imageUrl,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    right: 10,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.recipe.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Ingredients Section
              Text(
                'Ingredients:',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green[800]),
              ),
              SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: widget.recipe.ingredients.length,
                itemBuilder: (context, index) {
                  final ingredient = widget.recipe.ingredients[index];

                  // Use fuzzy matching to check if the ingredient name is similar to any of the matched ingredients
                  bool isMatched = fuzzyMatcher.search(ingredient.name).isNotEmpty;

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${ingredient.amount} ${ingredient.unit} ${ingredient.name}',
                              style: TextStyle(fontSize: 16),
                              overflow: TextOverflow.ellipsis, // Prevent overflow by truncating text
                            ),
                          ),
                          // Show check or empty circle based on match
                          Icon(
                            isMatched ? Icons.check_circle : Icons.circle_outlined,
                            color: isMatched ? Colors.green : Colors.grey,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: 20),

              // Instructions Section
              Text(
                'Instructions:',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green[800]),
              ),
              SizedBox(height: 10),
              Html(
                data: widget.recipe.instructions, // Pass the HTML content here
                style: {
                  "body": Style(fontSize: FontSize(16), lineHeight: LineHeight(1.5)), // Customize HTML rendering style
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

