import 'package:flutter_test/flutter_test.dart';
import 'package:shelfaware_app/models/recipe_model.dart';

void main() {
  group('Ingredient', () {
    test('fromJson creates an Ingredient from valid JSON', () {
      final json = {
        'name': 'Sugar',
        'amount': 2.5,
        'unit': 'cups',
      };

      final ingredient = Ingredient.fromJson(json);

      expect(ingredient.name, 'Sugar');
      expect(ingredient.amount, 2.5);
      expect(ingredient.unit, 'cups');
    });

    test('fromJson handles missing fields', () {
      final json = {
        'name': 'Flour',
      };

      final ingredient = Ingredient.fromJson(json);

      expect(ingredient.name, 'Flour');
      expect(ingredient.amount, 0.0);
      expect(ingredient.unit, '');
    });
  });

  group('Recipe', () {
    test('fromJson creates a Recipe from valid JSON', () {
      final json = {
        'id': 1,
        'title': 'Pancakes',
        'image': 'image_url',
        'usedIngredients': [
          {'name': 'Flour', 'amount': 2.0, 'unit': 'cups'},
        ],
        'missedIngredients': [
          {'name': 'Milk', 'amount': 1.0, 'unit': 'cup'},
        ],
        'sourceUrl': 'source_url',
        'summary': 'Delicious pancakes',
        'instructions': 'Mix ingredients and cook.',
      };

      final recipe = Recipe.fromJson(json);

      expect(recipe.id, 1);
      expect(recipe.title, 'Pancakes');
      expect(recipe.imageUrl, 'image_url');
      expect(recipe.ingredients.length, 2);
      expect(recipe.ingredients[0].name, 'Flour');
      expect(recipe.ingredients[1].name, 'Milk');
      expect(recipe.sourceUrl, 'source_url');
      expect(recipe.summary, 'Delicious pancakes');
      expect(recipe.instructions, 'Mix ingredients and cook.');
    });

    test('fromJson handles missing fields', () {
      final json = {
        'id': 2,
        'title': 'Omelette',
      };

      final recipe = Recipe.fromJson(json);

      expect(recipe.id, 2);
      expect(recipe.title, 'Omelette');
      expect(recipe.imageUrl, '');
      expect(recipe.ingredients.length, 0);
      expect(recipe.sourceUrl, '');
      expect(recipe.summary, 'No summary available.');
      expect(recipe.instructions, 'No instructions available.');
    });

    test('toMap converts a Recipe to a map', () {
      final recipe = Recipe(
        id: 1,
        title: 'Pancakes',
        imageUrl: 'image_url',
        ingredients: [
          Ingredient(name: 'Flour', amount: 2.0, unit: 'cups'),
          Ingredient(name: 'Milk', amount: 1.0, unit: 'cup'),
        ],
        sourceUrl: 'source_url',
        summary: 'Delicious pancakes',
        instructions: 'Mix ingredients and cook.',
      );

      final map = recipe.toMap();

      expect(map['id'], 1);
      expect(map['title'], 'Pancakes');
      expect(map['image'], 'image_url');
      expect(map['ingredients'].length, 2);
      expect(map['ingredients'][0]['name'], 'Flour');
      expect(map['ingredients'][1]['name'], 'Milk');
      expect(map['sourceUrl'], 'source_url');
      expect(map['summary'], 'Delicious pancakes');
    });
  });
}
