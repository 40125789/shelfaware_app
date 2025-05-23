import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shelfaware_app/components/bottom_navigation_bar.dart';
import 'package:shelfaware_app/components/calendar_view_widget.dart';
import 'package:shelfaware_app/components/food_list_view.dart';
import 'package:shelfaware_app/components/side_drawer_menu.dart';
import 'package:shelfaware_app/components/top_app_bar.dart';
import 'package:shelfaware_app/components/category_filter_dropdown.dart'; // Import the new component
import 'package:shelfaware_app/controllers/bottom_nav_controller.dart';
import 'package:shelfaware_app/screens/location_page.dart';
import 'package:shelfaware_app/screens/notification_page.dart';
import 'package:shelfaware_app/screens/recipes_page.dart';
import 'package:shelfaware_app/screens/favourites_page.dart';
import 'package:shelfaware_app/screens/donations_page.dart';
import 'package:shelfaware_app/screens/statistics_page.dart';
import 'package:shelfaware_app/controllers/auth_controller.dart'; // Ensure this import is correct
import 'package:shelfaware_app/repositories/user_repository.dart';
import 'package:wiredash/wiredash.dart';
import 'package:shelfaware_app/services/user_service.dart';
import 'package:shelfaware_app/services/food_service.dart';
import 'package:shelfaware_app/services/donation_service.dart';


class HomePage extends ConsumerStatefulWidget {
  HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with TickerProviderStateMixin {
  String firstName = '';
  String lastName = '';
  final user = FirebaseAuth.instance.currentUser!;
  late PageController _pageController;
  String selectedFilter = 'All';
  List<String> filterOptions = ['All'];
  late AnimationController _controller;
  int _currentPage = 0;
  int selectedIndex = 0;
  final List<String> pageTitles = [
    'Home',
    'Recipes',
    'Donations',
    'Statistics'
  ];
  final DonationService donationService = DonationService();
  final FoodService foodService = FoodService();

  @override
  void initState() {
    super.initState();
    getUserData();
    _pageController =
        PageController(initialPage: ref.read(bottomNavControllerProvider));
    _fetchFilterOptions();
    _controller = AnimationController(vsync: this);
    DonationService donationService = DonationService();
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
      final userRepository = UserRepository(firestore: FirebaseFirestore.instance, auth: FirebaseAuth.instance);
      final userService = UserService(userRepository);
      final userData = await userService.getUserData(user.uid);
      if (mounted) {
        setState(() {
          firstName = userData['firstName'];
          lastName = userData['lastName'];
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  void onNotificationPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationPage(),
      ),
    );
  }

  Future<void> _fetchFilterOptions() async {
    try {
      final categories = await foodService.fetchFilterOptions();
      if (mounted) {
        setState(() {
          filterOptions = ['All', ...categories];
        });
      }
    } catch (e) {
      print('Error fetching filter options: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(bottomNavControllerProvider);
    // Track position of draggable FAB
    final ValueNotifier<Offset> fabPosition = ValueNotifier(Offset(300, 500)); // Initial position

    return Scaffold(
      appBar: TopAppBar(
        title: pageTitles[selectedIndex],
        onLocationPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LocationScreen()),
          );
        },
        onNotificationPressed: onNotificationPressed,
        userId: user.uid,
        onPageChanged: (int index) {},
      ),
      drawer: CustomDrawer(
        firstName: firstName,
        lastName: lastName,
        onSignOut: () async {
          await context.read<AuthNotifier>().signOut();
        },
        onNavigateToFavorites: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FavouritesPage()),
          );
        },
        onNavigateToDonationWatchList: () {},
      ),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              ref
                  .read(bottomNavControllerProvider.notifier)
                  .navigateTo(index);
            },
            physics: const NeverScrollableScrollPhysics(),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const SizedBox(width: 8),
                            FilterDropdown(
                              selectedFilter: selectedFilter,
                              filterOptions: filterOptions,
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedFilter = newValue!;
                                });
                              },
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              _isToggled ? "Calendar view" : "List view",
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
                    _isToggled
                        ? SizedBox(
                            height: 400,
                            child: CalendarView(user, userId: user.uid),
                          )
                        : Expanded(
                            child: FoodListView(
                              user: user,
                              selectedFilter: selectedFilter,
                              donationService: donationService,
                            ),
                          )
                  ],
                ),
              ),
              RecipesPage(),
              DonationsPage(),
              StatisticsPage(),
            ],
          ),
            ValueListenableBuilder<Offset>(
            valueListenable: fabPosition,
            builder: (context, position, child) {
              // Get screen size
              final screenSize = MediaQuery.of(context).size;
              // Get safe area
              final padding = MediaQuery.of(context).padding;
              // Calculate available space (accounting for FAB size ~56)
              final maxX = screenSize.width - 56;
              final maxY = screenSize.height - 56 - padding.bottom - 80; // 80 for bottom nav
              final minY = padding.top + 56; // Account for app bar

              // Constrain position within bounds
              final constrainedX = position.dx.clamp(0, maxX);
              final constrainedY = position.dy.clamp(minY, maxY);

              return Positioned(
              left: constrainedX.toDouble(),
              top: constrainedY.toDouble(),
              child: Draggable(
                feedback: FloatingActionButton(
                onPressed: null,
                child: const Icon(Icons.feedback_rounded),
                ),
                childWhenDragging: Container(),
                onDragEnd: (details) {
                // Constrain final position
                fabPosition.value = Offset(
                  details.offset.dx.clamp(0, maxX),
                  details.offset.dy.clamp(minY, maxY),
                );
                },
                child: FloatingActionButton(
                onPressed: () {
                  Wiredash.of(context).show(inheritMaterialTheme: true);
                },
                child: const Icon(Icons.feedback_rounded),
                elevation: 6.0,
                shape: const CircleBorder(),
                ),
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar:
          BottomNavigationBarComponent(pageController: _pageController),
    );
  }

  // Use the new utility functions for date formatting
  String formatDate(Timestamp timestamp) {
    return formatDate(timestamp);
  }

  String formatExpiryDate(Timestamp expiryTimestamp) {
    return formatExpiryDate(expiryTimestamp);
  }

 

  
}