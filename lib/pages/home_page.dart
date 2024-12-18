import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shelfaware_app/components/bottom_navigation_bar.dart';
import 'package:shelfaware_app/components/calendar_view_widget.dart';
import 'package:shelfaware_app/components/side_drawer_menu.dart';
import 'package:shelfaware_app/components/top_app_bar.dart';
import 'package:shelfaware_app/components/filter_dropdown.dart'; // Import the new component
import 'package:shelfaware_app/controllers/bottom_nav_controller.dart';
import 'package:shelfaware_app/pages/recipes_page.dart';
import 'package:shelfaware_app/pages/favourites_page.dart';
import 'package:shelfaware_app/pages/donations_page.dart';
import 'package:shelfaware_app/pages/statistics_page.dart';
import 'package:shelfaware_app/pages/add_food_item.dart'; // Import the add_food_item page
import 'package:shelfaware_app/models/food_category.dart';
import 'package:shelfaware_app/models/food_category_icons.dart';
import 'package:shelfaware_app/components/expiry_icon.dart'; // Import the expiry icon component
import 'package:shelfaware_app/controllers/auth_controller.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shelfaware_app/components/mark_food_dialogue.dart';
// Import the Mark Food Dialog page
// Import the Mark Food Dialog page
// Import the Flutter Slidable package

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

Future<Position> getUserLocation() async {
  LocationPermission permission;
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    throw Exception('Location permissions are permanently denied');
  }

  return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high);
}

class _HomePageState extends State<HomePage> {
  int expiringItemCount = 0;
  int expiredItemCount = 0;
  String firstName = '';
  String lastName = '';
  final user = FirebaseAuth.instance.currentUser!;
  late PageController _pageController;
  String selectedFilter = 'All';
  List<String> filterOptions = ['All'];

  @override
  void initState() {
    super.initState();
    getUserData();
    _pageController = PageController();
    _fetchFilterOptions();
    _checkExpiryNotifications();
  }

