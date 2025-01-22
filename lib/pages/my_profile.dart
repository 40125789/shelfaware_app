import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  final String userId;

  ProfilePage({required this.userId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController _bioController = TextEditingController();
  TextEditingController _goalsController = TextEditingController();
  TextEditingController _cityController = TextEditingController();
  bool _isEditingBio = false;
  bool _isEditingGoals = false;
  bool _isEditingCity = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('My Profile'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return Center(child: Text('User not found.'));
            }

            var userData = snapshot.data!.data() as Map<String, dynamic>;

            DateTime joinDate = (userData['joinDate'] as Timestamp).toDate();
            String profileImageUrl = userData['profileImageUrl'] ?? '';
            double? rating = userData['averageRating'];
            int reviewCount = userData['reviewCount'] ?? 0;
            String city = userData['city'] ?? '';

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Centered the content
                children: [
                  SizedBox(height: 40),

                  // Profile Image and Rating in center
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final pickedFile = await picker.pickImage(
                              source: ImageSource.gallery);

                          if (pickedFile != null) {
                            try {
                              final storageRef = FirebaseStorage.instance
                                  .ref()
                                  .child(
                                      'user_profile_images/${widget.userId}.jpg');
                              final uploadTask =
                                  storageRef.putFile(File(pickedFile.path));
                              final snapshot =
                                  await uploadTask.whenComplete(() {});
                              final downloadUrl =
                                  await snapshot.ref.getDownloadURL();

                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(widget.userId)
                                  .update({
                                'profileImageUrl': downloadUrl,
                              });

                              setState(() {
                                profileImageUrl = downloadUrl;
                              });
                            } catch (e) {
                              debugPrint('Error updating profile image: $e');
                            }
                          }
                        },
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: profileImageUrl.isNotEmpty
                                  ? NetworkImage(profileImageUrl)
                                  : AssetImage('assets/default_avatar.png')
                                      as ImageProvider,
                              fit: BoxFit.cover,
                            ),
                            border: Border.all(
                              color: Colors.white,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (rating != null)
                        Positioned(
                          bottom: 1,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.yellow,
                                  size: 18,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 10),

                  // Review Count in center
                  Text(
                    reviewCount > 0 ? '$reviewCount Reviews' : 'No reviews',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 20),

                  // Full Name in center
                  Text(
                    '${userData['firstName']} ${userData['lastName']}',
                    style: TextStyle(
                      fontSize: 26,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),

                  // Join Date with smaller icon and text, aligned in center
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Colors.grey[700],
                        size: 16, // Smaller icon size
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Joined ${_formatJoinDate(userData['joinDate'])}',
                        style: TextStyle(
                          fontSize: 16, // Smaller font size
                          fontWeight: FontWeight.normal,
                          color: Colors.grey[700],
                        ),
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
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  SizedBox(height: 10),

                  // Editable Bio Container
                  Row(
                    children: [
                      // Bio Text
                      Expanded(
                        child: _isEditingBio
                            ? TextField(
                                controller: _bioController
                                  ..text = userData['bio'] ?? '',
                                decoration: InputDecoration(
                                  hintText: 'Add a description to your bio...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide(
                                        color: Colors.green, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: EdgeInsets.all(10),
                                ),
                                maxLines: 3,
                              )
                            : Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  userData['bio'] ?? 'No bio available.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                      ),

                      // Edit Bio Icon
                      IconButton(
                        icon: Icon(
                          _isEditingBio ? Icons.check : Icons.edit,
                          color: Colors.green,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_isEditingBio) {
                              if (_bioController.text.isNotEmpty) {
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(widget.userId)
                                    .update({
                                  'bio': _bioController.text,
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Profile updated successfully!')),
                                );
                              }
                            }
                            _isEditingBio = !_isEditingBio;
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Goals Label (Smaller font size and better spacing)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Goals',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  SizedBox(height: 10),

                  // Editable Goals Container
                  Row(
                    children: [
                      // Goals Text
                      Expanded(
                        child: _isEditingGoals
                            ? TextField(
                                controller: _goalsController
                                  ..text = userData['goals'] ?? '',
                                decoration: InputDecoration(
                                  hintText: 'Add your goals...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide(
                                        color: Colors.green, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: EdgeInsets.all(10),
                                ),
                                maxLines: 3,
                              )
                            : Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  userData['goals'] ?? 'No goals available.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                      ),

                      // Edit Goals Icon
                      IconButton(
                        icon: Icon(
                          _isEditingGoals ? Icons.check : Icons.edit,
                          color: Colors.green,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_isEditingGoals) {
                              if (_goalsController.text.isNotEmpty) {
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(widget.userId)
                                    .update({
                                  'goals': _goalsController.text,
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('Goals updated successfully!')),
                                );
                              }
                            }
                            _isEditingGoals = !_isEditingGoals;
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // City Label with smaller font size and icon
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_city,
                          color: Colors.grey[700],
                          size: 16, // Smaller icon size
                        ),
                        SizedBox(width: 8),
                        Text(
                          'City',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),

                  // Editable City Container
                  Row(
                    children: [
                      // City Text
                      Expanded(
                        child: _isEditingCity
                            ? TextField(
                                controller: _cityController..text = city,
                                decoration: InputDecoration(
                                  hintText: 'Enter your city...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide(
                                        color: Colors.green, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: EdgeInsets.all(10),
                                ),
                              )
                            : Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  city.isNotEmpty ? city : 'No city available.',
                                  style: TextStyle(
                                    fontSize:
                                        14, // Smaller font size for city text
                                    color: Colors.grey[700],
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                      ),

                      // Edit City Icon
                      IconButton(
                        icon: Icon(
                          _isEditingCity ? Icons.check : Icons.edit,
                          color: Colors.green,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_isEditingCity) {
                              if (_cityController.text.isNotEmpty) {
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(widget.userId)
                                    .update({
                                  'city': _cityController.text,
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('City updated successfully!')),
                                );
                              }
                            }
                            _isEditingCity = !_isEditingCity;
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatJoinDate(Timestamp joinDate) {
    // Convert the Timestamp to DateTime
    DateTime date = joinDate.toDate();

    // Use DateFormat to format the date as "Month Year" (e.g., "January 2025")
    return DateFormat('MMMM yyyy').format(date);
  }
}
