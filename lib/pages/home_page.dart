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
import 'package:shelfaware_app/pages/add_food_item.dart'; // Import the add_food_item page
import 'package:shelfaware_app/models/food_category.dart';
import 'package:shelfaware_app/models/food_category_icons.dart';
import 'package:shelfaware_app/components/expiry_icon.dart'; // Import the expiry icon component


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
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('categories').get();
      List<String> categories = snapshot.docs.map((doc) {
        final foodType = doc['Food Type'];
        print('Fetched Food Type: $foodType'); // Debugging output
        return foodType?.toString() ?? ''; // Ensure safety against null
      }).toList();

      // Remove empty strings if any
      categories.removeWhere((category) => category.isEmpty);

      setState(() {
        filterOptions = ['All', ...categories];
      });
    } catch (e) {
      print('Error fetching filter options: $e');
    }
  }

  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }


  // Updated formatDate function to show "Expires in X days" format
  String formatDate(Timestamp expiryTimestamp) {
    DateTime expiryDate = expiryTimestamp.toDate();
    DateTime today = DateTime.now();
    int daysDifference = expiryDate.difference(today).inDays;

    if (daysDifference < 0) {
      return "Expired";
    } else if (daysDifference == 0) {
      return "Expires today";
    } else {
      return "Expires in $daysDifference days";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopAppBar(
        title: 'Inventory',
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
                FilterDropdown(
                  selectedFilter: selectedFilter,
                  filterOptions: filterOptions,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedFilter = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('foodItems').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(child: Text('Error fetching food items'));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No food items found'));
                      }

                      final filteredItems = selectedFilter == 'All'
                          ? snapshot.data!.docs
                          : snapshot.data!.docs.where((doc) {
                              return doc['category'] == selectedFilter;
                            }).toList();

                      if (filteredItems.isEmpty) {
                        return const Center(child: Text('No food items match the selected filter.'));
                      }

                      return ListView(
  children: filteredItems.map((document) {
    final data = document.data() as Map<String, dynamic>;
    final expiryTimestamp = data['expiryDate'] as Timestamp;

    // Get the food category from the "foodItems" collection
    String? fetchedFoodType = data['category'];
    FoodCategory foodCategory;

    if (fetchedFoodType != null) {
      foodCategory = FoodCategory.values.firstWhere(
        (e) => e.toString().split('.').last == fetchedFoodType,
        orElse: () => FoodCategory.values.first, // Default category if not found
      );
    } else {
      foodCategory = FoodCategory.values.first; // Default category if no type is present
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: SizedBox(
          width: 40, // Adjust as necessary
          height: 40, // Adjust as necessary
          child: Icon(FoodCategoryIcons.getIcon(foodCategory)), // Displaying the icon
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                data['productName'] ?? 'No Name',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        subtitle: Text(
          "Quantity: ${data['quantity']}\n${formatDate(expiryTimestamp)}", // Showing quantity and expiry date
        ),
        trailing: SizedBox(
          width: 60, // Adjust as necessary
          height: 60, // Adjust as necessary
          child: ExpiryIcon(expiryTimestamp: expiryTimestamp), // Displaying the expiry icon
        ),
      ),
    );
  }).toList(),
);

                    },
                  ),
                ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddFoodItem()),
          );
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.green,
        elevation: 6.0, // Adds shadow to the button
        shape: const CircleBorder(), // Change to a circular button
      ),
    );
  }
}
