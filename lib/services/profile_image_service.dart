import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProfileImage extends StatefulWidget {
  final String donorId;
  final String userId;

  ProfileImage({required this.donorId, required this.userId});

  @override
  _ProfileImageState createState() => _ProfileImageState();
}

class _ProfileImageState extends State<ProfileImage> {
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchProfileImage();
  }

    Future<void> _fetchProfileImage() async {
    // Fetch the donor's profile image URL from Firestore or Firebase Storage
    var userData = await FirebaseFirestore.instance.collection('users').doc(widget.donorId).get();
    if (userData.exists) {
      if (mounted) {
        setState(() {
          profileImageUrl = userData['profileImageUrl']; // Make sure this field exists in Firestore
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator while fetching the profile image
    if (profileImageUrl == null) {
      return CircleAvatar(
        radius: 20,
        child: CircularProgressIndicator(),
      );
    }

    // Show the profile image or a default icon if it's not available
    return CircleAvatar(
      backgroundImage: profileImageUrl != null && profileImageUrl!.isNotEmpty
          ? NetworkImage(profileImageUrl!)
          : null,
      radius: 20,
      child: profileImageUrl == null || profileImageUrl!.isEmpty
          ? Icon(Icons.account_circle, size: 40)
          : null, // Default icon if no image available
    );
  }
}
