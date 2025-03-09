import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shelfaware_app/components/editable_bio.dart';
import 'package:shelfaware_app/components/review_section.dart';
import 'package:shelfaware_app/models/user_model.dart';

class ProfilePage extends StatefulWidget {
  final String userId;

  ProfilePage({required this.userId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController _bioController = TextEditingController();
  bool _isEditingBio = false;
  String? loggedInUserId;
  UserData? userData;
  bool isImageLoading = true; // Track image loading state

  @override
  void initState() {
    super.initState();
    _fetchLoggedInUserId();
    _fetchUserData();
  }

  Future<void> _fetchLoggedInUserId() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        loggedInUserId = user.uid;
      });
    }
  }

  Future<void> _fetchUserData() async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
    setState(() {
      userData =
          UserData.fromFirestore(snapshot.data() as Map<String, dynamic>);
      isImageLoading =
          false; // After loading user data, set image loading state to false
    });
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return Scaffold(
        appBar: AppBar(title: Text('My Profile')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('My Profile')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 40),

              // Profile Image and Rating
              Stack(
                alignment: Alignment.center,
                children: [
                  GestureDetector(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: userData!.profileImageUrl.isNotEmpty
                              ? Image.network(
                                  userData!.profileImageUrl,
                                  errorBuilder: (BuildContext context,
                                      Object error, StackTrace? stackTrace) {
                                    return Image.asset(
                                        'assets/default_avatar.png');
                                  },
                                ).image
                              : AssetImage('assets/default_avatar.png')
                                  as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 2),
                        ],
                      ),
                    ),
                  ),
                  if (isImageLoading)
                    Positioned(child: CircularProgressIndicator()),
                  if (userData!.averageRating != null)
                    Positioned(
                      bottom: 1,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.star, color: Colors.yellow, size: 18),
                            SizedBox(width: 4),
                            Text(
                              userData!.averageRating?.toStringAsFixed(1) ??
                                  '0.0',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 10),

              // Review Count
              Text(
                userData!.reviewCount > 0
                    ? '${userData!.reviewCount} Reviews'
                    : 'No reviews',
                style: TextStyle(fontSize: 12, color: Colors.grey[800]),
              ),
              SizedBox(height: 20),

              // Full Name
              Text(
                '${userData!.firstName} ${userData!.lastName}',
                style: TextStyle(
                    fontSize: 26,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),

              // Join Date
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, color: Colors.grey[700], size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Joined ${_formatJoinDate(userData!.joinDate)}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // About Me Label
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'About Me',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700]),
                ),
              ),
              SizedBox(height: 10),

              // Editable Bio Container with fixed height
              EditableBio(
                initialBio: userData!.bio,
                onBioChanged: (newBio) {
                  setState(() {
                    userData!.bio = newBio;
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.userId)
                        .update({'bio': newBio});
                  });
                },
              ),
              SizedBox(height: 20),

              // Reviews Section
              if (loggedInUserId != null)
                ReviewSection(loggedInUserId: loggedInUserId!),
            ],
          ),
        ),
      ),
    );
  }

  String _formatJoinDate(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }
}
