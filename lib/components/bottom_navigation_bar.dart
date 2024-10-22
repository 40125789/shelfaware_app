import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';


class BottomNavigationBarComponent extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabChange;

  const BottomNavigationBarComponent({
    Key? key,
    required this.selectedIndex,
    required this.onTabChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GNav(
      activeColor: Colors.green,
      iconSize: 24,
      gap: 8,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      onTabChange: onTabChange,
      tabs: [
        GButton(
          icon: Icons.home,
          text: 'Home',
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
    );
  }
}