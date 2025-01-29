import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:shelfaware_app/pages/add_food_item.dart';

import 'package:flutter/material.dart';

class BottomNavigationBarComponent extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onTabChange;

  const BottomNavigationBarComponent({
    Key? key,
    required this.selectedIndex,
    required this.onTabChange,
  }) : super(key: key);

  @override
  _BottomNavigationBarComponentState createState() =>
      _BottomNavigationBarComponentState();
}

class _BottomNavigationBarComponentState
    extends State<BottomNavigationBarComponent> {
  bool _isPressed = false;

  void _onFabTap() {
    setState(() {
      _isPressed = true;
    });

    // Reset the press effect after a short duration (to simulate pressing)
    Future.delayed(Duration(milliseconds: 150), () {
      setState(() {
        _isPressed = false;
      });
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFoodItem(
          foodItems: [], // Navigate to the add item page
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none, // Allows the button to overlap the navbar
      children: [
        // Bottom Navigation Bar with Donations at index 2
        BottomNavigationBar(
          currentIndex: widget.selectedIndex, // Highlight the selected tab
          onTap: (index) {
            // Handle navigation to the correct page
            widget.onTabChange(index);
          },
          selectedItemColor: Colors.green, // Selected tab color
          unselectedItemColor: Colors.grey, // Unselected tab color
          showUnselectedLabels: true, // Show labels for unselected tabs
          iconSize: 25, // Adjust icon size to fit better
          type: BottomNavigationBarType.fixed, // Keep items fixed in place
          selectedFontSize: 12, // Adjust font size for labels if needed
          unselectedFontSize: 12, // Same for unselected labels
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home', // Non-null label
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book),
              label: 'Recipes', // Non-null label
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.food_bank),
              label: 'Donations', // Non-null label
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Statistics', // Non-null label
            ),
          ],
        ),
        // The smaller plus button, centered above the navbar and not covering other icons
        Positioned(
          left: MediaQuery.of(context).size.width * 0.5 - 25, // Center horizontally
          bottom: 30, // Move the button above the bottom nav bar (adjust to avoid overlap)
          child: GestureDetector(
            onTap: _onFabTap,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 150), // Duration for the color fade
              curve: Curves.easeInOut, // Smooth animation curve
              decoration: BoxDecoration(
                color: _isPressed ? Colors.green[800] : Colors.green, // Change color on press
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 22, // Smaller button radius
                backgroundColor: Colors.transparent, // Transparent background for CircleAvatar
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 24, // Smaller icon size
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

