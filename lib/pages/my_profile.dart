import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchLoggedInUserId();
  }

  Future<void> _fetchLoggedInUserId() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        loggedInUserId = user.uid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Profile')),
      body: SingleChildScrollView(
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(widget.userId).get(),
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

            return Padding(
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
                        onTap: _updateProfileImage,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: profileImageUrl.isNotEmpty
                                  ? NetworkImage(profileImageUrl)
                                  : AssetImage('assets/default_avatar.png') as ImageProvider,
                              fit: BoxFit.cover,
                            ),
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, spreadRadius: 2),
                            ],
                          ),
                        ),
                      ),
                      if (rating != null)
                        Positioned(
                          bottom: 1,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.star, color: Colors.yellow, size: 18),
                                SizedBox(width: 4),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
                    reviewCount > 0 ? '$reviewCount Reviews' : 'No reviews',
                    style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                  ),
                  SizedBox(height: 20),

                  // Full Name
                  Text(
                    '${userData['firstName']} ${userData['lastName']}',
                    style: TextStyle(fontSize: 26, color: Colors.grey[700], fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),

                  // Join Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey[700], size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Joined ${_formatJoinDate(userData['joinDate'])}',
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
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                    ),
                  ),
                  SizedBox(height: 10),

                  // Editable Bio Container
                  Row(
                    children: [
                      Expanded(
                        child: _isEditingBio
                            ? TextField(
                                controller: _bioController..text = userData['bio'] ?? '',
                                decoration: InputDecoration(
                                  hintText: 'Add a description to your bio...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
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
                                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                ),
                              ),
                      ),
                      IconButton(
                        icon: Icon(_isEditingBio ? Icons.check : Icons.edit, color: Colors.green),
                        onPressed: _toggleBioEditing,
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Reviews Section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Reviews left by others',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                    ),
                  ),
                  SizedBox(height: 10),

                  // Reviews List
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('reviews').where('donorId', isEqualTo: loggedInUserId).snapshots(),
                    builder: (context, reviewSnapshot) {
                      if (reviewSnapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (!reviewSnapshot.hasData || reviewSnapshot.data!.docs.isEmpty) {
                        return Center(child: Text('No reviews yet.'));
                      }

                      var reviews = reviewSnapshot.data!.docs;
                     return ListView.builder(
  shrinkWrap: true,
  physics: NeverScrollableScrollPhysics(),
  itemCount: reviews.length,
  itemBuilder: (context, index) {
    var reviewData = reviews[index].data() as Map<String, dynamic>;
    String reviewerId = reviewData['reviewerId'];
    String comment = reviewData['comment'];
    double communicationRating = reviewData['communicationRating'];
    double foodItemRating = reviewData['foodItemRating'];
    double donationProcessRating = reviewData['donationProcessRating'];
    Timestamp reviewTimestamp = reviewData['timestamp'];

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(reviewerId).get(),
      builder: (context, reviewerSnapshot) {
        if (reviewerSnapshot.connectionState == ConnectionState.waiting) {
          return SizedBox.shrink();
        }

        var reviewerData = reviewerSnapshot.data?.data() as Map<String, dynamic>;
        String reviewerName = '${reviewerData?['firstName']}';
        String reviewerProfileImage = reviewerData?['profileImageUrl'] ?? '';
        DateTime reviewDate = reviewTimestamp.toDate();

        return Card(
          margin: EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: reviewerProfileImage.isNotEmpty
                  ? NetworkImage(reviewerProfileImage)
                  : AssetImage('assets/default_avatar.png') as ImageProvider,
            ),
            title: Text(
              '$reviewerName on ${DateFormat('dd MMM yyyy').format(reviewDate)}',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
            
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Communication Rating with star after the field name
                Row(
                  children: [
                    Text('Communication: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Icon(Icons.star, color: Colors.yellow, size: 16),
                    Text('${communicationRating.toStringAsFixed(1)}'),
                  ],
                ),
                SizedBox(height: 5),
                
                // Food Item Rating with star after the field name
                Row(
                  children: [
                    Text('Food Quality: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Icon(Icons.star, color: Colors.yellow, size: 16),
                    Text('${foodItemRating.toStringAsFixed(1)}'),
                  ],
                ),
                SizedBox(height: 5),
                
                // Donation Process Rating with star after the field name
                Row(
                  children: [
                    Text('Pickup Process: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Icon(Icons.star, color: Colors.yellow, size: 16),
                    Text('${donationProcessRating.toStringAsFixed(1)}'),
                  ],
                ),
                SizedBox(height: 5),
                
                // Comment with quotation marks
                Text('"$comment"', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
              ],
            ),
          ),
        );
      },
    );
  },
);

                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatJoinDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return DateFormat('d MMM yyyy').format(date);
  }

  void _toggleBioEditing() {
    setState(() {
      if (_isEditingBio) {
        // Save bio if editing is done
        FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
          'bio': _bioController.text,
        });
      }
      _isEditingBio = !_isEditingBio;
    });
  }

  Future<void> _updateProfileImage() async {
    // Implement image picker here
    // Upload new image to Firebase Storage and update Firestore
  }
}
