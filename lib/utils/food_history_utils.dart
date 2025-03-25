import 'package:intl/intl.dart';
import 'package:shelfaware_app/models/food_history.dart';

void sortFoodHistoryItems(List<FoodHistory> foodItems, bool isNewestToOldest) {
  foodItems.sort((a, b) {
    return isNewestToOldest
        ? b.updatedOn.compareTo(a.updatedOn)
        : a.updatedOn.compareTo(b.updatedOn);
  });
}

List<FoodHistory> filterFoodHistoryItems(
    List<FoodHistory> foodItems, String filterOption) {
  if (filterOption == 'Show Consumed') {
    return foodItems.where((item) => item.status == 'consumed').toList();
  } else if (filterOption == 'Show Discarded') {
    return foodItems.where((item) => item.status == 'discarded').toList();
  } else {
    return foodItems; // Show all items if no specific filter is applied
  }
}

Map<String, List<FoodHistory>> groupFoodHistoryItemsByMonth(
    List<FoodHistory> foodItems) {
  Map<String, List<FoodHistory>> groupedItems = {};

  for (var foodItem in foodItems) {
    String monthYear =
        DateFormat('MMMM yyyy').format(foodItem.updatedOn.toDate());
    if (!groupedItems.containsKey(monthYear)) {
      groupedItems[monthYear] = [];
    }
    groupedItems[monthYear]!.add(foodItem);
  }

  return groupedItems;
}
