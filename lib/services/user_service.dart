import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth = FirebaseFirestore.instance;

  static Future<Map<String, dynamic>> getUserData(String userId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    return userDoc.data() as Map<String, dynamic>;
  }

   Future<double?> fetchDonorRating(String donorId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(donorId).get();
      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;
        var rating = data['averageRating'];
        if (rating != null) {
          return rating.toDouble();
        }
      }
    } catch (e) {
      print('Error fetching donor rating: $e');
    }
    return null;
  }

  Future<String?> fetchProfileImageUrl(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;
        return data['profileImageUrl'] ?? '';
      }
    } catch (e) {
      print('Error fetching profile image URL: $e');
    }
    return null;
  }
}




