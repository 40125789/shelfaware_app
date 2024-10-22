import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shelfaware_app/components/bottom_navigation_bar.dart';
import 'package:shelfaware_app/components/side_drawer_menu.dart'; // Import the new CustomDrawer
import 'package:shelfaware_app/controllers/bottom_nav_controller.dart';
import 'package:shelfaware_app/pages/recipes_page.dart';
import 'package:shelfaware_app/pages/donations_page.dart';
import 'package:shelfaware_app/pages/statistics_page.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String firstName = '';
  String lastName = '';
  final user = FirebaseAuth.instance.currentUser!;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    getUserData();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> getUserData() async {
    QueryDocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: user.email)
        .get()
        .then((snapshot) => snapshot.docs.first);

    setState(() {
      firstName = userDoc['firstName'];
      lastName = userDoc['lastName'];
    });
  }

  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        iconTheme: IconThemeData(color: Colors.grey[800]),
        actions: [

          IconButton(
          icon: Icon(Icons.location_on, color: Colors.grey[800]), // Location icon
          onPressed: () {
            // Define actions for location, e.g., showing user location or navigation
          },
        ),
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.grey[800]),
            onPressed: () {
              // Define actions for notifications
            },
          ),
          IconButton(
          icon: Icon(Icons.message, color: Colors.grey[800]), // Message icon
          onPressed: () {
            // Navigate to the Messages screen or define message-related actions
          },
        ),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 10.0)),
        ],
      ),

      drawer: CustomDrawer(
        firstName: firstName,
        lastName: lastName,
        onSignOut: signUserOut,

      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInventoryCard(),
                const SizedBox(height: 20),
                _buildExpiringSoonCard(),
                const SizedBox(height: 20),
              ],
            ),
          ),
          RecipesPage(),
          DonationsPage(),
          StatisticsPage(),
        ],
      ),
      bottomNavigationBar: Consumer<BottomNavController>(
        builder: (context, controller, child) {
          return BottomNavigationBarComponent(
            selectedIndex: controller.selectedIndex,
            onTabChange: (index) {
              controller.navigateTo(index);
              _pageController.jumpToPage(index);
            },
          );
        },
      ),
    );
  }

  Card _buildInventoryCard() {
    return Card(
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
                Text("Check your food items", style: TextStyle(fontSize: 16)),
              ],
            ),
            const Icon(Icons.arrow_forward, size: 30),
          ],
        ),
      ),
    );
  }

  Card _buildExpiringSoonCard() {
    return Card(
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
                Text("Items Expiring Soon", style: TextStyle(fontSize: 24)),
                Text("3 items need your attention", style: TextStyle(fontSize: 16)),
              ],
            ),
            const Icon(Icons.arrow_forward, size: 30),
          ],
        ),
      ),
    );
  }
}
