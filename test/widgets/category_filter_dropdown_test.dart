import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfaware_app/components/category_filter_dropdown.dart';
import 'package:shelfaware_app/models/food_category.dart';
import 'package:shelfaware_app/models/food_category_icons.dart';

void main() {
  testWidgets('FilterDropdown displays correct initial value', (WidgetTester tester) async {
    const selectedFilter = 'dairy';
    const filterOptions = ['all', 'dairy', 'fish', 'frozen', 'fruits', 'grains', 'tinned', 'meat', 'vegetables', 'beverage'];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterDropdown(
            selectedFilter: selectedFilter,
            filterOptions: filterOptions,
            onChanged: (value) {},
          ),
        ),
      ),
    );

    expect(find.text(selectedFilter), findsOneWidget);
  });

  testWidgets('FilterDropdown calls onChanged when a new item is selected', (WidgetTester tester) async {
    const selectedFilter = 'dairy';
    const filterOptions = ['all', 'dairy', 'fish', 'frozen', 'fruits', 'grains', 'tinned', 'meat', 'vegetables', 'beverage'];
    String? changedValue;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterDropdown(
            selectedFilter: selectedFilter,
            filterOptions: filterOptions,
            onChanged: (value) {
              changedValue = value;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text(selectedFilter));
    await tester.pumpAndSettle();

    await tester.tap(find.text('fish').last);
    await tester.pumpAndSettle();

    expect(changedValue, 'fish');
  });


  IconData _getIconForCategory(String category) {
    if (category == 'all') {
      return Icons.category; // Default icon for "All" category
    }
    switch (category) {
      case 'dairy':
        return FoodCategoryIcons.getIcon(FoodCategory.dairy);
      case 'fish':
        return FoodCategoryIcons.getIcon(FoodCategory.fish);
      case 'frozen':
        return FoodCategoryIcons.getIcon(FoodCategory.frozen);
      case 'fruits':
        return FoodCategoryIcons.getIcon(FoodCategory.fruits);
      case 'grains':
        return FoodCategoryIcons.getIcon(FoodCategory.grains);
      case 'tinned':
        return FoodCategoryIcons.getIcon(FoodCategory.tinned);
      case 'meat':
        return FoodCategoryIcons.getIcon(FoodCategory.meat);
      case 'vegetables':
        return FoodCategoryIcons.getIcon(FoodCategory.vegetables);
      case 'beverage':
        return FoodCategoryIcons.getIcon(FoodCategory.beverage);
      default:
        return Icons.category; // Default icon for unknown categories
    }
  }


}