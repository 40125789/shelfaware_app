import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FilterStateNotifier extends StateNotifier<String> {
  FilterStateNotifier() : super('All'); // Default to 'All'

  void setFilter(String filter) {
    state = filter;
  }
}

final filterStateProvider = StateNotifierProvider<FilterStateNotifier, String>((ref) {
  return FilterStateNotifier();
});


final filterOptionsProvider = FutureProvider<List<String>>((ref) async {
  try {
    final snapshot = await FirebaseFirestore.instance.collection('categories').get();
    List<String> categories = snapshot.docs.map((doc) {
      final foodType = doc['Food Type'];
      return foodType?.toString() ?? '';
    }).toList();
    categories.removeWhere((category) => category.isEmpty);
    return ['All', ...categories];
  } catch (e) {
      throw Exception('Error fetching filter options: $e');
    }
  });