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

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  TextEditingController _bioController = TextEditingController();
  bool _isEditingBio = false;
  String? loggedInUserId;
  UserData? userData;
  bool isImageLoading = true;
  final UserRepository _userRepository = UserRepository(firestore: FirebaseFirestore.instance, auth: FirebaseAuth.instance);
  late final UserService _userService;
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _userService = UserService(_userRepository);
    
    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );
    
    _fetchLoggedInUserId();
    _fetchUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _fetchLoggedInUserId() async {
    String? userId = await FirebaseAuth.instance.currentUser?.uid;
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
        _bioController.text = userData!.bio;
        isImageLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        isImageLoading = false;
      });
      print('Error fetching user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define green color that works in both dark and light mode
    final greenColor = Theme.of(context).brightness == Brightness.dark 
        ? Color(0xFF81C784) // Lighter green for dark mode
        : Color(0xFF2E7D32); // Darker green for light mode

    if (userData == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold, color: greenColor)),
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: greenColor,
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(greenColor),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold, color: greenColor)),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: greenColor,
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeInAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: child,
            ),
          );
        },
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 30),
                
                // Profile Image with Hero animation
                Hero(
                  tag: 'profile-${widget.userId}',
                  child: _buildProfileImage(greenColor),
                ),
                SizedBox(height: 10),
                
                // Star Rating (Moved below profile picture)
                if (userData!.averageRating != null)
                  TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 800),
                  curve: Interval(0.1, 0.9, curve: Curves.easeOut),
                  builder: (context, double value, child) {
                    return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - value)),
                      child: child,
                    ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                    color: Color(0xFFFFF9C4), // Light yellow background
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      spreadRadius: 0.5,
                      ),
                    ],
                    ),
                    child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 20),
                      SizedBox(width: 4),
                      Text(
                      userData!.averageRating?.toStringAsFixed(1) ?? '0.0',
                      style: TextStyle(
                        color: greenColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      ),
                    ],
                    ),
                  ),
                  ),
                SizedBox(height: 10),

                // Review Count
                AnimatedOpacity(
                  opacity: _animationController.value,
                  duration: Duration(milliseconds: 500),
                  child: Text(
                    userData!.reviewCount > 0
                        ? '${userData!.reviewCount} Reviews'
                        : 'No reviews yet',
                    style: TextStyle(
                      fontSize: 13, 
                      color: greenColor.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(height: 10),

                // Full Name
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 800),
                  curve: Curves.easeOut,
                  builder: (context, double value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    '${userData!.firstName} ${userData!.lastName}',
                    style: TextStyle(
                      fontSize: 28,
                      color: greenColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(height: 8),

                // Join Date
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 800),
                  curve: Interval(0.2, 1.0, curve: Curves.easeOut), // 200ms delay using Interval
                  builder: (context, double value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 15 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: greenColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today, color: greenColor, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Joined ${_formatJoinDate(userData!.joinDate)}',
                          style: TextStyle(
                            fontSize: 14, 
                            color: greenColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 30),

                // About Me Section
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 1100), // increased to include delay
                  curve: Interval(0.3, 1.0, curve: Curves.easeOut), // 300ms delay using Interval
                  builder: (context, double value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: greenColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'About Me',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: greenColor,
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      
                      // Editable Bio with animation
                      EditableBio(
                        initialBio: userData!.bio,
                        onBioChanged: (newBio) async {
                          await _userService.updateUserBio(widget.userId, newBio);
                          setState(() {
                            userData!.bio = newBio;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),

                // Reviews Section
                if (loggedInUserId != null)
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 800),
                    curve: Interval(0.4, 1.0, curve: Curves.easeOut), // 400ms delay using Interval
                    builder: (context, double value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 30 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: ReviewSection(loggedInUserId: loggedInUserId!),
                  ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage(Color greenColor) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                greenColor.withOpacity(0.7),
                greenColor.withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 2,
                offset: Offset(0, 5),
              ),
            ],
          ),
          padding: EdgeInsets.all(4),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
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
        ),
        if (isImageLoading)
          Positioned(
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.4),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatJoinDate(DateTime date) {
    return DateFormat('MMMM d, yyyy').format(date);
  }
}
