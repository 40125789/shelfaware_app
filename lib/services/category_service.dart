import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryService {
  final FirebaseFirestore firestore;

  CategoryService({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  // Fetch the filter options (food categories) from Firestore
  Future<List<String>> getFilterOptions() async {
    try {
      QuerySnapshot snapshot = await firestore.collection('categories').get();
      // Use safe access: doc.data() might be null if the document has no data.
      List<String> categories = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?; 
        final foodType = data?['Food Type']?.toString().trim() ?? '';
        return foodType;
      }).toList();

      // Remove empty strings
      categories.removeWhere((category) => category.isEmpty);
      return categories;
    } catch (e) {
      throw Exception('Error fetching filter options: $e');
    }
  }
}

