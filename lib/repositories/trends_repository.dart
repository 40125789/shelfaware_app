import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TrendsRepository {
 final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  TrendsRepository({required FirebaseAuth auth, required FirebaseFirestore firestore})
      : _auth = auth,
        _firestore = firestore;

  Future<List<Map<String, dynamic>>> fetchHistoryData(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('history')
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Error fetching history data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchDonations() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('donations').get();

      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Error fetching donations: $e');
    }
  }

  Future<String> fetchJoinDuration(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        return "Unknown duration";
      }

      Timestamp joinDate = userDoc['joinDate'];
      Duration duration = DateTime.now().difference(joinDate.toDate());

      if (duration.inDays > 0) {
        return "${duration.inDays} days";
      } else {
        return "${duration.inHours} hours";
      }
    } catch (e) {
      throw Exception('Error fetching join duration: $e');
    }
  }
}