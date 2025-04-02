import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shelfaware_app/components/editable_bio.dart';
import 'package:shelfaware_app/components/review_section.dart';
import 'package:shelfaware_app/models/user_model.dart';
import 'package:shelfaware_app/repositories/user_repository.dart';
import 'package:shelfaware_app/services/user_service.dart';

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
  bool isImageLoading = true;
  final UserRepository _userRepository = UserRepository(firestore: FirebaseFirestore.instance, auth: FirebaseAuth.instance);
  late final UserService _userService;

  @override
  void initState() {
    super.initState();
    _userService = UserService(_userRepository);
    _fetchLoggedInUserId();
    _fetchUserData();
  }

  Future<void> _fetchLoggedInUserId() async {
    String? userId = await FirebaseAuth.instance.currentUser?.uid;
    // Check if the logged-in user ID is the same as the profile being viewed
    if (userId != null) {
      setState(() {
        loggedInUserId = userId;
      });
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final userMap = await _userService.getUserData(widget.userId);
      setState(() {
        userData = UserData.fromFirestore(userMap);
        // Set the initial bio in the controller
        _bioController.text = userData!.bio;
        // Set the image loading state to false after fetching data
        isImageLoading = false;
      });
    } catch (e) {
      setState(() {
        isImageLoading = false;
      });
      print('Error fetching user data: $e');
    }
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
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            spreadRadius: 2),
                      ],
                      color: Colors.grey[200], // Placeholder color
                    ),
                    child: ClipOval(
                      child: userData!.profileImageUrl.isNotEmpty
                          ? FadeInImage.assetNetwork(
                              placeholder: 'assets/default_avatar.png',
                              image: userData!.profileImageUrl,
                              fit: BoxFit.cover,
                              fadeInDuration: Duration(milliseconds: 300),
                              imageErrorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/default_avatar.png',
                                  fit: BoxFit.cover,
                                );
                              },
                            )
                          : Image.asset(
                              'assets/default_avatar.png',
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  if (isImageLoading)
                    Positioned(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.3),
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    ),
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
                onBioChanged: (newBio) async {
                  await _userService.updateUserBio(widget.userId, newBio);
                  setState(() {
                    userData!.bio = newBio;
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