  bool _isToggled = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> getUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid) // Fetch document by UID
          .get();

      setState(() {
        firstName = userDoc['firstName'];
        lastName = userDoc['lastName'];
      });
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _checkExpiryNotifications() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('foodItems')
          .where('userId', isEqualTo: user.uid)
          .get();

      int expiringSoonCount = 0;
      int expiredCount = 0;
      DateTime today = DateTime.now();

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        Timestamp expiryTimestamp = data['expiryDate'];
        DateTime expiryDate = expiryTimestamp.toDate();

        if (expiryDate.isBefore(today) &&
            expiryDate.difference(today).inDays <= 0) {
          expiredCount++; // Increment for expired items
        } else if (expiryDate.isAfter(today) &&
            expiryDate.difference(today).inDays <= 3) {
          expiringSoonCount++; // Increment for items expiring soon
        }
      }

      setState(() {
        expiringItemCount = expiringSoonCount;
        expiredItemCount = expiredCount;
      });
    } catch (e) {
      print('Error checking expiry notifications: $e');
    }
  }

  void _handleNotificationPress() {
    // Navigate to the notifications page
  }

  Future<void> _fetchFilterOptions() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('categories').get();
      List<String> categories = snapshot.docs.map((doc) {
        final foodType = doc['Food Type'];
        return foodType?.toString() ?? '';
      }).toList();

      categories.removeWhere((category) => category.isEmpty);
      setState(() {
        filterOptions = ['All', ...categories];
      });
    } catch (e) {
      print('Error fetching filter options: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Add this variable for the toggle state
    return Consumer<AuthController>(
      builder: (context, authController, child) {
        return Scaffold(
          appBar: TopAppBar(
            onLocationPressed: () {},
            onNotificationPressed: _handleNotificationPress,
            expiringItemCount: expiringItemCount +
                expiredItemCount, // Total count of expiring items
          ),
          drawer: CustomDrawer(
            firstName: firstName,
            lastName: lastName,
            onSignOut: () async {
              await authController.signOut();
            },
            onNavigateToFavorites: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FavoritesPage()),
              );
            }, onNavigateToDonationWatchList: () {  },
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
                    // Row containing the filter dropdown (left) and toggle button (right)
                    Row(
                      mainAxisAlignment: MainAxisAlignment
                          .spaceBetween, // Align items on both sides
                      children: [
                        // Filter Dropdown on the left
                        FilterDropdown(
                          selectedFilter: selectedFilter,
                          filterOptions: filterOptions,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedFilter = newValue!;
                            });
                          },
                        ),
                        // Row for the toggle button and its label on the right
                        Row(
                          children: [
                            Text(
                              _isToggled
                                  ? "Calendar view"
                                  : "List view", // Dynamic text based on the toggle state
                              style: TextStyle(fontSize: 16),
                            ),
                            Switch(
                              value: _isToggled,
                              onChanged: (bool value) {
                                setState(() {
                                  _isToggled = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Conditionally show either the list view or the calendar view
                    _isToggled
                        ? SizedBox(
                            height: 400, // Adjust height of the calendar view
                            child: CalendarView(user, userId: user.uid),
                          )
                        : Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('foodItems')
                                  .where('userId', isEqualTo: user.uid)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                                if (snapshot.hasError) {
                                  return const Center(
                                      child: Text('Error fetching food items'));
                                }
                                if (!snapshot.hasData ||
                                    snapshot.data!.docs.isEmpty) {
                                  return const Center(
                                      child: Text('No food items found'));
                                }

                                final filteredItems = selectedFilter == 'All'
                                    ? snapshot.data!.docs
                                    : snapshot.data!.docs.where((doc) {
                                        return doc['category'] ==
                                            selectedFilter;
                                      }).toList();

                                if (filteredItems.isEmpty) {
                                  return const Center(
                                      child: Text(
                                          'No food items match the selected filter.'));
                                }

                                return ListView(
                                  children: filteredItems.map((document) {
                                    final data =
                                        document.data() as Map<String, dynamic>;
                                    final expiryTimestamp =
                                        data['expiryDate'] as Timestamp;

                                    String? fetchedFoodType = data['category'];
                                    FoodCategory foodCategory;

                                    if (fetchedFoodType != null) {
                                      foodCategory =
                                          FoodCategory.values.firstWhere(
                                        (e) =>
                                            e.toString().split('.').last ==
                                            fetchedFoodType,
                                        orElse: () => FoodCategory.values.first,
                                      );
                                    } else {
                                      foodCategory = FoodCategory.values.first;
                                    }

                                    String documentId = document.id;

                                    return InkWell(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          barrierDismissible:
                                              true, // Allows the background to be tapped to close the dialog
                                          builder: (BuildContext context) {
                                            return MarkFoodDialog(
                                              documentId: documentId,
                                            );
                                          },
                                        );
                                      },
                                      child: Card(
                                        elevation: 3,
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: ListTile(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(50),
                                          ),
                                          leading: SizedBox(
                                            width: 40,
                                            height: 40,
                                            child: Icon(
                                                FoodCategoryIcons.getIcon(
                                                    foodCategory)),
                                          ),
                                          title: Text(
                                            data['productName'] ?? 'No Name',
                                            style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          subtitle: Text(
                                            "Quantity: ${data['quantity']}\n${_formatExpiryDate(expiryTimestamp)}",
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width: 60,
                                                height: 60,
                                                child: ExpiryIcon(
                                                    expiryTimestamp:
                                                        expiryTimestamp),
                                              ),
                                              PopupMenuButton<String>(
                                                icon: Icon(Icons.more_vert),
                                                onSelected: (String value) {
                                                  if (value == 'edit') {
                                                    _editFoodItem(documentId);
                                                  } else if (value ==
                                                      'delete') {
                                                    _deleteFoodItem(context, documentId);
                                                  } else if (value ==
                                                      'donate') {
                                                    _confirmDonation(
                                                        documentId);
                                                  }
                                                },
                                                itemBuilder:
                                                    (BuildContext context) => [
                                                  PopupMenuItem<String>(
                                                    value: 'edit',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.edit),
                                                        SizedBox(width: 8),
                                                        Text('Edit'),
                                                      ],
                                                    ),
                                                  ),
                                                  PopupMenuItem<String>(
                                                    value: 'delete',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.delete),
                                                        SizedBox(width: 8),
                                                        Text('Delete'),
                                                      ],
                                                    ),
                                                  ),
                                                  PopupMenuItem<String>(
                                                    value: 'donate',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons
                                                            .volunteer_activism),
                                                        SizedBox(width: 8),
                                                        Text('Donate'),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
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
                MaterialPageRoute(builder: (context) => AddFoodItem(foodItems: [],)),
              );
            },
            child: const Icon(Icons.add),
            backgroundColor: Colors.green,
            elevation: 6.0,
            shape: const CircleBorder(),
          ),
        );
      },
    );
  }

  String formatDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}";
  }

  Future<void> _donateFoodItem(String id) async {
  try {
    // Fetch the food item document
    DocumentSnapshot foodItemDoc = await FirebaseFirestore.instance
        .collection('foodItems')
        .doc(id)
        .get();

    if (!foodItemDoc.exists) {
      throw Exception("Food item not found.");
    }

    // Get food item data
    Map<String, dynamic> foodItemData = foodItemDoc.data() as Map<String, dynamic>;

    // Check if the item is expired
    Timestamp expiryTimestamp = foodItemData['expiryDate'];
    DateTime expiryDate = expiryTimestamp.toDate();
    if (expiryDate.isBefore(DateTime.now())) {
      _showExpiredItemDialog();
      return;
    }

    // Get the user's current location
    final location = await getUserLocation();

    // Ask if the user wants to add a photo
    bool takePhoto = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add a photo?"),
          content: Text(
              "Would you like to take a photo of the food item? Items with photos tend to attract more interest."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text("No, skip"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text("Yes, add photo"),
            ),
          ],
        );
      },
    );

    String? imageUrl;
    if (takePhoto) {
      // Allow the user to take a photo
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image != null) {
        // Upload the image to Firebase Storage
        final String userId = FirebaseAuth.instance.currentUser!.uid;
        final String imageName = "donation_${DateTime.now().millisecondsSinceEpoch}.jpg";
        final Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('donation_images/$userId/$imageName');
        final TaskSnapshot snapshot = await storageRef.putFile(File(image.path)).whenComplete(() {});
        imageUrl = await snapshot.ref.getDownloadURL();
      } else {
        // Notify user if no photo was taken
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No photo captured. Proceeding without photo.")),
        );
      }
    }

    // Prepare donation data
    final String donorId = FirebaseAuth.instance.currentUser!.uid;
    final String donorEmail = FirebaseAuth.instance.currentUser!.email!;
    final DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(donorId)
        .get();
    final String donorName = userDoc['firstName'];

    final String donationId = FirebaseFirestore.instance.collection('donations').doc().id;

    foodItemData['donorId'] = donorId;
    foodItemData['donorName'] = donorName;
    foodItemData['donorEmail'] = donorEmail;
    foodItemData['donated'] = true;
    foodItemData['donatedAt'] = Timestamp.now();
    foodItemData['location'] = GeoPoint(location.latitude, location.longitude);
    foodItemData['status'] = 'available';
    foodItemData['donationId'] = donationId;

    if (imageUrl != null) {
      foodItemData['imageUrl'] = imageUrl;
    }

    // Add the item to the donations collection
    await FirebaseFirestore.instance.collection('donations').doc(donationId).set(foodItemData);

    // Remove the item from the foodItems collection
    await FirebaseFirestore.instance.collection('foodItems').doc(id).delete();

    // Update the user's document with the new donation
    await FirebaseFirestore.instance.collection('users').doc(donorId).update({
      'myDonations': FieldValue.arrayUnion([donationId]),
    });

    // Notify the user of success
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Item donated successfully.")),
    );
  } catch (e) {
    print('Error donating food item: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to donate item: $e")),
    );
  }
}

