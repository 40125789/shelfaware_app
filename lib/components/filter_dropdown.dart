// filter_dropdown.dart
import 'package:flutter/material.dart';
import 'package:shelfaware_app/models/food_category.dart';
import 'package:shelfaware_app/models/food_category_icons.dart';

import 'package:flutter/material.dart';
import 'package:shelfaware_app/models/food_category.dart';
import 'package:shelfaware_app/models/food_category_icons.dart';

class FilterDropdown extends StatelessWidget {
  final String selectedFilter;
  final List<String> filterOptions;
  final ValueChanged<String?> onChanged;

  const FilterDropdown({
    Key? key,
    required this.selectedFilter,
    required this.filterOptions,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: selectedFilter,
      onChanged: onChanged,
      items: filterOptions.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Row(
            children: [
              Icon(_getIconForCategory(value)),
              const SizedBox(width: 8),
              Text(value),
            ],
          ),
        );
      }).toList(),
    );
  }

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