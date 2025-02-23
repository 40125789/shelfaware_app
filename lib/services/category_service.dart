import 'package:cloud_firestore/cloud_firestore.dart';



class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch the filter options (food categories) from Firestore
  Future<List<String>> getFilterOptions() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('categories').get();
      List<String> categories = snapshot.docs.map((doc) {
        final foodType = doc['Food Type']?.toString();
        return foodType ?? '';
      }).toList();
      
      categories.removeWhere((category) => category.isEmpty);
      return categories;
    } catch (e) {
      throw Exception('Error fetching filter options: $e');
    }
  }
}

