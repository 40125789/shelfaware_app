import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shelfaware_app/components/bottom_navigation_bar.dart';
import 'package:shelfaware_app/components/side_drawer_menu.dart'; 
import 'package:shelfaware_app/components/top_app_bar.dart';
import 'package:shelfaware_app/components/filter_dropdown.dart'; // Import the new component
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
  String selectedFilter = 'All'; // State for the filter
  List<String> filterOptions = ['All']; // Default value to show

  @override
  void initState() {
    super.initState();
    getUserData();
    _pageController = PageController();
    _fetchFilterOptions(); // Fetch filter options from Firestore
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> getUserData() async {
    try {
      QueryDocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: user.email)
          .get()
          .then((snapshot) => snapshot.docs.first);

      setState(() {
        firstName = userDoc['firstName'];
        lastName = userDoc['lastName'];
      });
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  // Function to fetch filter options (categories) from Firestore
  Future<void> _fetchFilterOptions() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('categories') // Assuming 'categories' is the collection
          .get();

      // Map through the documents and get the 'Food Type' field
      List<String> categories = snapshot.docs.map((doc) {
        return doc['Food Type'].toString();
      }).toList();
      
      setState(() {
        filterOptions = ['All', ...categories]; // Add 'All' at the beginning
      });
    } catch (e) {
      print('Error fetching filter options: $e');
    }
  }

  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopAppBar(
        onLocationPressed: () {},
        onNotificationPressed: () {},
        onMessagePressed: () {},
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
                // Use the FilterDropdown component
                FilterDropdown(
                  selectedFilter: selectedFilter,
                  filterOptions: filterOptions,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedFilter = newValue!;
                    });
                    // Optionally, implement filtering logic based on selected category
                  },
                ),
                const SizedBox(height: 20),
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