// Function to show a popup dialog when the item is expired
void _showExpiredItemDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Donation Alert!"),
        content: Text("This item has expired and cannot be donated."),
        actions: [
          TextButton(
            child: Text("OK"),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
          ),
        ],
      );
    },
  );
}

Future<void> _confirmDonation(String id) async {
  bool? confirm = await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Confirm Donation"),
        content: Text("Are you sure you want to donate this item?"),
        actions: [
          TextButton(
            child: Text("Cancel"),
            onPressed: () {
              Navigator.of(context).pop(false); // Return false
            },
          ),
          TextButton(
            child: Text("Donate"),
            onPressed: () {
              Navigator.of(context).pop(true); // Return true
            },
          ),
        ],
      );
    },
  );

  if (confirm == true) {
    await _donateFoodItem(id); // Proceed with donation if confirmed
  }
}


  String _formatExpiryDate(Timestamp expiryTimestamp) {
    DateTime expiryDate = expiryTimestamp.toDate();
    DateTime today = DateTime.now();
    int daysDifference = expiryDate.difference(today).inDays;

    // Determine the expiry date message
    if (daysDifference < 0) {
      return 'Expired'; // If expired, show 'Expired'
    } else if (daysDifference == 0) {
      return 'Expires today'; // If it expires today
    } else if (daysDifference <= 5) {
      return 'Expires in: $daysDifference day${daysDifference == 1 ? '' : 's'}'; // Expiring soon
    } else {
      return 'Expires in: $daysDifference day${daysDifference == 1 ? '' : 's'}'; // Fresh items
    }
  }
  
  void _editFoodItem(String documentId) {}
}



Future<void> _deleteFoodItem(BuildContext context, String documentId) async {
  bool? confirm = await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Confirm Deletion"),
        content: Text("Are you sure you want to delete this item? This action cannot be undone."),
        actions: [
          TextButton(
            child: Text("Cancel"),
            onPressed: () {
              Navigator.of(context).pop(false); // Return false if user cancels
            },
          ),
          TextButton(
            child: Text("Delete"),
            onPressed: () {
              Navigator.of(context).pop(true); // Return true if user confirms
            },
          ),
        ],
      );
    },
  );

  if (confirm == true) {
    try {
      // Delete the food item document from Firestore
      await FirebaseFirestore.instance
          .collection('foodItems')
          .doc(documentId)
          .delete();

      // Notify the user of success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Item deleted successfully.")),
      );
    } catch (e) {
      print('Error deleting food item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete item: $e")),
      );
    }
  }
}
