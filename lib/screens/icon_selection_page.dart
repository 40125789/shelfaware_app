import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IconSelectionScreen extends StatefulWidget {
  @override
  _IconSelectionScreenState createState() => _IconSelectionScreenState();
}

class _IconSelectionScreenState extends State<IconSelectionScreen> {
  late Future<List<Map<String, String>>> iconUrls;
  String? selectedIconUrl; // To store the selected icon URL locally

  @override
  void initState() {
    super.initState();
    iconUrls = fetchIcons();
    checkUserAuthentication();
  }

  // Check if the user is authenticated
  Future<void> checkUserAuthentication() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User is not authenticated');
      // You can show a sign-in prompt here if necessary
    }
  }

  // Fetch the icons from Firestore
  Future<List<Map<String, String>>> fetchIcons() async {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('icons').get();
    List<Map<String, String>> icons = [];
    querySnapshot.docs.forEach((doc) {
      icons.add({
        'url': doc['url'],
        'name': doc['name'],  // Optional: if you want to display the name
      });
    });
    return icons;
  }

  // Handle icon selection
  void _selectIcon(Map<String, String> icon) async {
    // Optimistic UI update: Immediately reflect the selected icon
    setState(() {
      selectedIconUrl = icon['url']; // Update the selected icon locally
    });

    // Get the current user ID
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Update Firestore in the background
      await _updateUserProfileWithIcon(user.uid, icon['url']!);

      // Optionally, show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile icon updated!')),
      );

      // Close the screen after selection
      Navigator.pop(context);
    } else {
      // Handle the case where the user is not authenticated
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to select an icon.')),
      );
    }
  }

  // Update the user's profile with the selected icon
  Future<void> _updateUserProfileWithIcon(String userId, String iconUrl) async {
    DocumentReference userRef =
        FirebaseFirestore.instance.collection('users').doc(userId);
    await userRef.update({
      'profileImageUrl': iconUrl,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Profile Icon'),
      ),
      body: FutureBuilder<List<Map<String, String>>>( 
        future: iconUrls,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No icons available.'));
          }

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // 3 columns
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              Map<String, String> icon = snapshot.data![index];
              return GestureDetector(
                onTap: () {
                  _selectIcon(icon); // Select icon and update the profile
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: Image.network(
                    icon['url']!, // Load the image from Firestore URL
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}


