abstract class FoodRepository {
  Future<List<String>> fetchFilterOptions();
  Future<void> deleteFoodItem(String documentId);
  Future<List<String>> fetchUserIngredients(String userId);
  Future<List<Map<String, dynamic>>> getFoodHistory(String userId);
}