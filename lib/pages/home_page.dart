import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser!;
  String firstName = '';

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  // Fetch user data from Firestore
  Future<void> getUserData() async {
    QueryDocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: user.email)
        .get()
        .then((snapshot) => snapshot.docs.first);

    setState(() {
      firstName = userDoc['firstName']; // Get the first name from Firestore
    });
  }

  // SIGN USER OUT
  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(onPressed: signUserOut, icon: const Icon(Icons.logout)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.0),
          ),
        ],
      ),
      bottomNavigationBar: GNav(
        activeColor: Colors.green,
        iconSize: 24,
        gap: 8,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        onTabChange: (index) {
          print(index);
        },
        tabs: [
          GButton(
            icon: Icons.home,
            text: 'Home',
            iconColor: Colors.grey,
            textColor: Colors.green,
          ),
          GButton(
            icon: Icons.list,
            text: 'Inventory',
            iconColor: Colors.grey,
            textColor: Colors.green,
          ),
          GButton(
            icon: Icons.favorite_border_outlined,
            text: 'Recipes',
            iconColor: Colors.grey,
            textColor: Colors.green,
          ),
          GButton(
            icon: Icons.location_on,
            text: 'Donations',
            iconColor: Colors.grey,
            textColor: Colors.green,
          ),
          GButton(
            icon: Icons.bar_chart,
            text: 'Statistics',
            iconColor: Colors.grey,
            textColor: Colors.green,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message
            Text(
              "Welcome, $firstName!",
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Inventory card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.list, size: 40, color: Colors.green),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("Inventory", style: TextStyle(fontSize: 24)),
                        Text("Check your food items",
                            style: TextStyle(fontSize: 16)),
                      ],
                    ),
                    const Icon(Icons.arrow_forward, size: 30),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Expiring soon card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.warning, size: 40, color: Colors.red),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("Items Expiring Soon",
                            style: TextStyle(fontSize: 24)),
                        Text("3 items need your attention",
                            style: TextStyle(fontSize: 16)),
                      ],
                    ),
                    const Icon(Icons.arrow_forward, size: 30),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
