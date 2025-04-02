// user_data.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UserData {
  final String firstName;
  final String lastName;
  final String profileImageUrl;
  String bio;
  final DateTime joinDate;
  final double? averageRating;
  final int reviewCount;

  UserData({
    required this.firstName,
    required this.lastName,
    required this.profileImageUrl,
    required this.bio,
    required this.joinDate,
    this.averageRating,
    required this.reviewCount,
  });

  // Factory constructor to create a UserData instance from a Firestore document
  factory UserData.fromFirestore(Map<String, dynamic> data) {
    return UserData(
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      profileImageUrl: data['profileImageUrl'] ?? '',
      bio: data['bio'] ?? '',
      joinDate: (data['joinDate'] as Timestamp).toDate(),
      averageRating: data['averageRating']?.toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
    );
  }

  // Method to convert UserData instance to a map (for Firestore updates)
  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'joinDate': Timestamp.fromDate(joinDate),
      'averageRating': averageRating,
      'reviewCount': reviewCount,
    };
  }

 

  String _formatJoinDate() {
    return DateFormat('MMMM yyyy').format(joinDate);
  }
}
