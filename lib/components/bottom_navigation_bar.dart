import 'package:flutter/material.dart';
import 'package:shelfaware_app/controllers/bottom_nav_controller.dart';
import 'package:shelfaware_app/pages/add_food_item.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class BottomNavigationBarComponent extends ConsumerStatefulWidget {
  final PageController pageController;

  const BottomNavigationBarComponent({Key? key, required this.pageController}) : super(key: key);

  @override
  _BottomNavigationBarComponentState createState() => _BottomNavigationBarComponentState();
}

class _BottomNavigationBarComponentState extends ConsumerState<BottomNavigationBarComponent> {
  bool _isPressed = false;

  void _onFabTap() {
    setState(() {
      _isPressed = true;
    });

    Future.delayed(const Duration(milliseconds: 150), () {
      setState(() {
        _isPressed = false;
      });
    });

    // Push the AddFoodItem screen when FAB is tapped
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFoodItem(
         
        ),

      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(bottomNavControllerProvider);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) {
            ref.read(bottomNavControllerProvider.notifier).navigateTo(index); // Update Riverpod state
           widget.pageController.animateToPage(
  index,
  duration: const Duration(milliseconds: 300),
  curve: Curves.easeInOut,
);
          },
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          iconSize: 25,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Recipes'),
            BottomNavigationBarItem(icon: Icon(Icons.food_bank), label: 'Donations'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Statistics'),
          ],
        ),
        Positioned(
          left: MediaQuery.of(context).size.width * 0.5 - 25,
          bottom: 30,
          child: GestureDetector(
            onTap: _onFabTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: _isPressed ? Colors.green[800] : Colors.green,
                shape: BoxShape.circle,
              ),
              child: const CircleAvatar(
                radius: 22,
                backgroundColor: Colors.transparent,
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}