class Ingredient {
  final String name;
  final double amount;
  final String unit;

  Ingredient({
    required this.name,
    required this.amount,
    required this.unit,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name'] ?? 'Unknown',
      amount: json['amount'] ?? 0.0,
      unit: json['unit'] ?? '',
    );
  }
}

class Recipe {
  final int id;
  final String title;
  final String imageUrl;
  final List<Ingredient>
      ingredients; // Change from List<String> to List<Ingredient>
  final String sourceUrl;
  final String summary;
  final String? instructions;

  Recipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.ingredients,
    required this.sourceUrl,
    required this.summary,
    this.instructions,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    // Combine used and missed ingredients into Ingredient objects
    List<Ingredient> allIngredients = [];

    // Add used ingredients
    if (json['usedIngredients'] != null) {
      allIngredients.addAll((json['usedIngredients'] as List)
          .map((item) => Ingredient.fromJson(
              item)) // Create Ingredient objects from the JSON
          .toList());
    }

    // Add missed ingredients
    if (json['missedIngredients'] != null) {
      allIngredients.addAll((json['missedIngredients'] as List)
          .map((item) => Ingredient.fromJson(
              item)) // Create Ingredient objects from the JSON
          .toList());
    }

    return Recipe(
      id: json['id'],
      title: json['title'],
      imageUrl: json['image'] ?? '',
      ingredients: allIngredients, // Combine both used and missed ingredients
      sourceUrl: json['sourceUrl'] ?? '',
      summary: json['summary'] ?? 'No summary available.',
      instructions: json['instructions'] ?? 'No instructions available.',
    );
  }

  Map<String, dynamic> toMap() {
    // Convert the Recipe object back into a map for saving in a database
    return {
      'id': id,
      'title': title,
      'image': imageUrl,
      'ingredients': ingredients
          .map((ingredient) => {
                'name': ingredient.name,
                'amount': ingredient.amount,
                'unit': ingredient.unit,
              })
          .toList(),
      'sourceUrl': sourceUrl,
      'summary': summary,
    };
  }
}
