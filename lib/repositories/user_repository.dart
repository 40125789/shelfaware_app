import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class UserRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  UserRepository({required this.firestore, required this.auth});


  Future<Map<String, dynamic>> getUserData(String userId) async {
    DocumentSnapshot userDoc = await firestore.collection('users').doc(userId).get();
    return userDoc.data() as Map<String, dynamic>;
  }

  Future<double?> fetchDonorRating(String donorId) async {
    try {
      DocumentSnapshot userDoc = await firestore.collection('users').doc(donorId).get();
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

     Future<void> updateUserBio(String userId, String newBio) async {
                    try {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .update({'bio': newBio});
                    } catch (e) {
                      print('Error updating user bio: $e');
                      throw e;
                    }
                  }
                  

  Future<String?> fetchProfileImageUrl(String userId) async {
    try {
      DocumentSnapshot userDoc = await firestore.collection('users').doc(userId).get();
      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;
        return data['profileImageUrl'] ?? '';
      }
    } catch (e) {
      print('Error fetching profile image URL: $e');
    }
    return null;
  }

  Future<String> fetchDonorProfileImageUrl(String userId) async {
    try {
      DocumentSnapshot userDoc = await firestore.collection('users').doc(userId).get();
      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;
        return data['profileImageUrl'] ?? '';
      }
    } catch (e) {
      print('Error fetching profile image URL: $e');
    }
    return ''; // Return empty string if no image found
  }
}