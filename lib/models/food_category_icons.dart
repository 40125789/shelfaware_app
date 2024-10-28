import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'food_category.dart';

class FoodCategoryIcons {
  // Mapping of FoodCategory to Font Awesome Icons
  static const Map<FoodCategory, IconData> categoryIcons = {
    FoodCategory.dairy: FontAwesomeIcons.cheese,       // Dairy products
    FoodCategory.fish: FontAwesomeIcons.fish,          // Fish
    FoodCategory.frozen: FontAwesomeIcons.snowflake,    // Frozen foods
    FoodCategory.fruits: FontAwesomeIcons.apple,    // Fruits
    FoodCategory.grains: FontAwesomeIcons.breadSlice,  // Grains
    FoodCategory.tinned: FontAwesomeIcons.prescriptionBottle, // Tinned foods
    FoodCategory.meat: FontAwesomeIcons.drumstickBite,      // Meat
    FoodCategory.vegetables: FontAwesomeIcons.carrot,   // Vegetables
  };

  // Method to get icon for food category
  static IconData getIcon(FoodCategory category) {
    return categoryIcons[category] ?? FontAwesomeIcons.utensils; // Default icon if no match found
  }
}
