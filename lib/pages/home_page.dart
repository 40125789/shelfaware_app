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
import 'package:shelfaware_app/pages/location_page.dart';
import 'package:shelfaware_app/pages/notification_page.dart';
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
import 'package:lottie/lottie.dart';
import 'package:wiredash/wiredash.dart';


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

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  String firstName = '';
  String lastName = '';
  final user = FirebaseAuth.instance.currentUser!;
  late PageController _pageController;
  String selectedFilter = 'All';
  List<String> filterOptions = ['All'];
  late AnimationController _controller;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    getUserData();
    _pageController = PageController();
    _fetchFilterOptions();
    _controller = AnimationController(vsync: this);
  }

  bool _isToggled = false;

  @override
  void dispose() {
    _controller.dispose();
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

  


  void onNotificationPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationPage(userId: user.uid),
      ),
    );
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
            onLocationPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LocationPage()),
              );
            },
            onNotificationPressed: onNotificationPressed,
            userId: user.uid,
            title: getAppbarTitle(_currentPage),
          ), // Dynamic title based on the toggle state
          // Total count of expiring items

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
            },
            onNavigateToDonationWatchList: () {},
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
                                        child:
                                            Text('Error fetching food items'));
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

                                  // Group items by expiry date category
                                  final groupedItems =
                                      <String, List<QueryDocumentSnapshot>>{
                                    'Expired': [],
                                    'Expiring Soon': [],
                                    'Fresh': []
                                  };

                                  final now = DateTime.now();

                                  for (var item in filteredItems) {
                                    final data =
                                        item.data() as Map<String, dynamic>;
                                    final expiryTimestamp =
                                        data['expiryDate'] as Timestamp;
                                    final expiryDate = expiryTimestamp.toDate();
                                    final difference =
                                        expiryDate.difference(now).inDays;

                                    // Classify based on expiry date
                                    if (difference < 0) {
                                      groupedItems['Expired']!
                                          .add(item); // Expired items
                                    } else if (difference <= 4) {
                                      groupedItems['Expiring Soon']!
                                          .add(item); // Expiring within 7 days
                                    } else {
                                      groupedItems['Fresh']!
                                          .add(item); // Fresh items
                                    }
                                  }

                                  return ListView(
                                    children: groupedItems.keys.map((category) {
                                      // Get the count of items in each category
                                      int itemCount =
                                          groupedItems[category]!.length;

                                      // Color each category differently
                                      Color categoryColor;
                                      switch (category) {
                                        case 'Expired':
                                          categoryColor = Colors
                                              .red; // Red for expired items
                                          break;
                                        case 'Expiring Soon':
                                          categoryColor = Colors
                                              .orange; // Orange for items expiring soon
                                          break;
                                        case 'Fresh':
                                          categoryColor = Colors
                                              .green; // Green for fresh items
                                          break;
                                        default:
                                          categoryColor = Colors
                                              .blueAccent; // Default color
                                      }

                                      // For each category, create an expandable tile with a colored header only
                                      return ExpansionTile(
                                        tilePadding: EdgeInsets
                                            .zero, // Remove padding to make the header stick to the edge
                                        title: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8.0, horizontal: 16.0),
                                          decoration: BoxDecoration(
                                            color: categoryColor,
                                            borderRadius: BorderRadius.circular(
                                                12), // Rounded corners
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                category, // The category name
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors
                                                      .white, // White text on colored background
                                                ),
                                              ),
                                              Text(
                                                '($itemCount)', // Display the item count in each category
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors
                                                      .white, // White text on colored background
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        children: groupedItems[category]!
                                            .map((document) {
                                          final data = document.data()
                                              as Map<String, dynamic>;
                                          final expiryTimestamp =
                                              data['expiryDate'] as Timestamp;

                                          String? fetchedFoodType =
                                              data['category'];
                                          FoodCategory foodCategory;

                                          if (fetchedFoodType != null) {
                                            foodCategory =
                                                FoodCategory.values.firstWhere(
                                              (e) =>
                                                  e
                                                      .toString()
                                                      .split('.')
                                                      .last ==
                                                  fetchedFoodType,
                                              orElse: () =>
                                                  FoodCategory.values.first,
                                            );
                                          } else {
                                            foodCategory =
                                                FoodCategory.values.first;
                                          }

                                          String documentId = document.id;

                                          return InkWell(
                                            onTap: () {
                                              showModalBottomSheet(
                                                context: context,
                                                isScrollControlled: true,
                                                builder:
                                                    (BuildContext context) {
                                                  return Container(
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            0.7,
                                                    child: MarkFoodDialog(
                                                      documentId: documentId,
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                            child: Card(
                                              elevation: 3,
                                              margin:
                                                  const EdgeInsets.symmetric(
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
                                                  data['productName'] ??
                                                      'No Name',
                                                  style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                subtitle: Text(
                                                  "Quantity: ${data['quantity']}\n${_formatExpiryDate(expiryTimestamp)}",
                                                ),
                                                trailing: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    SizedBox(
                                                      width: 60,
                                                      height: 60,
                                                      child: ExpiryIcon(
                                                          expiryTimestamp:
                                                              expiryTimestamp),
                                                    ),
                                                    PopupMenuButton<String>(
                                                      icon:
                                                          Icon(Icons.more_vert),
                                                      onSelected:
                                                          (String value) {
                                                        if (value == 'edit') {
                                                          _editFoodItem(
                                                              documentId);
                                                        } else if (value ==
                                                            'delete') {
                                                          _deleteFoodItem(
                                                              context,
                                                              documentId);
                                                        } else if (value ==
                                                            'donate') {
                                                          _confirmDonation(
                                                              documentId);
                                                        }
                                                      },
                                                      itemBuilder: (BuildContext
                                                              context) =>
                                                          [
                                                        PopupMenuItem<String>(
                                                          value: 'edit',
                                                          child: Row(
                                                            children: [
                                                              Icon(Icons.edit),
                                                              SizedBox(
                                                                  width: 8),
                                                              Text('Edit'),
                                                            ],
                                                          ),
                                                        ),
                                                        PopupMenuItem<String>(
                                                          value: 'delete',
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                  Icons.delete),
                                                              SizedBox(
                                                                  width: 8),
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
                                                              SizedBox(
                                                                  width: 8),
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
                                    }).toList(),
                                  );
                                },
                              ),
                            )
                    ],
                  ),
                ),
                RecipesPage(),
                DonationsPage(),
                StatisticsPage(),
              ],
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              }),
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
              // Add your onPressed functionality here
            Wiredash.of(context).show(inheritMaterialTheme: true);
            },
            child: const Icon(Icons.feedback_rounded),
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
      Map<String, dynamic> foodItemData =
          foodItemDoc.data() as Map<String, dynamic>;

      // Check if the item is expired
      Timestamp expiryTimestamp = foodItemData['expiryDate'];
      DateTime expiryDate = expiryTimestamp.toDate();
      if (expiryDate.isBefore(DateTime.now())) {
        _showExpiredItemDialog();
        return;
      }

      // Get the user's location from Firestore or GeoLocator
      final location = await _getUserLocation();

      // Ask if the user wants to add a photo
      bool takePhoto = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              "Would you like to add a photo?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center, // Ensures title is centered
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image with adjusted size and border for better presentation
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey, width: 1),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/camera.png', // Your image path here
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Improved text with better alignment and styling
                Text(
                  "Adding a photo of your food item can help attract more attention and assist others in assessing its quality. Photos make listings stand out and feel more trustworthy.",
                  textAlign: TextAlign.center, // Centers the content text
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
            actions: [
              // Simplified actions with consistent styling
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  "No, skip",
                  style: TextStyle(color: Colors.blueAccent),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Yes, add photo",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );

      String? imageUrl;
      if (takePhoto) {
        // Show the Lottie loading animation dialog after the photo is taken
        showDialog(
          context: context,
          barrierDismissible: false, // Prevent closing the dialog
          builder: (BuildContext context) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RepaintBoundary(
                    child: Lottie.network(
                      'https://lottie.host/726edc0a-86f8-4d94-95fc-3df9de90d8fe/c2E6eYh86Z.json',
                      frameRate: FrameRate.max,
                      repeat: true,
                      animate: true,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Donating your food...",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          },
        );

        // Let user pick an image
        final picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 800,
          maxHeight: 800,
        );

        if (image != null) {
          final String userId = FirebaseAuth.instance.currentUser!.uid;
          final String imageName =
              "donation_${DateTime.now().millisecondsSinceEpoch}.jpg";
          final Reference storageRef = FirebaseStorage.instance
              .ref()
              .child('donation_images/$userId/$imageName');
          final TaskSnapshot snapshot =
              await storageRef.putFile(File(image.path)).whenComplete(() {});

          // Get image URL after upload
          imageUrl = await snapshot.ref.getDownloadURL();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("No photo captured. Proceeding without photo.")),
          );
        }

        Navigator.pop(context); // Dismiss loading dialog after image upload
      }

      // Prepare donation data
      final String donorId = FirebaseAuth.instance.currentUser!.uid;
      final String donorEmail = FirebaseAuth.instance.currentUser!.email!;

      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(donorId)
          .get();
      final String donorName = userDoc['firstName'];

      final String donationId =
          FirebaseFirestore.instance.collection('donations').doc().id;

      foodItemData['donorId'] = donorId;
      foodItemData['donorName'] = donorName;
      foodItemData['donorEmail'] = donorEmail;
      foodItemData['donated'] = true;
      foodItemData['donatedAt'] = Timestamp.now();
      foodItemData['status'] = 'available';
      foodItemData['donationId'] = donationId;

      // If location exists in the user's document, use that, otherwise use GeoLocator location
      if (userDoc['location'] != null) {
        GeoPoint userLocation = userDoc['location'];
        foodItemData['location'] =
            GeoPoint(userLocation.latitude, userLocation.longitude);
      } else {
        foodItemData['location'] =
            GeoPoint(location.latitude, location.longitude);
      }

      if (imageUrl != null) {
        foodItemData['imageUrl'] = imageUrl;
      }

      // Add the item to the donations collection
      await FirebaseFirestore.instance
          .collection('donations')
          .doc(donationId)
          .set(foodItemData);

      // Remove the item from the foodItems collection
      await FirebaseFirestore.instance.collection('foodItems').doc(id).delete();

      // Update the user's document with the new donation
      await FirebaseFirestore.instance.collection('users').doc(donorId).update({
        'myDonations': FieldValue.arrayUnion([donationId]),
      });

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

  Future<Position> _getUserLocation() async {
    return await getUserLocation();
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
    } else if (daysDifference <= 4) {
      return 'Expires in: $daysDifference day${daysDifference == 1 ? '' : 's'}'; // Expiring soon
    } else {
      return 'Expires in: $daysDifference day${daysDifference == 1 ? '' : 's'}'; // Fresh items
    }
  }

  void _editFoodItem(String documentId) {}

  getAppbarTitle(int currentPage) {
    switch (currentPage) {
      case 0:
        return 'Home';
      case 1:
        return 'Recipes';
      case 2:
        return 'Donations';
      case 3:
        return 'Statistics';
      default:
        return 'Home';
    }
  }

  Future<void> _deleteFoodItem(BuildContext context, String documentId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Deletion"),
          content: Text(
              "Are you sure you want to delete this item? This action cannot be undone."),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context)
                    .pop(false); // Return false if user cancels
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
}
